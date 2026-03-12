import 'package:flutter/material.dart';
import '../../../Commons/Models/ProductModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
import '../../../Commons/Widgets/DesignSystem/AppNetworkImage.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../ProductsListPresenter.dart';
import '../ProductsListViewModel.dart';
import '../ProductsCoordinator.dart';

/// Lista de Produtos - Layout Web (>= 1000px).
///
/// Catálogo moderno com metric cards, filtros e tabela de dados.
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.pagePaddingHorizontalWeb,
        vertical: DSSpacing.pagePaddingVerticalWeb,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildMetricCards(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildFiltersBar(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildContent(context, colors, textStyles),
        ],
      ),
    );
  }

  // ──────────────────── Header ────────────────────

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
              Text('Catálogo de Produtos', style: textStyles.headline1),
              const SizedBox(height: DSSpacing.xs),
              Text(
                'Gerencie todos os produtos e suas variações',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
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

  // ──────────────────── Metric Cards ────────────────────

  Widget _buildMetricCards(DSColors colors, DSTextStyle textStyles) {
    return Row(
      children: [
        Expanded(
          child: DSMetricCard(
            title: 'Total de Produtos',
            value: '${viewModel.totalCount}',
            comparison: viewModel.totalCount > 0
                ? '${viewModel.activeCount} ativos'
                : null,
            trend: viewModel.totalCount > 0 ? TrendType.up : TrendType.neutral,
            icon: Icons.inventory_2_rounded,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Produtos Ativos',
            value: '${viewModel.activeCount}',
            comparison: '${viewModel.activePercent}%',
            trend: viewModel.activePercent >= 80
                ? TrendType.up
                : TrendType.neutral,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Estoque Total',
            value: '${viewModel.totalStock}',
            comparison: 'unidades em estoque',
            icon: Icons.warehouse_rounded,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Estoque Baixo',
            value: '${viewModel.lowStockCount}',
            comparison: viewModel.lowStockCount > 0 ? 'repor' : 'ok',
            trend: viewModel.lowStockCount > 0 ? TrendType.down : TrendType.up,
            icon: Icons.warning_amber_rounded,
          ),
        ),
      ],
    );
  }

  // ──────────────────── Filters Bar ────────────────────

  Widget _buildFiltersBar(DSColors colors, DSTextStyle textStyles) {
    return Row(
      children: [
        // Status dropdown
        _buildFilterDropdown<ProductStatusFilter>(
          value: viewModel.statusFilter,
          items: const {
            ProductStatusFilter.all: 'Todos os status',
            ProductStatusFilter.active: 'Ativos',
            ProductStatusFilter.inactive: 'Inativos',
          },
          onChanged: (v) =>
              presenter.setStatusFilter(v ?? ProductStatusFilter.all),
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Estoque dropdown
        _buildFilterDropdown<ProductStockFilter>(
          value: viewModel.stockFilter,
          items: const {
            ProductStockFilter.all: 'Todo estoque',
            ProductStockFilter.available: 'Disponível',
            ProductStockFilter.outOfStock: 'Sem Estoque',
            ProductStockFilter.lowStock: 'Estoque Baixo',
          },
          onChanged: (v) =>
              presenter.setStockFilter(v ?? ProductStockFilter.all),
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Ordenação dropdown
        _buildFilterDropdown<ProductSortOption>(
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
          textStyles: textStyles,
          icon: Icons.sort_rounded,
        ),

        if (viewModel.hasActiveFilters) ...[
          const SizedBox(width: DSSpacing.sm),
          _buildClearFiltersButton(colors),
        ],

        const Spacer(),

        // Busca
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchController,
            onChanged: presenter.onSearchChanged,
            style: textStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Buscar produto...',
              hintStyle: textStyles.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.textTertiary,
                size: DSSpacing.iconMd,
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
                        size: DSSpacing.iconSm,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: colors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.md,
                vertical: DSSpacing.sm,
              ),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    required DSColors colors,
    required DSTextStyle textStyles,
    IconData? icon,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.inputBorder),
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        color: colors.inputBackground,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: colors.textSecondary),
                        const SizedBox(width: DSSpacing.xs),
                      ],
                      Text(e.value),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          style: textStyles.bodyMedium.copyWith(color: colors.textPrimary),
          dropdownColor: colors.cardBackground,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textTertiary,
            size: DSSpacing.iconMd,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton(DSColors colors) {
    return Tooltip(
      message: 'Limpar filtros',
      child: InkWell(
        onTap: () {
          searchController.clear();
          presenter.clearFilters();
        },
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: colors.redLight,
            borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
            border: Border.all(color: colors.red.withValues(alpha: 0.3)),
          ),
          child: Icon(
            Icons.filter_alt_off_rounded,
            color: colors.red,
            size: DSSpacing.iconMd,
          ),
        ),
      ),
    );
  }

  // ──────────────────── Content ────────────────────

  Widget _buildContent(
    BuildContext context,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    if (viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando produtos...');
    }

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

    return _buildTable(context, colors, textStyles);
  }

  // ──────────────────── Table ────────────────────

  Widget _buildTable(
    BuildContext context,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: DSSpacing.elevationSmBlur,
            offset: const Offset(0, DSSpacing.elevationSmOffset),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DSSpacing.lg,
              DSSpacing.lg,
              DSSpacing.lg,
              DSSpacing.base,
            ),
            child: Text('Todos os Produtos', style: textStyles.headline3),
          ),

          // Divider
          Divider(height: 1, color: colors.divider),

          // Table Header
          _buildTableHeader(colors, textStyles),

          // Table Rows
          ...viewModel.filteredProducts.map((product) {
            final isLast = product == viewModel.filteredProducts.last;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProductTableRow(
                  product: product,
                  colors: colors,
                  textStyles: textStyles,
                  onTap: () async {
                    await ProductsCoordinator.navigateToDetail(
                      context,
                      product,
                    );
                    presenter.refresh();
                  },
                  onEdit: () async {
                    await ProductsCoordinator.navigateToEdit(context, product);
                    presenter.refresh();
                  },
                  onDelete: () => presenter.deleteProduct(product),
                ),
                if (!isLast) Divider(height: 1, color: colors.divider),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(DSColors colors, DSTextStyle textStyles) {
    final headerStyle = textStyles.labelMedium.copyWith(
      color: colors.textTertiary,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.lg,
        vertical: DSSpacing.md,
      ),
      decoration: BoxDecoration(color: colors.scaffoldBackground),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('Produto', style: headerStyle)),
          Expanded(flex: 2, child: Text('SKU', style: headerStyle)),
          Expanded(flex: 2, child: Text('Preço', style: headerStyle)),
          Expanded(flex: 2, child: Text('Estoque', style: headerStyle)),
          Expanded(flex: 2, child: Text('Status', style: headerStyle)),
          const SizedBox(width: 80, child: Text('')),
        ],
      ),
    );
  }
}

/// Linha de produto na tabela — widget separado com hover animado.
class _ProductTableRow extends StatefulWidget {
  final ProductModel product;
  final DSColors colors;
  final DSTextStyle textStyles;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProductTableRow({
    required this.product,
    required this.colors,
    required this.textStyles,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_ProductTableRow> createState() => _ProductTableRowState();
}

class _ProductTableRowState extends State<_ProductTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final textStyles = widget.textStyles;
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.lg,
            vertical: DSSpacing.md,
          ),
          color: _isHovered
              ? colors.primarySurface.withValues(alpha: 0.4)
              : Colors.transparent,
          child: Row(
            children: [
              // Produto (imagem + nome + descrição)
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                        border: Border.all(color: colors.divider),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                        child: AppNetworkImage(
                          url: product.mainImageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          placeholder: Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                            color: colors.textTertiary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DSSpacing.md),

                    // Nome + descrição
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: textStyles.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (product.description != null &&
                              product.description!.isNotEmpty) ...[
                            const SizedBox(height: DSSpacing.xxs),
                            Text(
                              product.description!,
                              style: textStyles.caption.copyWith(
                                color: colors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // SKU
              Expanded(
                flex: 2,
                child: Text(
                  product.sku,
                  style: textStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Preço
              Expanded(
                flex: 2,
                child: Text(
                  product.price.formatToBRL(),
                  style: textStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Estoque
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Text(
                      '${product.stock} un',
                      style: textStyles.bodyMedium.copyWith(
                        color: _stockColor(colors, product.stock),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DSBadge(
                    label: product.isActive ? 'Publicado' : 'Pausado',
                    type: product.isActive
                        ? DSBadgeType.success
                        : DSBadgeType.warning,
                    size: DSBadgeSize.small,
                  ),
                ),
              ),

              // Ações
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionIcon(
                      icon: Icons.edit_outlined,
                      tooltip: 'Editar',
                      color: colors.textSecondary,
                      hoverColor: colors.primaryColor,
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: DSSpacing.xs),
                    _ActionIcon(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Excluir',
                      color: colors.textTertiary,
                      hoverColor: colors.red,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _stockColor(DSColors colors, int stock) {
    if (stock == 0) return colors.red;
    if (stock < 10) return colors.orange;
    return colors.green;
  }
}

/// Ícone de ação com hover animado.
class _ActionIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color hoverColor;
  final VoidCallback? onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.hoverColor,
    this.onTap,
  });

  @override
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(DSSpacing.xs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                widget.icon,
                size: DSSpacing.iconMd,
                color: _hovered ? widget.hoverColor : widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
