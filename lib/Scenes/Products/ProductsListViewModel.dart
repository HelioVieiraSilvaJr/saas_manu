import '../../Commons/Models/ProductModel.dart';

/// Enum para filtro de status dos produtos.
enum ProductStatusFilter { all, active, inactive }

/// Enum para filtro de estoque dos produtos.
enum ProductStockFilter { all, available, outOfStock, lowStock }

/// Enum para ordenação de produtos.
enum ProductSortOption {
  newestFirst,
  oldestFirst,
  nameAZ,
  nameZA,
  priceLow,
  priceHigh,
  stockLow,
  stockHigh,
}

/// Estado da lista de produtos.
class ProductsListViewModel {
  final bool isLoading;
  final String? errorMessage;
  final List<ProductModel> allProducts;
  final List<ProductModel> filteredProducts;
  final String searchQuery;
  final ProductStatusFilter statusFilter;
  final ProductStockFilter stockFilter;
  final ProductSortOption sortOption;
  final bool isDeleting;

  const ProductsListViewModel({
    this.isLoading = true,
    this.errorMessage,
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.statusFilter = ProductStatusFilter.all,
    this.stockFilter = ProductStockFilter.all,
    this.sortOption = ProductSortOption.newestFirst,
    this.isDeleting = false,
  });

  /// Total de produtos (sem filtro).
  int get totalCount => allProducts.length;

  /// Total de produtos filtrados.
  int get filteredCount => filteredProducts.length;

  /// Verifica se existem filtros ativos.
  bool get hasActiveFilters =>
      statusFilter != ProductStatusFilter.all ||
      stockFilter != ProductStockFilter.all;

  /// Verifica se tem busca ativa.
  bool get hasSearch => searchQuery.isNotEmpty;

  ProductsListViewModel copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ProductModel>? allProducts,
    List<ProductModel>? filteredProducts,
    String? searchQuery,
    ProductStatusFilter? statusFilter,
    ProductStockFilter? stockFilter,
    ProductSortOption? sortOption,
    bool? isDeleting,
    bool clearError = true,
  }) {
    return ProductsListViewModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError
          ? errorMessage
          : (errorMessage ?? this.errorMessage),
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      stockFilter: stockFilter ?? this.stockFilter,
      sortOption: sortOption ?? this.sortOption,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}
