import 'package:cloud_firestore/cloud_firestore.dart';
import '../Commons/Models/PlatformAnalyticsModel.dart';
import '../Commons/Models/TenantModel.dart';
import '../Commons/Utils/AppLogger.dart';

/// Serviço de analytics globais da plataforma com lazy-cache.
///
/// Estratégia:
/// - Lê o documento `platform_analytics/global_summary` do Firestore.
/// - Se o cache for válido (< 1 hora), retorna direto (1 read).
/// - Se stale ou inexistente, recalcula agregando dados de todos os tenants
///   ativos e persiste o resultado como novo cache.
///
/// Isso minimiza reads do Firestore — em média 1 read por acesso ao dashboard,
/// com recálculo completo no máximo 1x por hora.
class PlatformAnalyticsService {
  static final PlatformAnalyticsService instance = PlatformAnalyticsService._();
  PlatformAnalyticsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionPath = 'platform_analytics';
  static const String _docId = 'global_summary';

  DocumentReference<Map<String, dynamic>> get _summaryDoc =>
      _firestore.collection(_collectionPath).doc(_docId);

  /// Obtém analytics da plataforma (com cache inteligente).
  ///
  /// Se [forceRefresh] for true, recalcula mesmo com cache válido.
  Future<PlatformAnalyticsModel> getAnalytics({
    bool forceRefresh = false,
  }) async {
    try {
      // 1. Tentar ler do cache
      if (!forceRefresh) {
        final doc = await _summaryDoc.get();
        if (doc.exists) {
          final cached = PlatformAnalyticsModel.fromMap(doc.data()!);
          if (!cached.isStale) {
            AppLogger.debug(
              'Analytics: cache hit (${DateTime.now().difference(cached.lastUpdated).inMinutes}min)',
            );
            return cached;
          }
          AppLogger.info('Analytics: cache stale, recalculando...');
        } else {
          AppLogger.info(
            'Analytics: sem cache, calculando pela primeira vez...',
          );
        }
      }

      // 2. Recalcular
      return await _recalculate();
    } catch (e) {
      AppLogger.error('Erro ao obter analytics', error: e);
      // Retornar modelo vazio em caso de erro
      return PlatformAnalyticsModel(lastUpdated: DateTime.now());
    }
  }

  /// Recalcula todos os analytics agregando dados de todos os tenants ativos.
  Future<PlatformAnalyticsModel> _recalculate() async {
    AppLogger.info('Analytics: iniciando recálculo global...');

    // Buscar todos os tenants ativos
    final tenantsSnapshot = await _firestore
        .collection('tenants')
        .where('is_active', isEqualTo: true)
        .get();

    final tenants = tenantsSnapshot.docs
        .map((doc) => TenantModel.fromDocumentSnapshot(doc))
        .toList();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final tenantResults = await Future.wait(
      tenants.map((tenant) async {
        final salesCol = _firestore
            .collection('tenants')
            .doc(tenant.uid)
            .collection('sales');

        final customersCol = _firestore
            .collection('tenants')
            .doc(tenant.uid)
            .collection('customers');

        try {
          final results = await Future.wait([
            salesCol
                .where(
                  'created_at',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
                )
                .where('status', isNotEqualTo: 'cancelled')
                .get(),
            customersCol.count().get(),
            customersCol
                .where(
                  'created_at',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
                )
                .count()
                .get(),
          ]);

          final monthSnapshot =
              results[0] as QuerySnapshot<Map<String, dynamic>>;
          final customersCount = results[1] as AggregateQuerySnapshot;
          final newCustomersCount = results[2] as AggregateQuerySnapshot;

          double tenantSalesToday = 0;
          double tenantSalesMonth = 0;
          int tenantSalesCountToday = 0;

          for (final doc in monthSnapshot.docs) {
            final data = doc.data();
            final total =
                ((data['total'] ?? data['total_value']) as num?)?.toDouble() ??
                0;
            tenantSalesMonth += total;

            final createdAt = (data['created_at'] as Timestamp?)?.toDate();
            if (createdAt != null && !createdAt.isBefore(startOfDay)) {
              tenantSalesToday += total;
              tenantSalesCountToday++;
            }
          }

          return (
            tenant: tenant,
            salesToday: tenantSalesToday,
            salesMonth: tenantSalesMonth,
            salesCountToday: tenantSalesCountToday,
            salesCountMonth: monthSnapshot.docs.length,
            totalCustomers: customersCount.count ?? 0,
            newCustomersMonth: newCustomersCount.count ?? 0,
          );
        } catch (e) {
          AppLogger.warning(
            'Erro ao agregar dados do tenant ${tenant.name}: $e',
          );
          return null;
        }
      }),
    );

    double totalSalesToday = 0;
    double totalSalesMonth = 0;
    int salesCountToday = 0;
    int salesCountMonth = 0;
    int totalCustomers = 0;
    int newCustomersMonth = 0;
    final topTenantsList = <TopTenantDTO>[];

    for (final result
        in tenantResults
            .whereType<
              ({
                TenantModel tenant,
                double salesToday,
                double salesMonth,
                int salesCountToday,
                int salesCountMonth,
                int totalCustomers,
                int newCustomersMonth,
              })
            >()) {
      totalSalesToday += result.salesToday;
      totalSalesMonth += result.salesMonth;
      salesCountToday += result.salesCountToday;
      salesCountMonth += result.salesCountMonth;
      totalCustomers += result.totalCustomers;
      newCustomersMonth += result.newCustomersMonth;

      if (result.salesMonth > 0) {
        topTenantsList.add(
          TopTenantDTO(
            tenantId: result.tenant.uid,
            tenantName: result.tenant.name,
            salesMonth: result.salesMonth,
            salesCount: result.salesCountMonth,
          ),
        );
      }
    }

    // Ordenar top tenants por vendas do mês (desc)
    topTenantsList.sort((a, b) => b.salesMonth.compareTo(a.salesMonth));
    final topTenants = topTenantsList.take(10).toList();

    // Calcular ticket médio
    final averageTicketMonth = salesCountMonth > 0
        ? totalSalesMonth / salesCountMonth
        : 0.0;

    final analytics = PlatformAnalyticsModel(
      totalSalesToday: totalSalesToday,
      totalSalesMonth: totalSalesMonth,
      salesCountToday: salesCountToday,
      salesCountMonth: salesCountMonth,
      totalCustomers: totalCustomers,
      newCustomersMonth: newCustomersMonth,
      averageTicketMonth: averageTicketMonth,
      topTenants: topTenants,
      lastUpdated: DateTime.now(),
    );

    // Persistir cache no Firestore
    try {
      await _summaryDoc.set(analytics.toMap());
      AppLogger.info('Analytics: cache atualizado com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao salvar cache de analytics', error: e);
    }

    AppLogger.info(
      'Analytics recalculado: '
      'vendas hoje=R\$${totalSalesToday.toStringAsFixed(2)}, '
      'vendas mês=R\$${totalSalesMonth.toStringAsFixed(2)}, '
      'clientes=$totalCustomers, '
      'ticket médio=R\$${averageTicketMonth.toStringAsFixed(2)}',
    );

    return analytics;
  }
}
