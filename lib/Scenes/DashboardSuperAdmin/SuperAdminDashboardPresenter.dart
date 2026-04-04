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
      final results = await Future.wait([
        _repository.loadDashboardSnapshot(),
        _analyticsService.getAnalytics(),
      ]);

      final snapshot = results[0] as SuperAdminDashboardSnapshot;
      final analytics = results[1] as PlatformAnalyticsModel;

      _update(
        _viewModel.copyWith(
          isLoading: false,
          totalTenants: snapshot.totalTenants,
          activeTenants: snapshot.activeTenants,
          trialTenants: snapshot.trialTenants,
          mrr: snapshot.mrr,
          newTenantsThisMonth: snapshot.newTenantsThisMonth,
          trialExpiringIn7Days: snapshot.trialExpiringIn7Days,
          planDistribution: snapshot.planDistribution,
          tenantGrowth: snapshot.tenantGrowth,
          recentActivities: snapshot.recentActivities,
          trialExpiringSoon: snapshot.trialExpiringSoon,
          inactiveCount: snapshot.inactiveCount,
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
        _repository.loadDashboardSnapshot(),
        _analyticsService.getAnalytics(forceRefresh: true),
      ]);

      final snapshot = results[0] as SuperAdminDashboardSnapshot;
      final analytics = results[1] as PlatformAnalyticsModel;

      _update(
        _viewModel.copyWith(
          isLoading: false,
          totalTenants: snapshot.totalTenants,
          activeTenants: snapshot.activeTenants,
          trialTenants: snapshot.trialTenants,
          mrr: snapshot.mrr,
          newTenantsThisMonth: snapshot.newTenantsThisMonth,
          trialExpiringIn7Days: snapshot.trialExpiringIn7Days,
          planDistribution: snapshot.planDistribution,
          tenantGrowth: snapshot.tenantGrowth,
          recentActivities: snapshot.recentActivities,
          trialExpiringSoon: snapshot.trialExpiringSoon,
          inactiveCount: snapshot.inactiveCount,
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
