import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Enums/EscalationStatus.dart';
import '../../Commons/Enums/StockAlertStatus.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/SessionManager.dart';

/// DTO leve para representar uma venda recente no Dashboard.
class RecentSaleDTO {
  final String uid;
  final String customerName;
  final int itemCount;
  final double totalValue;
  final String source; // 'manual' | 'whatsapp_automation'
  final DateTime createdAt;

  RecentSaleDTO({
    required this.uid,
    required this.customerName,
    required this.itemCount,
    required this.totalValue,
    required this.source,
    required this.createdAt,
  });

  factory RecentSaleDTO.fromMap(String uid, Map<String, dynamic> data) {
    return RecentSaleDTO(
      uid: uid,
      customerName: data['customer_name'] ?? 'Cliente',
      itemCount: DashboardTenantRepository.saleItemCountFromMap(data),
      totalValue: DashboardTenantRepository.saleTotalFromMap(data),
      source: data['source'] ?? 'manual',
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

/// DTO para dados diários de vendas (usado no gráfico).
class DailySalesDTO {
  final DateTime date;
  final double totalValue;

  DailySalesDTO({required this.date, required this.totalValue});
}

/// Repositório de dados para o Dashboard Tenant.
///
/// Consulta Firestore para métricas, gráficos e alertas.
class DashboardTenantRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _tenantId => SessionManager.instance.currentTenant!.uid;

  CollectionReference get _salesCollection =>
      _firestore.collection('tenants').doc(_tenantId).collection('sales');

  CollectionReference get _customersCollection =>
      _firestore.collection('tenants').doc(_tenantId).collection('customers');

  CollectionReference get _productsCollection =>
      _firestore.collection('tenants').doc(_tenantId).collection('products');

  CollectionReference get _escalationsCollection =>
      _firestore.collection('tenants').doc(_tenantId).collection('escalations');

  CollectionReference get _stockAlertsCollection =>
      _firestore.collection('tenants').doc(_tenantId).collection('stockAlerts');

  static double saleTotalFromMap(Map<String, dynamic> data) {
    final rawValue = data['total'] ?? data['total_value'] ?? 0;
    return (rawValue as num).toDouble();
  }

  static int saleItemCountFromMap(Map<String, dynamic> data) {
    final explicitCount = data['item_count'];
    if (explicitCount is num) {
      return explicitCount.toInt();
    }

    final items = data['items'];
    if (items is List) {
      int total = 0;
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          total += ((item['quantity'] ?? 0) as num).toInt();
        } else if (item is Map) {
          total += ((item['quantity'] ?? 0) as num).toInt();
        }
      }
      return total;
    }

    return 0;
  }

  // MARK: - Vendas Hoje

  /// Retorna o total em R$ das vendas do dia atual.
  Future<double> getSalesToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await _salesCollection
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('status', isNotEqualTo: 'cancelled')
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += saleTotalFromMap(data);
      }

      AppLogger.debug('Vendas hoje: R\$ $total');
      return total;
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas hoje', error: e);
      return 0;
    }
  }

  /// Retorna o total em R$ das vendas de ontem.
  Future<double> getSalesYesterday() async {
    try {
      final now = DateTime.now();
      final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
      final endOfYesterday = DateTime(now.year, now.month, now.day);

      final snapshot = await _salesCollection
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYesterday),
          )
          .where('created_at', isLessThan: Timestamp.fromDate(endOfYesterday))
          .where('status', isNotEqualTo: 'cancelled')
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += saleTotalFromMap(data);
      }

      return total;
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas ontem', error: e);
      return 0;
    }
  }

  // MARK: - Vendas do Mês

  /// Retorna o total em R$ e quantidade de vendas do mês atual.
  Future<({double total, int count})> getSalesThisMonth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await _salesCollection
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('status', isNotEqualTo: 'cancelled')
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += saleTotalFromMap(data);
      }

      return (total: total, count: snapshot.docs.length);
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas do mês', error: e);
      return (total: 0.0, count: 0);
    }
  }

  /// Retorna o total em R$ e quantidade do mesmo período do mês anterior.
  Future<({double total, int count})> getSalesLastMonthSamePeriod() async {
    try {
      final now = DateTime.now();
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final sameDayLastMonth = DateTime(now.year, now.month - 1, now.day);

      final snapshot = await _salesCollection
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth),
          )
          .where(
            'created_at',
            isLessThanOrEqualTo: Timestamp.fromDate(sameDayLastMonth),
          )
          .where('status', isNotEqualTo: 'cancelled')
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += saleTotalFromMap(data);
      }

      return (total: total, count: snapshot.docs.length);
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas mês anterior', error: e);
      return (total: 0.0, count: 0);
    }
  }

  // MARK: - Clientes

  /// Retorna o total de clientes cadastrados.
  Future<int> getTotalCustomers() async {
    try {
      final snapshot = await _customersCollection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao buscar total de clientes', error: e);
      return 0;
    }
  }

  /// Retorna a quantidade de novos clientes no mês atual.
  Future<int> getNewCustomersThisMonth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await _customersCollection
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao buscar clientes novos do mês', error: e);
      return 0;
    }
  }

  // MARK: - Gráfico (Últimos 7 dias)

  /// Retorna vendas agrupadas por dia nos últimos 7 dias.
  Future<List<DailySalesDTO>> getSalesLast7Days() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = DateTime(now.year, now.month, now.day - 6);

      final snapshot = await _salesCollection
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          )
          .where('status', isNotEqualTo: 'cancelled')
          .orderBy('created_at')
          .get();

      // Agrupar por dia
      final Map<String, double> dailyTotals = {};
      for (int i = 0; i < 7; i++) {
        final date = DateTime(now.year, now.month, now.day - 6 + i);
        final key = '${date.year}-${date.month}-${date.day}';
        dailyTotals[key] = 0;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['created_at'] as Timestamp).toDate();
        final key = '${createdAt.year}-${createdAt.month}-${createdAt.day}';
        if (dailyTotals.containsKey(key)) {
          dailyTotals[key] = dailyTotals[key]! + saleTotalFromMap(data);
        }
      }

      // Converter para lista ordenada
      final result = <DailySalesDTO>[];
      for (int i = 0; i < 7; i++) {
        final date = DateTime(now.year, now.month, now.day - 6 + i);
        final key = '${date.year}-${date.month}-${date.day}';
        result.add(
          DailySalesDTO(date: date, totalValue: dailyTotals[key] ?? 0),
        );
      }

      return result;
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas últimos 7 dias', error: e);
      // Retornar lista com 7 dias zerados
      final now = DateTime.now();
      return List.generate(7, (i) {
        return DailySalesDTO(
          date: DateTime(now.year, now.month, now.day - 6 + i),
          totalValue: 0,
        );
      });
    }
  }

  // MARK: - Últimas Vendas

  /// Retorna as 5 vendas mais recentes.
  Future<List<RecentSaleDTO>> getRecentSales() async {
    try {
      final snapshot = await _salesCollection
          .orderBy('created_at', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RecentSaleDTO.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas recentes', error: e);
      return [];
    }
  }

  // MARK: - Produtos (Alertas)

  /// Retorna o total de produtos cadastrados.
  Future<int> getTotalProducts() async {
    try {
      final snapshot = await _productsCollection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao buscar total de produtos', error: e);
      return 0;
    }
  }

  /// Retorna a quantidade de produtos sem imagem.
  Future<int> getProductsWithoutImage() async {
    try {
      // Produtos onde image_url é null ou vazio
      final snapshotNull = await _productsCollection
          .where('image_url', isNull: true)
          .count()
          .get();

      final snapshotEmpty = await _productsCollection
          .where('image_url', isEqualTo: '')
          .count()
          .get();

      return (snapshotNull.count ?? 0) + (snapshotEmpty.count ?? 0);
    } catch (e) {
      AppLogger.error('Erro ao buscar produtos sem imagem', error: e);
      return 0;
    }
  }

  // MARK: - Escalações Pendentes

  /// Retorna a quantidade de escalações pendentes (aguardando atendimento).
  Future<int> getPendingEscalationsCount() async {
    try {
      final snapshot = await _escalationsCollection
          .where('status', isEqualTo: EscalationStatus.pending.name)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao buscar escalações pendentes', error: e);
      return 0;
    }
  }

  // MARK: - Alertas de Estoque Pendentes

  /// Retorna a quantidade de alertas de estoque pendentes.
  Future<int> getPendingStockAlertsCount() async {
    try {
      final snapshot = await _stockAlertsCollection
          .where('status', isEqualTo: StockAlertStatus.pending.name)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao buscar alertas de estoque pendentes', error: e);
      return 0;
    }
  }
}
