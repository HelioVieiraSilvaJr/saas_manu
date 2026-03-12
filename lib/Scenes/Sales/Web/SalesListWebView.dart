import 'package:flutter/material.dart';
import '../../../Commons/Enums/SaleStatus.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/SaleModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../SalesListPresenter.dart';
import '../SalesListViewModel.dart';

/// View Web da listagem de vendas.
///
/// Catálogo moderno com metric cards, filtros e tabela de dados.
class SalesListWebView extends StatelessWidget {
  final SalesListPresenter presenter;
  final TextEditingController searchController;
  final VoidCallback onNewSale;
  final void Function(String saleId) onViewDetails;
  final void Function(String saleId) onDeleteSale;

  const SalesListWebView({
    super.key,
    required this.presenter,
    required this.searchController,
    required this.onNewSale,
    required this.onViewDetails,
    required this.onDeleteSale,
  });

  @override
  Widget build(BuildContext context) {
    final vm = presenter.viewModel;
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
          _buildHeader(context, vm, colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildMetricCards(vm, colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildFiltersBar(vm, colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildContent(vm, colors, textStyles),
        ],
      ),
    );
  }

  // ──────────────────── Header ────────────────────

  Widget _buildHeader(
    BuildContext context,
    SalesListViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vendas', style: textStyles.headline1),
              const SizedBox(height: DSSpacing.xs),
              Text(
                'Gerencie todas as vendas e acompanhe os resultados',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        DSButton.primary(
          label: 'Nova Venda',
          icon: Icons.add_shopping_cart_rounded,
          onTap: onNewSale,
        ),
      ],
    );
  }

  // ──────────────────── Metric Cards ────────────────────

  Widget _buildMetricCards(
    SalesListViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        Expanded(
          child: DSMetricCard(
            title: 'Hoje',
            value: vm.todayTotal.formatToBRL(),
            comparison: '${vm.todayCount} vendas',
            trend: vm.todayCount > 0 ? TrendType.up : TrendType.neutral,
            icon: Icons.today_rounded,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Este Mês',
            value: vm.monthTotal.formatToBRL(),
            comparison: '${vm.monthCount} vendas',
            trend: vm.monthCount > 0 ? TrendType.up : TrendType.neutral,
            icon: Icons.calendar_month_rounded,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Ticket Médio',
            value: vm.averageTicket.formatToBRL(),
            comparison: 'por venda',
            icon: Icons.receipt_long_rounded,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Total de Vendas',
            value: '${vm.totalCount}',
            comparison: '${vm.filteredCount} exibidas',
            icon: Icons.point_of_sale_rounded,
          ),
        ),
      ],
    );
  }

  // ──────────────────── Filters Bar ────────────────────

  Widget _buildFiltersBar(
    SalesListViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        // Status dropdown
        _buildFilterDropdown<SaleStatusFilter>(
          value: vm.statusFilter,
          items: const {
            SaleStatusFilter.all: 'Todos os status',
            SaleStatusFilter.pending: 'Pendente',
            SaleStatusFilter.confirmed: 'Confirmada',
            SaleStatusFilter.cancelled: 'Cancelada',
          },
          onChanged: (v) =>
              presenter.setStatusFilter(v ?? SaleStatusFilter.all),
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Origem dropdown
        _buildFilterDropdown<SaleSourceFilter>(
          value: vm.sourceFilter,
          items: const {
            SaleSourceFilter.all: 'Todas as origens',
            SaleSourceFilter.manual: 'Manual',
            SaleSourceFilter.whatsappAutomation: 'WhatsApp Bot',
          },
          onChanged: (v) =>
              presenter.setSourceFilter(v ?? SaleSourceFilter.all),
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Período dropdown
        _buildFilterDropdown<SalePeriodFilter>(
          value: vm.periodFilter,
          items: const {
            SalePeriodFilter.all: 'Todos os períodos',
            SalePeriodFilter.today: 'Hoje',
            SalePeriodFilter.last7Days: 'Últimos 7 dias',
            SalePeriodFilter.last30Days: 'Últimos 30 dias',
            SalePeriodFilter.thisMonth: 'Este mês',
          },
          onChanged: (v) =>
              presenter.setPeriodFilter(v ?? SalePeriodFilter.all),
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Ordenação dropdown
        _buildFilterDropdown<SaleSortOption>(
          value: vm.sortOption,
          items: const {
            SaleSortOption.newestFirst: 'Mais Recentes',
            SaleSortOption.oldestFirst: 'Mais Antigas',
            SaleSortOption.totalHighest: 'Valor (maior)',
            SaleSortOption.totalLowest: 'Valor (menor)',
            SaleSortOption.customerAZ: 'Cliente (A-Z)',
            SaleSortOption.customerZA: 'Cliente (Z-A)',
          },
          onChanged: (v) =>
              presenter.setSortOption(v ?? SaleSortOption.newestFirst),
          colors: colors,
          textStyles: textStyles,
          icon: Icons.sort_rounded,
        ),

        if (vm.hasActiveFilters) ...[
          const SizedBox(width: DSSpacing.sm),
          _buildClearFiltersButton(colors),
        ],

        const Spacer(),

        // Busca
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchController,
            onChanged: presenter.search,
            style: textStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Buscar venda...',
              hintStyle: textStyles.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.textTertiary,
                size: DSSpacing.iconMd,
              ),
              suffixIcon: vm.hasSearch
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                        presenter.search('');
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
    SalesListViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    if (vm.isLoading) {
      return const LoadingIndicator(message: 'Carregando vendas...');
    }

    if (vm.allSales.isEmpty) {
      return EmptyState(
        icon: Icons.point_of_sale_rounded,
        title: 'Nenhuma venda registrada',
        message: 'Crie sua primeira venda para começar.',
        actionLabel: 'Nova Venda',
        onAction: onNewSale,
      );
    }

    if (vm.filteredSales.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Nenhuma venda encontrada',
        message: vm.hasSearch
            ? 'Nenhum resultado para "${vm.searchQuery}".'
            : 'Tente alterar os filtros aplicados.',
        actionLabel: 'Limpar Filtros',
        onAction: () {
          searchController.clear();
          presenter.clearFilters();
        },
      );
    }

    return _buildTable(vm, colors, textStyles);
  }

  // ──────────────────── Table ────────────────────

  Widget _buildTable(
    SalesListViewModel vm,
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
            child: Text('Todas as Vendas', style: textStyles.headline3),
          ),

          // Divider
          Divider(height: 1, color: colors.divider),

          // Table Header
          _buildTableHeader(colors, textStyles),

          // Table Rows
          ...vm.filteredSales.map((sale) {
            final isLast = sale == vm.filteredSales.last;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SaleTableRow(
                  sale: sale,
                  colors: colors,
                  textStyles: textStyles,
                  onTap: () => onViewDetails(sale.uid),
                  onDelete: () => onDeleteSale(sale.uid),
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
          Expanded(flex: 3, child: Text('Venda', style: headerStyle)),
          Expanded(flex: 3, child: Text('Cliente', style: headerStyle)),
          Expanded(flex: 2, child: Text('Valor', style: headerStyle)),
          Expanded(flex: 2, child: Text('Status', style: headerStyle)),
          Expanded(flex: 2, child: Text('Origem', style: headerStyle)),
          const SizedBox(width: 50, child: Text('')),
        ],
      ),
    );
  }
}

/// Linha de venda na tabela — widget separado com hover animado.
class _SaleTableRow extends StatefulWidget {
  final SaleModel sale;
  final DSColors colors;
  final DSTextStyle textStyles;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _SaleTableRow({
    required this.sale,
    required this.colors,
    required this.textStyles,
    this.onTap,
    this.onDelete,
  });

  @override
  State<_SaleTableRow> createState() => _SaleTableRowState();
}

class _SaleTableRowState extends State<_SaleTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final textStyles = widget.textStyles;
    final sale = widget.sale;

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
              // Venda (número + data)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${sale.number}',
                      style: textStyles.labelLarge.copyWith(
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DSSpacing.xxs),
                    Text(
                      _formatDate(sale.createdAt),
                      style: textStyles.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Cliente
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.customerName,
                      style: textStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sale.items.isNotEmpty) ...[
                      const SizedBox(height: DSSpacing.xxs),
                      Text(
                        '${sale.itemsCount} ${sale.itemsCount == 1 ? 'item' : 'itens'}',
                        style: textStyles.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Valor
              Expanded(
                flex: 2,
                child: Text(
                  sale.total.formatToBRL(),
                  style: textStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Status
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DSBadge(
                    label: sale.status.label,
                    type: _statusBadgeType(sale.status),
                    size: DSBadgeSize.small,
                  ),
                ),
              ),

              // Origem
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DSBadge(
                    label: sale.source.label,
                    type: sale.isAutomated
                        ? DSBadgeType.info
                        : DSBadgeType.neutral,
                    size: DSBadgeSize.small,
                  ),
                ),
              ),

              // Ações
              SizedBox(
                width: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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

  DSBadgeType _statusBadgeType(SaleStatus status) {
    switch (status) {
      case SaleStatus.confirmed:
        return DSBadgeType.success;
      case SaleStatus.pending:
        return DSBadgeType.warning;
      case SaleStatus.cancelled:
        return DSBadgeType.error;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
