import '../../Commons/Models/TenantModel.dart';
import 'SuperAdminRepository.dart';

/// ViewModel do Dashboard SuperAdmin.
class SuperAdminDashboardViewModel {
  // Loading
  final bool isLoading;
  final String? errorMessage;

  // Métricas
  final int totalTenants;
  final int activeTenants;
  final int trialTenants;
  final double mrr;
  final int newTenantsThisMonth;
  final int trialExpiringIn7Days;

  // Distribuição por plano
  final Map<String, int> planDistribution;

  // Crescimento (últimos 30 dias)
  final Map<DateTime, int> tenantGrowth;

  // Atividades recentes
  final List<ActivityDTO> recentActivities;

  // Alertas
  final List<TenantModel> trialExpiringSoon;
  final int inactiveCount;

  const SuperAdminDashboardViewModel({
    this.isLoading = true,
    this.errorMessage,
    this.totalTenants = 0,
    this.activeTenants = 0,
    this.trialTenants = 0,
    this.mrr = 0,
    this.newTenantsThisMonth = 0,
    this.trialExpiringIn7Days = 0,
    this.planDistribution = const {},
    this.tenantGrowth = const {},
    this.recentActivities = const [],
    this.trialExpiringSoon = const [],
    this.inactiveCount = 0,
  });

  // Computed

  double get activePercentage =>
      totalTenants > 0 ? (activeTenants / totalTenants) * 100 : 0;

  int get basicCount => planDistribution['basic'] ?? 0;
  int get fullCount => planDistribution['full'] ?? 0;
  int get trialCount => planDistribution['trial'] ?? 0;

  bool get hasAlerts => trialExpiringSoon.isNotEmpty || inactiveCount > 0;

  int get totalAlerts => trialExpiringSoon.length + (inactiveCount > 0 ? 1 : 0);

  SuperAdminDashboardViewModel copyWith({
    bool? isLoading,
    String? errorMessage,
    int? totalTenants,
    int? activeTenants,
    int? trialTenants,
    double? mrr,
    int? newTenantsThisMonth,
    int? trialExpiringIn7Days,
    Map<String, int>? planDistribution,
    Map<DateTime, int>? tenantGrowth,
    List<ActivityDTO>? recentActivities,
    List<TenantModel>? trialExpiringSoon,
    int? inactiveCount,
  }) {
    return SuperAdminDashboardViewModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      totalTenants: totalTenants ?? this.totalTenants,
      activeTenants: activeTenants ?? this.activeTenants,
      trialTenants: trialTenants ?? this.trialTenants,
      mrr: mrr ?? this.mrr,
      newTenantsThisMonth: newTenantsThisMonth ?? this.newTenantsThisMonth,
      trialExpiringIn7Days: trialExpiringIn7Days ?? this.trialExpiringIn7Days,
      planDistribution: planDistribution ?? this.planDistribution,
      tenantGrowth: tenantGrowth ?? this.tenantGrowth,
      recentActivities: recentActivities ?? this.recentActivities,
      trialExpiringSoon: trialExpiringSoon ?? this.trialExpiringSoon,
      inactiveCount: inactiveCount ?? this.inactiveCount,
    );
  }
}
