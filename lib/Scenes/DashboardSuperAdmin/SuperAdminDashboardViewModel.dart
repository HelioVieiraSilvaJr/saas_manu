import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Models/PlatformAnalyticsModel.dart';
import 'SuperAdminRepository.dart';

/// ViewModel do Dashboard SuperAdmin.
class SuperAdminDashboardViewModel {
  // Loading
  final bool isLoading;
  final String? errorMessage;

  // Métricas de Tenants
  final int totalTenants;
  final int activeTenants;
  final int trialTenants;
  final double mrr;
  final int newTenantsThisMonth;
  final int trialExpiringIn7Days;

  // Analytics Globais (vendas agregadas de todos os tenants)
  final double totalSalesToday;
  final double totalSalesMonth;
  final int salesCountToday;
  final int salesCountMonth;
  final int totalCustomers;
  final int newCustomersMonth;
  final double averageTicketMonth;
  final List<TopTenantDTO> topTenants;
  final DateTime? analyticsLastUpdated;

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
    this.totalSalesToday = 0,
    this.totalSalesMonth = 0,
    this.salesCountToday = 0,
    this.salesCountMonth = 0,
    this.totalCustomers = 0,
    this.newCustomersMonth = 0,
    this.averageTicketMonth = 0,
    this.topTenants = const [],
    this.analyticsLastUpdated,
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

  String get analyticsAgeLabel {
    if (analyticsLastUpdated == null) return '';
    final minutes = DateTime.now().difference(analyticsLastUpdated!).inMinutes;
    if (minutes < 1) return 'Atualizado agora';
    if (minutes < 60) return 'Atualizado há ${minutes}min';
    final hours = minutes ~/ 60;
    return 'Atualizado há ${hours}h';
  }

  SuperAdminDashboardViewModel copyWith({
    bool? isLoading,
    String? errorMessage,
    int? totalTenants,
    int? activeTenants,
    int? trialTenants,
    double? mrr,
    int? newTenantsThisMonth,
    int? trialExpiringIn7Days,
    double? totalSalesToday,
    double? totalSalesMonth,
    int? salesCountToday,
    int? salesCountMonth,
    int? totalCustomers,
    int? newCustomersMonth,
    double? averageTicketMonth,
    List<TopTenantDTO>? topTenants,
    DateTime? analyticsLastUpdated,
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
      totalSalesToday: totalSalesToday ?? this.totalSalesToday,
      totalSalesMonth: totalSalesMonth ?? this.totalSalesMonth,
      salesCountToday: salesCountToday ?? this.salesCountToday,
      salesCountMonth: salesCountMonth ?? this.salesCountMonth,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      newCustomersMonth: newCustomersMonth ?? this.newCustomersMonth,
      averageTicketMonth: averageTicketMonth ?? this.averageTicketMonth,
      topTenants: topTenants ?? this.topTenants,
      analyticsLastUpdated: analyticsLastUpdated ?? this.analyticsLastUpdated,
      planDistribution: planDistribution ?? this.planDistribution,
      tenantGrowth: tenantGrowth ?? this.tenantGrowth,
      recentActivities: recentActivities ?? this.recentActivities,
      trialExpiringSoon: trialExpiringSoon ?? this.trialExpiringSoon,
      inactiveCount: inactiveCount ?? this.inactiveCount,
    );
  }
}
