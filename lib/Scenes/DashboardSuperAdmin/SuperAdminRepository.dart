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

/// Snapshot consolidado do dashboard SuperAdmin para reduzir múltiplas queries.
class SuperAdminDashboardSnapshot {
  final int totalTenants;
  final int activeTenants;
  final int trialTenants;
  final double mrr;
  final int newTenantsThisMonth;
  final int trialExpiringIn7Days;
  final Map<String, int> planDistribution;
  final Map<DateTime, int> tenantGrowth;
  final List<ActivityDTO> recentActivities;
  final List<TenantModel> trialExpiringSoon;
  final int inactiveCount;

  const SuperAdminDashboardSnapshot({
    required this.totalTenants,
    required this.activeTenants,
    required this.trialTenants,
    required this.mrr,
    required this.newTenantsThisMonth,
    required this.trialExpiringIn7Days,
    required this.planDistribution,
    required this.tenantGrowth,
    required this.recentActivities,
    required this.trialExpiringSoon,
    required this.inactiveCount,
  });
}

/// Repository do Dashboard SuperAdmin.
///
/// Acessa dados cross-tenant (coleção global `tenants/`).
class SuperAdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Map<String, int> _basePlanDistribution = {
    'trial': 0,
    'monthly_standard': 0,
    'monthly_pro': 0,
    'quarterly_standard': 0,
    'quarterly_pro': 0,
  };

  CollectionReference<Map<String, dynamic>> get _tenantsCollection =>
      _firestore.collection('tenants');

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Carrega o snapshot consolidado do dashboard usando uma única leitura de tenants.
  Future<SuperAdminDashboardSnapshot> loadDashboardSnapshot() async {
    try {
      final tenants = await getAllTenants();
      final now = DateTime.now();
      final startOfToday = _dateOnly(now);
      final startOfMonth = DateTime(now.year, now.month, 1);
      final growthWindowStart = startOfToday.subtract(const Duration(days: 29));
      final trialLimit3Days = now.add(const Duration(days: 3));
      final trialLimit7Days = now.add(const Duration(days: 7));

      final planDistribution = Map<String, int>.from(_basePlanDistribution);
      final tenantGrowth = <DateTime, int>{};
      for (int i = 0; i < 30; i++) {
        final day = growthWindowStart.add(Duration(days: i));
        tenantGrowth[day] = 0;
      }

      var activeTenants = 0;
      var trialTenants = 0;
      var newTenantsThisMonth = 0;
      var trialExpiringIn7Days = 0;
      var inactiveCount = 0;
      var mrr = 0.0;
      final recentActivities = <ActivityDTO>[];
      final trialExpiringSoon = <TenantModel>[];

      for (final tenant in tenants) {
        if (tenant.isActive) {
          activeTenants++;
        } else {
          inactiveCount++;
        }

        if (!tenant.createdAt.isBefore(startOfMonth)) {
          newTenantsThisMonth++;
        }

        final createdDay = _dateOnly(tenant.createdAt);
        if (!createdDay.isBefore(growthWindowStart)) {
          tenantGrowth[createdDay] = (tenantGrowth[createdDay] ?? 0) + 1;
        }

        if (recentActivities.length < 10) {
          recentActivities.add(
            ActivityDTO(
              description: 'Novo tenant criado',
              tenantName: tenant.name,
              timestamp: tenant.createdAt,
              type: ActivityType.created,
            ),
          );
        }

        if (tenant.isTrial) {
          trialTenants++;
          planDistribution['trial'] = (planDistribution['trial'] ?? 0) + 1;

          final trialEndDate = tenant.trialEndDate;
          if (tenant.isActive &&
              trialEndDate != null &&
              !trialEndDate.isBefore(now)) {
            if (!trialEndDate.isAfter(trialLimit7Days)) {
              trialExpiringIn7Days++;
            }
            if (!trialEndDate.isAfter(trialLimit3Days)) {
              trialExpiringSoon.add(tenant);
            }
          }
          continue;
        }

        final planKey = '${tenant.plan}_${tenant.planTier}';
        planDistribution[planKey] = (planDistribution[planKey] ?? 0) + 1;

        if (tenant.isActive) {
          final price = tenant.planPrice;
          mrr += tenant.plan == 'quarterly' ? price / 3 : price;
        }
      }

      trialExpiringSoon.sort((a, b) {
        final aDate = a.trialEndDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.trialEndDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

      return SuperAdminDashboardSnapshot(
        totalTenants: tenants.length,
        activeTenants: activeTenants,
        trialTenants: trialTenants,
        mrr: mrr,
        newTenantsThisMonth: newTenantsThisMonth,
        trialExpiringIn7Days: trialExpiringIn7Days,
        planDistribution: planDistribution,
        tenantGrowth: tenantGrowth,
        recentActivities: recentActivities,
        trialExpiringSoon: trialExpiringSoon,
        inactiveCount: inactiveCount,
      );
    } catch (e) {
      AppLogger.error('Erro ao carregar snapshot do dashboard', error: e);
      return const SuperAdminDashboardSnapshot(
        totalTenants: 0,
        activeTenants: 0,
        trialTenants: 0,
        mrr: 0,
        newTenantsThisMonth: 0,
        trialExpiringIn7Days: 0,
        planDistribution: _basePlanDistribution,
        tenantGrowth: {},
        recentActivities: [],
        trialExpiringSoon: [],
        inactiveCount: 0,
      );
    }
  }

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

  /// Conta tenants por plano (agrupado por período + tier).
  Future<Map<String, int>> getPlanDistribution() async {
    try {
      final tenants = await getAllTenants();
      final distribution = <String, int>{..._basePlanDistribution};
      for (final tenant in tenants) {
        if (tenant.isTrial) {
          distribution['trial'] = (distribution['trial'] ?? 0) + 1;
        } else {
          final key = '${tenant.plan}_${tenant.planTier}';
          distribution[key] = (distribution[key] ?? 0) + 1;
        }
      }
      return distribution;
    } catch (e) {
      AppLogger.error('Erro ao buscar distribuição de planos', error: e);
      return {..._basePlanDistribution};
    }
  }

  // MARK: - MRR

  /// Calcula MRR (Monthly Recurring Revenue).
  /// Usa preços reais de PlanTier por PlanPeriod, normalizados para mensal.
  Future<double> calculateMRR() async {
    try {
      final tenants = await getAllTenants();
      double mrr = 0;
      for (final tenant in tenants) {
        if (!tenant.isActive || tenant.isTrial) continue;
        // Normalizar para valor mensal
        final price = tenant.planPrice;
        if (tenant.plan == 'quarterly') {
          mrr += price / 3; // Trimestral dividido por 3
        } else {
          mrr += price; // Mensal direto
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
