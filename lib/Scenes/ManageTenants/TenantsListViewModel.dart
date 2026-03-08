import '../../Commons/Models/TenantModel.dart';

/// Filtro por plano do tenant.
enum TenantPlanFilter {
  all('Todos'),
  trial('Trial'),
  basic('Basic'),
  full('Full');

  final String label;
  const TenantPlanFilter(this.label);
}

/// Filtro por status do tenant.
enum TenantStatusFilter {
  all('Todos'),
  active('Ativos'),
  inactive('Inativos');

  final String label;
  const TenantStatusFilter(this.label);
}

/// Filtro por situação.
enum TenantSituationFilter {
  all('Todas'),
  trialExpiring('Trial Expirando'),
  createdToday('Criados Hoje'),
  createdLast7Days('Últimos 7 dias'),
  createdLast30Days('Últimos 30 dias');

  final String label;
  const TenantSituationFilter(this.label);
}

/// Ordenação de tenants.
enum TenantSortOption {
  nameAZ('Nome (A-Z)'),
  nameZA('Nome (Z-A)'),
  newestFirst('Mais Recentes'),
  oldestFirst('Mais Antigos'),
  planAsc('Plano (Trial → Full)'),
  planDesc('Plano (Full → Trial)');

  final String label;
  const TenantSortOption(this.label);
}

/// ViewModel da listagem de tenants.
class TenantsListViewModel {
  final bool isLoading;
  final bool isDeleting;
  final String? errorMessage;

  final List<TenantModel> allTenants;
  final List<TenantModel> filteredTenants;

  final String searchQuery;
  final TenantPlanFilter planFilter;
  final TenantStatusFilter statusFilter;
  final TenantSituationFilter situationFilter;
  final TenantSortOption sortOption;

  const TenantsListViewModel({
    this.isLoading = true,
    this.isDeleting = false,
    this.errorMessage,
    this.allTenants = const [],
    this.filteredTenants = const [],
    this.searchQuery = '',
    this.planFilter = TenantPlanFilter.all,
    this.statusFilter = TenantStatusFilter.all,
    this.situationFilter = TenantSituationFilter.all,
    this.sortOption = TenantSortOption.newestFirst,
  });

  // Computed

  int get totalCount => allTenants.length;
  int get filteredCount => filteredTenants.length;
  bool get hasActiveFilters =>
      planFilter != TenantPlanFilter.all ||
      statusFilter != TenantStatusFilter.all ||
      situationFilter != TenantSituationFilter.all;
  bool get hasSearch => searchQuery.isNotEmpty;

  TenantsListViewModel copyWith({
    bool? isLoading,
    bool? isDeleting,
    String? errorMessage,
    List<TenantModel>? allTenants,
    List<TenantModel>? filteredTenants,
    String? searchQuery,
    TenantPlanFilter? planFilter,
    TenantStatusFilter? statusFilter,
    TenantSituationFilter? situationFilter,
    TenantSortOption? sortOption,
  }) {
    return TenantsListViewModel(
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage ?? this.errorMessage,
      allTenants: allTenants ?? this.allTenants,
      filteredTenants: filteredTenants ?? this.filteredTenants,
      searchQuery: searchQuery ?? this.searchQuery,
      planFilter: planFilter ?? this.planFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      situationFilter: situationFilter ?? this.situationFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}
