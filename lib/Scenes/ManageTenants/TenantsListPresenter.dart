import 'dart:async';
import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import 'TenantsRepository.dart';
import 'TenantsListViewModel.dart';

/// Presenter da listagem de tenants (SuperAdmin).
class TenantsListPresenter {
  final TenantsRepository _repository = TenantsRepository();
  TenantsListViewModel viewModel = const TenantsListViewModel();
  void Function()? onUpdate;

  Timer? _debounce;

  void _notify() {
    onUpdate?.call();
  }

  /// Carrega todos os tenants.
  Future<void> loadTenants() async {
    viewModel = viewModel.copyWith(isLoading: true);
    _notify();

    try {
      final tenants = await _repository.getAll();
      viewModel = viewModel.copyWith(
        isLoading: false,
        allTenants: tenants,
        filteredTenants: tenants,
      );
      _applyFiltersAndSort();
    } catch (e) {
      AppLogger.error('Erro ao carregar tenants', error: e);
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar tenants.',
      );
      _notify();
    }
  }

  // MARK: - Busca

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      viewModel = viewModel.copyWith(searchQuery: query);
      _applyFiltersAndSort();
    });
  }

  // MARK: - Filtros

  void setPlanFilter(TenantPlanFilter filter) {
    viewModel = viewModel.copyWith(planFilter: filter);
    _applyFiltersAndSort();
  }

  void setStatusFilter(TenantStatusFilter filter) {
    viewModel = viewModel.copyWith(statusFilter: filter);
    _applyFiltersAndSort();
  }

  void setSituationFilter(TenantSituationFilter filter) {
    viewModel = viewModel.copyWith(situationFilter: filter);
    _applyFiltersAndSort();
  }

  void setSortOption(TenantSortOption option) {
    viewModel = viewModel.copyWith(sortOption: option);
    _applyFiltersAndSort();
  }

  void clearFilters() {
    viewModel = viewModel.copyWith(
      searchQuery: '',
      planFilter: TenantPlanFilter.all,
      statusFilter: TenantStatusFilter.all,
      situationFilter: TenantSituationFilter.all,
      sortOption: TenantSortOption.newestFirst,
    );
    _applyFiltersAndSort();
  }

  // MARK: - Filtro + Sort interno

  void _applyFiltersAndSort() {
    var result = List<TenantModel>.from(viewModel.allTenants);

    // Busca
    if (viewModel.searchQuery.isNotEmpty) {
      final q = viewModel.searchQuery.toLowerCase();
      result = result.where((t) {
        return t.name.toLowerCase().contains(q) ||
            t.contactEmail.toLowerCase().contains(q) ||
            t.contactPhone.contains(q);
      }).toList();
    }

    // Filtro por plano
    switch (viewModel.planFilter) {
      case TenantPlanFilter.trial:
        result = result.where((t) => t.plan == 'trial').toList();
        break;
      case TenantPlanFilter.monthly:
        result = result
            .where((t) => t.plan == 'monthly' && t.planTier == 'standard')
            .toList();
        break;
      case TenantPlanFilter.monthlyPro:
        result = result
            .where((t) => t.plan == 'monthly' && t.planTier == 'pro')
            .toList();
        break;
      case TenantPlanFilter.quarterly:
        result = result
            .where((t) => t.plan == 'quarterly' && t.planTier == 'standard')
            .toList();
        break;
      case TenantPlanFilter.quarterlyPro:
        result = result
            .where((t) => t.plan == 'quarterly' && t.planTier == 'pro')
            .toList();
        break;
      case TenantPlanFilter.all:
        break;
    }

    // Filtro por status
    switch (viewModel.statusFilter) {
      case TenantStatusFilter.active:
        result = result.where((t) => t.isActive).toList();
        break;
      case TenantStatusFilter.inactive:
        result = result.where((t) => !t.isActive).toList();
        break;
      case TenantStatusFilter.all:
        break;
    }

    // Filtro por situação
    final now = DateTime.now();
    switch (viewModel.situationFilter) {
      case TenantSituationFilter.trialExpiring:
        result = result.where((t) {
          return t.isTrial &&
              t.trialEndDate != null &&
              t.trialDaysRemaining >= 0 &&
              t.trialDaysRemaining <= 7;
        }).toList();
        break;
      case TenantSituationFilter.expiringSoon:
        result = result.where((t) => t.isExpirationWarning).toList();
        break;
      case TenantSituationFilter.expired:
        result = result.where((t) => t.isExpiredDynamic).toList();
        break;
      case TenantSituationFilter.createdToday:
        final startOfDay = DateTime(now.year, now.month, now.day);
        result = result.where((t) => t.createdAt.isAfter(startOfDay)).toList();
        break;
      case TenantSituationFilter.createdLast7Days:
        final start = now.subtract(const Duration(days: 7));
        result = result.where((t) => t.createdAt.isAfter(start)).toList();
        break;
      case TenantSituationFilter.createdLast30Days:
        final start = now.subtract(const Duration(days: 30));
        result = result.where((t) => t.createdAt.isAfter(start)).toList();
        break;
      case TenantSituationFilter.all:
        break;
    }

    // Ordenação
    switch (viewModel.sortOption) {
      case TenantSortOption.nameAZ:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case TenantSortOption.nameZA:
        result.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case TenantSortOption.newestFirst:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TenantSortOption.oldestFirst:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case TenantSortOption.planAsc:
        result.sort((a, b) => _planOrder(a.plan).compareTo(_planOrder(b.plan)));
        break;
      case TenantSortOption.planDesc:
        result.sort((a, b) => _planOrder(b.plan).compareTo(_planOrder(a.plan)));
        break;
    }

    viewModel = viewModel.copyWith(filteredTenants: result);
    _notify();
  }

  int _planOrder(String plan) {
    switch (plan) {
      case 'trial':
        return 0;
      case 'monthly':
        return 1;
      case 'quarterly':
        return 2;
      default:
        return 0;
    }
  }

  // MARK: - Delete

  Future<bool> deleteTenant(String tenantId) async {
    viewModel = viewModel.copyWith(isDeleting: true);
    _notify();

    final success = await _repository.deleteTenant(tenantId);

    if (success) {
      await loadTenants();
    }

    viewModel = viewModel.copyWith(isDeleting: false);
    _notify();
    return success;
  }

  void dispose() {
    _debounce?.cancel();
  }
}
