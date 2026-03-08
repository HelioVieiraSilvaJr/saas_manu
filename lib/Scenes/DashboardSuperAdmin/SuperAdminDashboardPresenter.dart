import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import 'SuperAdminRepository.dart';
import 'SuperAdminDashboardViewModel.dart';

/// Presenter do Dashboard SuperAdmin.
class SuperAdminDashboardPresenter {
  final SuperAdminRepository _repository = SuperAdminRepository();
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
      // Carregar métricas em paralelo
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
      ]);

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

  /// Atualiza o dashboard.
  Future<void> refresh() => loadDashboard();
}
