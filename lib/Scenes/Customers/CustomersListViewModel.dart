import '../../Commons/Models/CustomerModel.dart';

/// Enum para filtro de status dos clientes.
enum CustomerStatusFilter {
  all, // Todos
  active, // Já compraram
  inactive, // Nunca compraram
}

/// Enum para filtro de período da última compra.
enum CustomerPurchasePeriod {
  all, // Todos
  last7Days,
  last30Days,
  last90Days,
}

/// Enum para ordenação de clientes.
enum CustomerSortOption {
  newestFirst, // Data cadastro (recente)
  oldestFirst, // Data cadastro (antiga)
  nameAZ,
  nameZA,
  lastPurchaseRecent,
  lastPurchaseOld,
  totalSpentHigh,
  totalSpentLow,
}

/// Estado da lista de clientes.
class CustomersListViewModel {
  final bool isLoading;
  final String? errorMessage;
  final List<CustomerModel> allCustomers;
  final List<CustomerModel> filteredCustomers;
  final String searchQuery;
  final CustomerStatusFilter statusFilter;
  final CustomerPurchasePeriod purchasePeriod;
  final CustomerSortOption sortOption;
  final bool isDeleting;

  const CustomersListViewModel({
    this.isLoading = true,
    this.errorMessage,
    this.allCustomers = const [],
    this.filteredCustomers = const [],
    this.searchQuery = '',
    this.statusFilter = CustomerStatusFilter.all,
    this.purchasePeriod = CustomerPurchasePeriod.all,
    this.sortOption = CustomerSortOption.newestFirst,
    this.isDeleting = false,
  });

  /// Total de clientes (sem filtro).
  int get totalCount => allCustomers.length;

  /// Total de clientes filtrados.
  int get filteredCount => filteredCustomers.length;

  /// Verifica se existem filtros ativos.
  bool get hasActiveFilters =>
      statusFilter != CustomerStatusFilter.all ||
      purchasePeriod != CustomerPurchasePeriod.all;

  /// Verifica se tem busca ativa.
  bool get hasSearch => searchQuery.isNotEmpty;

  CustomersListViewModel copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CustomerModel>? allCustomers,
    List<CustomerModel>? filteredCustomers,
    String? searchQuery,
    CustomerStatusFilter? statusFilter,
    CustomerPurchasePeriod? purchasePeriod,
    CustomerSortOption? sortOption,
    bool? isDeleting,
    bool clearError = true,
  }) {
    return CustomersListViewModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError
          ? errorMessage
          : (errorMessage ?? this.errorMessage),
      allCustomers: allCustomers ?? this.allCustomers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      purchasePeriod: purchasePeriod ?? this.purchasePeriod,
      sortOption: sortOption ?? this.sortOption,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}
