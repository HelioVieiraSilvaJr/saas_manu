import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../ProductsListPresenter.dart';
import '../ProductsListViewModel.dart';
import '../ProductsCoordinator.dart';
import '../Widgets/ProductCard.dart';

/// Lista de Produtos - Layout Mobile (< 1000px).
///
/// Grid 2 colunas, busca, filtros, FAB para novo produto.
class ProductsListMobileView extends StatelessWidget {
  final ProductsListPresenter presenter;
  final ProductsListViewModel viewModel;
  final TextEditingController searchController;

  const ProductsListMobileView({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Stack(
      children: [
        Column(
          children: [
            // Busca e filtros
            _buildSearchAndFilters(colors, textStyles),

            // Contagem e filtros ativos
            if (!viewModel.isLoading) _buildCountBar(colors, textStyles),

            // Content
            Expanded(child: _buildContent(context, colors)),
          ],
        ),

        // FAB
        Positioned(
          right: DSSpacing.lg,
          bottom: DSSpacing.lg,
          child: FloatingActionButton.extended(
            onPressed: () async {
              await ProductsCoordinator.navigateToCreate(context);
              presenter.refresh();
            },
            backgroundColor: colors.primaryColor,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Novo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(DSColors colors, DSTextStyle textStyles) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Column(
        children: [
          // Campo de busca
          TextField(
            controller: searchController,
            onChanged: presenter.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar produtos...',
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
              isDense: true,
            ),
          ),
          const SizedBox(height: DSSpacing.sm),

          // Filtros inline
          Row(
            children: [
              Expanded(
                child: _buildCompactDropdown<ProductStatusFilter>(
                  value: viewModel.statusFilter,
                  items: const {
                    ProductStatusFilter.all: 'Status',
                    ProductStatusFilter.active: 'Ativos',
                    ProductStatusFilter.inactive: 'Inativos',
                  },
                  onChanged: (v) =>
                      presenter.setStatusFilter(v ?? ProductStatusFilter.all),
                  colors: colors,
                ),
              ),
              const SizedBox(width: DSSpacing.xs),
              Expanded(
                child: _buildCompactDropdown<ProductStockFilter>(
                  value: viewModel.stockFilter,
                  items: const {
                    ProductStockFilter.all: 'Estoque',
                    ProductStockFilter.available: 'Disponível',
                    ProductStockFilter.outOfStock: 'Sem Estoque',
                    ProductStockFilter.lowStock: 'Baixo',
                  },
                  onChanged: (v) =>
                      presenter.setStockFilter(v ?? ProductStockFilter.all),
                  colors: colors,
                ),
              ),
              const SizedBox(width: DSSpacing.xs),
              Expanded(
                child: _buildCompactDropdown<ProductSortOption>(
                  value: viewModel.sortOption,
                  items: const {
                    ProductSortOption.newestFirst: 'Recentes',
                    ProductSortOption.oldestFirst: 'Antigos',
                    ProductSortOption.nameAZ: 'A–Z',
                    ProductSortOption.nameZA: 'Z–A',
                    ProductSortOption.priceLow: 'Menor R\$',
                    ProductSortOption.priceHigh: 'Maior R\$',
                    ProductSortOption.stockLow: '↓ Estoque',
                    ProductSortOption.stockHigh: '↑ Estoque',
                  },
                  onChanged: (v) => presenter.setSortOption(
                    v ?? ProductSortOption.newestFirst,
                  ),
                  colors: colors,
                ),
              ),
              if (viewModel.hasActiveFilters) ...[
                const SizedBox(width: DSSpacing.xs),
                GestureDetector(
                  onTap: () {
                    searchController.clear();
                    presenter.clearFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(DSSpacing.xs),
                    decoration: BoxDecoration(
                      color: colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.filter_alt_off_rounded,
                      color: colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    required DSColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xs),
      decoration: BoxDecoration(
        border: Border.all(color: colors.inputBorder),
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        color: colors.inputBackground,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
          style: TextStyle(fontSize: 12, color: colors.textPrimary),
          dropdownColor: colors.cardBackground,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: colors.textTertiary,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildCountBar(DSColors colors, DSTextStyle textStyles) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.md,
        vertical: DSSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '${viewModel.filteredCount} de ${viewModel.totalCount} produto${viewModel.totalCount != 1 ? 's' : ''}',
            style: textStyles.caption.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DSColors colors) {
    if (viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando produtos...');
    }

    // Nenhum produto
    if (viewModel.allProducts.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Nenhum produto cadastrado',
        message: 'Toque no botão + para adicionar.',
      );
    }

    // Filtros sem resultado
    if (viewModel.filteredProducts.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Nenhum produto encontrado',
        message: viewModel.hasSearch
            ? 'Sem resultados para "${viewModel.searchQuery}".'
            : 'Altere os filtros aplicados.',
        actionLabel: 'Limpar Filtros',
        onAction: () {
          searchController.clear();
          presenter.clearFilters();
        },
      );
    }

    // Grid de produtos - 2 colunas
    return RefreshIndicator(
      onRefresh: presenter.refresh,
      color: colors.primaryColor,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(DSSpacing.md, 0, DSSpacing.md, 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: DSSpacing.sm,
          mainAxisSpacing: DSSpacing.sm,
          childAspectRatio: 0.58,
        ),
        itemCount: viewModel.filteredProducts.length,
        itemBuilder: (context, index) {
          final product = viewModel.filteredProducts[index];
          return ProductCard(
            product: product,
            isWeb: false,
            onTap: () async {
              await ProductsCoordinator.navigateToDetail(context, product);
              presenter.refresh();
            },
          );
        },
      ),
    );
  }
}
