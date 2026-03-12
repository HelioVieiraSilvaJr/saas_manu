import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Models/PlatformAnalyticsModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/PlatformAnalyticsService.dart';
import 'SuperAdminRepository.dart';
import 'SuperAdminDashboardViewModel.dart';

/// Presenter do Dashboard SuperAdmin.
class SuperAdminDashboardPresenter {
  final SuperAdminRepository _repository = SuperAdminRepository();
  final PlatformAnalyticsService _analyticsService =
      PlatformAnalyticsService.instance;
  final void Function(SuperAdminDashboardViewModel) onViewModelUpdated;

  SuperAdminDashboardViewModel _viewModel =
      const SuperAdminDashboardViewModel();

  SuperAdminDashboardPresenter({required this.onViewModelUpdated});

  SuperAdminDashboardViewModel get viewModel => _viewModel;

  void _update(SuperAdminDashboardViewModel vm) {
    _viewModel = vm;
    onViewModelUpdated(vm);
  }

  /// Carrega todos os dados do dashboard.
  Future<void> loadDashboard() async {
    _update(_viewModel.copyWith(isLoading: true));

    try {
      // Carregar métricas de tenants e analytics globais em paralelo
      final results = await Future.wait([
        _repository.countTenants(), // 0
        _repository.countActiveTenants(), // 1
        _repository.countTrialTenants(), // 2
        _repository.calculateMRR(), // 3
        _repository.countNewTenantsThisMonth(), // 4
        _repository.countTrialExpiringIn(7), // 5
        _repository.getPlanDistribution(), // 6
        _repository.getTenantGrowth30Days(), // 7
        _repository.getRecentActivities(), // 8
        _repository.getTrialExpiringSoon(), // 9
        _repository.countInactiveTenants30Days(), // 10
        _analyticsService.getAnalytics(), // 11
      ]);

      final analytics = results[11] as PlatformAnalyticsModel;

      _update(
        _viewModel.copyWith(
          isLoading: false,
          totalTenants: results[0] as int,
          activeTenants: results[1] as int,
          trialTenants: results[2] as int,
          mrr: results[3] as double,
          newTenantsThisMonth: results[4] as int,
          trialExpiringIn7Days: results[5] as int,
          planDistribution: results[6] as Map<String, int>,
          tenantGrowth: results[7] as Map<DateTime, int>,
          recentActivities: results[8] as List<ActivityDTO>,
          trialExpiringSoon: results[9] as List<TenantModel>,
          inactiveCount: results[10] as int,
          totalSalesToday: analytics.totalSalesToday,
          totalSalesMonth: analytics.totalSalesMonth,
          salesCountToday: analytics.salesCountToday,
          salesCountMonth: analytics.salesCountMonth,
          totalCustomers: analytics.totalCustomers,
          newCustomersMonth: analytics.newCustomersMonth,
          averageTicketMonth: analytics.averageTicketMonth,
          topTenants: analytics.topTenants,
          analyticsLastUpdated: analytics.lastUpdated,
        ),
      );
    } catch (e) {
      AppLogger.error('Erro ao carregar dashboard SuperAdmin', error: e);
      _update(
        _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar dados do dashboard.',
        ),
      );
    }
  }

  /// Atualiza o dashboard (força recálculo dos analytics).
  Future<void> refresh() async {
    _update(_viewModel.copyWith(isLoading: true));

    try {
      final results = await Future.wait([
        _repository.countTenants(),
        _repository.countActiveTenants(),
        _repository.countTrialTenants(),
        _repository.calculateMRR(),
        _repository.countNewTenantsThisMonth(),
        _repository.countTrialExpiringIn(7),
        _repository.getPlanDistribution(),
        _repository.getTenantGrowth30Days(),
        _repository.getRecentActivities(),
        _repository.getTrialExpiringSoon(),
        _repository.countInactiveTenants30Days(),
        _analyticsService.getAnalytics(forceRefresh: true),
      ]);

      final analytics = results[11] as PlatformAnalyticsModel;

      _update(
        _viewModel.copyWith(
          isLoading: false,
          totalTenants: results[0] as int,
          activeTenants: results[1] as int,
          trialTenants: results[2] as int,
          mrr: results[3] as double,
          newTenantsThisMonth: results[4] as int,
          trialExpiringIn7Days: results[5] as int,
          planDistribution: results[6] as Map<String, int>,
          tenantGrowth: results[7] as Map<DateTime, int>,
          recentActivities: results[8] as List<ActivityDTO>,
          trialExpiringSoon: results[9] as List<TenantModel>,
          inactiveCount: results[10] as int,
          totalSalesToday: analytics.totalSalesToday,
          totalSalesMonth: analytics.totalSalesMonth,
          salesCountToday: analytics.salesCountToday,
          salesCountMonth: analytics.salesCountMonth,
          totalCustomers: analytics.totalCustomers,
          newCustomersMonth: analytics.newCustomersMonth,
          averageTicketMonth: analytics.averageTicketMonth,
          topTenants: analytics.topTenants,
          analyticsLastUpdated: analytics.lastUpdated,
        ),
      );
    } catch (e) {
      AppLogger.error('Erro ao atualizar dashboard SuperAdmin', error: e);
      _update(
        _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao atualizar dados.',
        ),
      );
    }
  }
}
