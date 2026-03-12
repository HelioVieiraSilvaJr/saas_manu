import 'dart:async';
import 'package:flutter/material.dart';
import '../../Commons/Models/ProductModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import 'ProductsRepository.dart';
import 'ProductsListViewModel.dart';

/// Presenter da listagem de produtos (MVP).
class ProductsListPresenter {
  final ProductsRepository _repository = ProductsRepository();
  final ValueChanged<ProductsListViewModel> onViewModelUpdated;

  ProductsListViewModel _viewModel = const ProductsListViewModel();
  ProductsListViewModel get viewModel => _viewModel;

  BuildContext? context;
  Timer? _debounceTimer;

  ProductsListPresenter({required this.onViewModelUpdated});

  // MARK: - Load

  /// Carrega produtos. Usa cache se disponível.
  Future<void> loadProducts({bool forceRefresh = false}) async {
    // Se cache está fresco, usa sem loading
    if (!forceRefresh && ProductsRepository.productsCache.isFresh) {
      final products = ProductsRepository.productsCache.data;
      _update(_viewModel.copyWith(isLoading: false, allProducts: products));
      _applyFiltersAndSort();
      return;
    }

    _update(_viewModel.copyWith(isLoading: true));

    try {
      final products = await _repository.getAll(forceRefresh: forceRefresh);
      _update(_viewModel.copyWith(isLoading: false, allProducts: products));
      _applyFiltersAndSort();
      AppLogger.info('Produtos carregados: ${products.length}');
    } catch (e) {
      AppLogger.error('Erro ao carregar produtos', error: e);
      _update(
        _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar produtos.',
          clearError: false,
        ),
      );
    }
  }

  /// Recarregar produtos (forçando refresh do Firestore).
  Future<void> refresh() async {
    await loadProducts(forceRefresh: true);
  }

  // MARK: - Search

  /// Atualiza a busca com debounce de 300ms.
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _update(_viewModel.copyWith(searchQuery: query));
      _applyFiltersAndSort();
    });
  }

  /// Limpa a busca.
  void clearSearch() {
    _debounceTimer?.cancel();
    _update(_viewModel.copyWith(searchQuery: ''));
    _applyFiltersAndSort();
  }

  // MARK: - Filters

  /// Altera filtro de status.
  void setStatusFilter(ProductStatusFilter filter) {
    _update(_viewModel.copyWith(statusFilter: filter));
    _applyFiltersAndSort();
  }

  /// Altera filtro de estoque.
  void setStockFilter(ProductStockFilter filter) {
    _update(_viewModel.copyWith(stockFilter: filter));
    _applyFiltersAndSort();
  }

  /// Limpa todos os filtros.
  void clearFilters() {
    _update(
      _viewModel.copyWith(
        statusFilter: ProductStatusFilter.all,
        stockFilter: ProductStockFilter.all,
        searchQuery: '',
      ),
    );
    _applyFiltersAndSort();
  }

  // MARK: - Sort

  /// Altera a ordenação.
  void setSortOption(ProductSortOption option) {
    _update(_viewModel.copyWith(sortOption: option));
    _applyFiltersAndSort();
  }

  // MARK: - Delete

  /// Deleta um produto (soft ou hard delete).
  Future<void> deleteProduct(ProductModel product) async {
    if (context == null) return;

    // Verificar se tem vendas
    final hasSales = await _repository.productHasSales(product.uid);

    if (hasSales) {
      // Soft delete - inativar
      final confirm = await DSAlertDialog.showWarning(
        context: context!,
        title: 'Produto com Vendas',
        message:
            'Este produto possui vendas registradas e será inativado (não deletado).',
      );

      if (confirm == true) {
        _update(_viewModel.copyWith(isDeleting: true));
        final success = await _repository.update(
          product.copyWith(isActive: false),
        );
        _update(_viewModel.copyWith(isDeleting: false));

        if (success) {
          await DSAlertDialog.showSuccess(
            context: context!,
            title: 'Produto Inativado',
            message: '${product.name} foi inativado com sucesso.',
          );
          ProductsRepository.productsCache.invalidate();
          await loadProducts(forceRefresh: true);
        }
      }
    } else {
      // Hard delete
      final confirm = await DSAlertDialog.showDelete(
        context: context!,
        title: 'Confirmar Exclusão',
        message: 'Este produto será removido permanentemente.',
        content: DSAlertContentCard(
          icon: Icons.shopping_bag_outlined,
          title: product.name,
          subtitle: 'SKU: ${product.sku}',
        ),
      );

      if (confirm == true) {
        _update(_viewModel.copyWith(isDeleting: true));

        // Remover todas as imagens do Storage
        if (product.imageUrls.isNotEmpty) {
          await _repository.deleteImages(product.imageUrls);
        }

        final success = await _repository.delete(product.uid);
        _update(_viewModel.copyWith(isDeleting: false));

        if (success) {
          await DSAlertDialog.showSuccess(
            context: context!,
            title: 'Produto Excluído',
            message: '${product.name} foi removido permanentemente.',
          );
          ProductsRepository.productsCache.invalidate();
          await loadProducts(forceRefresh: true);
        }
      }
    }
  }

  // MARK: - Private

  void _update(ProductsListViewModel viewModel) {
    _viewModel = viewModel;
    onViewModelUpdated(viewModel);
  }

  /// Aplica busca, filtros e ordenação sobre allProducts.
  void _applyFiltersAndSort() {
    var products = List<ProductModel>.from(_viewModel.allProducts);

    // 1. Busca
    if (_viewModel.searchQuery.isNotEmpty) {
      final query = _viewModel.searchQuery.toLowerCase();
      products = products.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 2. Filtro de status
    switch (_viewModel.statusFilter) {
      case ProductStatusFilter.active:
        products = products.where((p) => p.isActive).toList();
        break;
      case ProductStatusFilter.inactive:
        products = products.where((p) => !p.isActive).toList();
        break;
      case ProductStatusFilter.all:
        break;
    }

    // 3. Filtro de estoque
    switch (_viewModel.stockFilter) {
      case ProductStockFilter.available:
        products = products.where((p) => p.stock > 0).toList();
        break;
      case ProductStockFilter.outOfStock:
        products = products.where((p) => p.stock == 0).toList();
        break;
      case ProductStockFilter.lowStock:
        products = products.where((p) => p.stock > 0 && p.stock < 10).toList();
        break;
      case ProductStockFilter.all:
        break;
    }

    // 4. Ordenação
    switch (_viewModel.sortOption) {
      case ProductSortOption.newestFirst:
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProductSortOption.oldestFirst:
        products.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ProductSortOption.nameAZ:
        products.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ProductSortOption.nameZA:
        products.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case ProductSortOption.priceLow:
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceHigh:
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.stockLow:
        products.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case ProductSortOption.stockHigh:
        products.sort((a, b) => b.stock.compareTo(a.stock));
        break;
    }

    _update(_viewModel.copyWith(filteredProducts: products));
  }

  /// Dispose do timer.
  void dispose() {
    _debounceTimer?.cancel();
  }
}
