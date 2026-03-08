import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Utils/AppLogger.dart';

/// DTO para atividade recente do SuperAdmin.
class ActivityDTO {
  final String description;
  final String tenantName;
  final DateTime timestamp;
  final ActivityType type;

  ActivityDTO({
    required this.description,
    required this.tenantName,
    required this.timestamp,
    required this.type,
  });
}

enum ActivityType { created, upgraded, deactivated, reactivated }

/// Repository do Dashboard SuperAdmin.
///
/// Acessa dados cross-tenant (coleção global `tenants/`).
class SuperAdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tenantsCollection =>
      _firestore.collection('tenants');

  // MARK: - Tenants

  /// Busca todos os tenants.
  Future<List<TenantModel>> getAllTenants() async {
    try {
      final snapshot = await _tenantsCollection
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TenantModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar tenants', error: e);
      return [];
    }
  }

  /// Total de tenants.
  Future<int> countTenants() async {
    try {
      final snapshot = await _tenantsCollection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar tenants', error: e);
      return 0;
    }
  }

  /// Tenants ativos.
  Future<int> countActiveTenants() async {
    try {
      final snapshot = await _tenantsCollection
          .where('is_active', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar tenants ativos', error: e);
      return 0;
    }
  }

  /// Tenants em trial.
  Future<int> countTrialTenants() async {
    try {
      final snapshot = await _tenantsCollection
          .where('plan', isEqualTo: 'trial')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar tenants trial', error: e);
      return 0;
    }
  }

  /// Tenants com trial expirando nos próximos X dias.
  Future<int> countTrialExpiringIn(int days) async {
    try {
      final now = DateTime.now();
      final limit = now.add(Duration(days: days));
      final snapshot = await _tenantsCollection
          .where('plan', isEqualTo: 'trial')
          .where('is_active', isEqualTo: true)
          .where(
            'trial_end_date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
          )
          .where(
            'trial_end_date',
            isLessThanOrEqualTo: Timestamp.fromDate(limit),
          )
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar trials expirando', error: e);
      return 0;
    }
  }

  /// Novos tenants criados este mês.
  Future<int> countNewTenantsThisMonth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final snapshot = await _tenantsCollection
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar novos tenants', error: e);
      return 0;
    }
  }

  // MARK: - Distribuição por Plano

  /// Conta tenants por plano.
  Future<Map<String, int>> getPlanDistribution() async {
    try {
      final tenants = await getAllTenants();
      final distribution = <String, int>{'trial': 0, 'basic': 0, 'full': 0};
      for (final tenant in tenants) {
        distribution[tenant.plan] = (distribution[tenant.plan] ?? 0) + 1;
      }
      return distribution;
    } catch (e) {
      AppLogger.error('Erro ao buscar distribuição de planos', error: e);
      return {'trial': 0, 'basic': 0, 'full': 0};
    }
  }

  // MARK: - MRR

  /// Calcula MRR (Monthly Recurring Revenue).
  /// Basic = R$50, Full = R$150, Trial = R$0
  Future<double> calculateMRR() async {
    try {
      final tenants = await getAllTenants();
      double mrr = 0;
      for (final tenant in tenants) {
        if (!tenant.isActive) continue;
        switch (tenant.plan) {
          case 'basic':
            mrr += 50;
            break;
          case 'full':
            mrr += 150;
            break;
          default:
            break;
        }
      }
      return mrr;
    } catch (e) {
      AppLogger.error('Erro ao calcular MRR', error: e);
      return 0;
    }
  }

  // MARK: - Tenants criados nos últimos 30 dias (para gráfico)

  /// Retorna tenants criados nos últimos 30 dias agrupados por dia.
  Future<Map<DateTime, int>> getTenantGrowth30Days() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));

      final snapshot = await _tenantsCollection
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .orderBy('created_at')
          .get();

      final growth = <DateTime, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['created_at'] != null) {
          final date = (data['created_at'] as Timestamp).toDate();
          final dayKey = DateTime(date.year, date.month, date.day);
          growth[dayKey] = (growth[dayKey] ?? 0) + 1;
        }
      }
      return growth;
    } catch (e) {
      AppLogger.error('Erro ao buscar crescimento', error: e);
      return {};
    }
  }

  // MARK: - Atividades Recentes

  /// Busca últimas atividades (baseado em mudanças recentes em tenants).
  Future<List<ActivityDTO>> getRecentActivities({int limit = 10}) async {
    try {
      final snapshot = await _tenantsCollection
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      final activities = <ActivityDTO>[];
      for (final doc in snapshot.docs) {
        final tenant = TenantModel.fromDocumentSnapshot(doc);
        activities.add(
          ActivityDTO(
            description: 'Novo tenant criado',
            tenantName: tenant.name,
            timestamp: tenant.createdAt,
            type: ActivityType.created,
          ),
        );
      }
      return activities;
    } catch (e) {
      AppLogger.error('Erro ao buscar atividades', error: e);
      return [];
    }
  }

  // MARK: - Alertas

  /// Tenants com trial expirando em 3 dias.
  Future<List<TenantModel>> getTrialExpiringSoon() async {
    try {
      final now = DateTime.now();
      final limit = now.add(const Duration(days: 3));
      final snapshot = await _tenantsCollection
          .where('plan', isEqualTo: 'trial')
          .where('is_active', isEqualTo: true)
          .where(
            'trial_end_date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
          )
          .where(
            'trial_end_date',
            isLessThanOrEqualTo: Timestamp.fromDate(limit),
          )
          .get();

      return snapshot.docs
          .map((doc) => TenantModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar trials expirando', error: e);
      return [];
    }
  }

  /// Tenants inativos há mais de 30 dias.
  Future<int> countInactiveTenants30Days() async {
    try {
      final snapshot = await _tenantsCollection
          .where('is_active', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar inativos', error: e);
      return 0;
    }
  }

  // MARK: - Tenant Stats

  /// Conta subcoleções de um tenant (para detalhes).
  Future<Map<String, int>> getTenantStats(String tenantId) async {
    try {
      final products = await _firestore
          .collection('tenants/$tenantId/products')
          .count()
          .get();
      final customers = await _firestore
          .collection('tenants/$tenantId/customers')
          .count()
          .get();
      final sales = await _firestore
          .collection('tenants/$tenantId/sales')
          .count()
          .get();

      return {
        'products': products.count ?? 0,
        'customers': customers.count ?? 0,
        'sales': sales.count ?? 0,
      };
    } catch (e) {
      AppLogger.error('Erro ao buscar stats do tenant', error: e);
      return {'products': 0, 'customers': 0, 'sales': 0};
    }
  }
}
