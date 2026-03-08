import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../ProductsListPresenter.dart';
import '../ProductsListViewModel.dart';
import '../ProductsCoordinator.dart';
import '../Widgets/ProductCard.dart';

/// Lista de Produtos - Layout Web (>= 1000px).
///
/// Grid 4 colunas, barra de busca, filtros dropdown, ordenação,
/// header com contagem e botão "Novo Produto".
class ProductsListWebView extends StatelessWidget {
  final ProductsListPresenter presenter;
  final ProductsListViewModel viewModel;
  final TextEditingController searchController;

  const ProductsListWebView({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Padding(
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, colors, textStyles),
          const SizedBox(height: DSSpacing.lg),

          // Barra de busca e filtros
          _buildSearchAndFilters(colors, textStyles),
          const SizedBox(height: DSSpacing.lg),

          // Content
          Expanded(child: _buildContent(context, colors)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Produtos', style: textStyles.headline1),
              const SizedBox(height: DSSpacing.xxs),
              Text(
                '${viewModel.totalCount} produto${viewModel.totalCount != 1 ? 's' : ''} cadastrado${viewModel.totalCount != 1 ? 's' : ''}',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        DSButton.primary(
          label: 'Novo Produto',
          icon: Icons.add_rounded,
          onTap: () async {
            await ProductsCoordinator.navigateToCreate(context);
            presenter.refresh();
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(DSColors colors, DSTextStyle textStyles) {
    return Row(
      children: [
        // Campo de busca
        Expanded(
          flex: 3,
          child: TextField(
            controller: searchController,
            onChanged: presenter.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, SKU ou descrição...',
              hintStyle: textStyles.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.textTertiary,
              ),
              suffixIcon: viewModel.hasSearch
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                        presenter.clearSearch();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textTertiary,
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                borderSide: BorderSide(color: colors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                borderSide: BorderSide(color: colors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                borderSide: BorderSide(color: colors.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: colors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.md,
                vertical: DSSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(width: DSSpacing.md),

        // Filtro Status
        _buildDropdown<ProductStatusFilter>(
          value: viewModel.statusFilter,
          items: const {
            ProductStatusFilter.all: 'Todos Status',
            ProductStatusFilter.active: 'Ativos',
            ProductStatusFilter.inactive: 'Inativos',
          },
          onChanged: (v) =>
              presenter.setStatusFilter(v ?? ProductStatusFilter.all),
          colors: colors,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Filtro Estoque
        _buildDropdown<ProductStockFilter>(
          value: viewModel.stockFilter,
          items: const {
            ProductStockFilter.all: 'Estoque',
            ProductStockFilter.available: 'Disponível',
            ProductStockFilter.outOfStock: 'Sem Estoque',
            ProductStockFilter.lowStock: 'Estoque Baixo',
          },
          onChanged: (v) =>
              presenter.setStockFilter(v ?? ProductStockFilter.all),
          colors: colors,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Ordenação
        _buildDropdown<ProductSortOption>(
          value: viewModel.sortOption,
          items: const {
            ProductSortOption.newestFirst: 'Mais Recentes',
            ProductSortOption.oldestFirst: 'Mais Antigos',
            ProductSortOption.nameAZ: 'Nome A–Z',
            ProductSortOption.nameZA: 'Nome Z–A',
            ProductSortOption.priceLow: 'Menor Preço',
            ProductSortOption.priceHigh: 'Maior Preço',
            ProductSortOption.stockLow: 'Menor Estoque',
            ProductSortOption.stockHigh: 'Maior Estoque',
          },
          onChanged: (v) =>
              presenter.setSortOption(v ?? ProductSortOption.newestFirst),
          colors: colors,
        ),

        // Limpar filtros
        if (viewModel.hasActiveFilters) ...[
          const SizedBox(width: DSSpacing.sm),
          Tooltip(
            message: 'Limpar filtros',
            child: InkWell(
              onTap: () {
                searchController.clear();
                presenter.clearFilters();
              },
              borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.all(DSSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.filter_alt_off_rounded,
                  color: colors.red,
                  size: DSSpacing.iconMd,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    required DSColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: colors.inputBorder),
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        color: colors.inputBackground,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
          dropdownColor: colors.cardBackground,
          icon: Icon(Icons.arrow_drop_down, color: colors.textTertiary),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DSColors colors) {
    if (viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando produtos...');
    }

    // Nenhum produto cadastrado
    if (viewModel.allProducts.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Nenhum produto cadastrado',
        message: 'Comece adicionando seu primeiro produto.',
        actionLabel: 'Novo Produto',
        onAction: () async {
          await ProductsCoordinator.navigateToCreate(context);
          presenter.refresh();
        },
      );
    }

    // Filtros sem resultado
    if (viewModel.filteredProducts.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Nenhum produto encontrado',
        message: viewModel.hasSearch
            ? 'Nenhum resultado para "${viewModel.searchQuery}".'
            : 'Tente alterar os filtros aplicados.',
        actionLabel: 'Limpar Filtros',
        onAction: () {
          searchController.clear();
          presenter.clearFilters();
        },
      );
    }

    // Grid de produtos - 4 colunas
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: DSSpacing.md,
        mainAxisSpacing: DSSpacing.md,
        childAspectRatio: 0.65,
      ),
      itemCount: viewModel.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = viewModel.filteredProducts[index];
        return ProductCard(
          product: product,
          isWeb: true,
          onTap: () async {
            await ProductsCoordinator.navigateToDetail(context, product);
            presenter.refresh();
          },
          onEdit: () async {
            await ProductsCoordinator.navigateToEdit(context, product);
            presenter.refresh();
          },
          onDelete: () => presenter.deleteProduct(product),
        );
      },
    );
  }
}
