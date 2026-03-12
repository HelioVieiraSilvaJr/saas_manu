import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/CustomerModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../CustomersListPresenter.dart';
import '../CustomersListViewModel.dart';
import '../CustomersCoordinator.dart';

/// Lista de Clientes - Layout Web (>= 1000px).
///
/// Catálogo moderno com metric cards, filtros e tabela de dados.
class CustomersListWebView extends StatelessWidget {
  final CustomersListPresenter presenter;
  final CustomersListViewModel viewModel;
  final TextEditingController searchController;

  const CustomersListWebView({
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
              Text('Clientes', style: textStyles.headline1),
              const SizedBox(height: DSSpacing.xs),
              Text(
                'Gerencie todos os clientes e seus dados',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        DSButton.primary(
          label: 'Novo Cliente',
          icon: Icons.person_add_rounded,
          onTap: () => CustomersCoordinator.navigateToCreate(context),
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
            title: 'Total de Clientes',
            value: '${viewModel.totalCount}',
            comparison: viewModel.totalCount > 0
                ? '${viewModel.activeCount} com compras'
                : null,
            trend: viewModel.totalCount > 0 ? TrendType.up : TrendType.neutral,
            icon: Icons.people_rounded,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Clientes Ativos',
            value: '${viewModel.activeCount}',
            comparison: viewModel.totalCount > 0
                ? '${(viewModel.activeCount * 100 / viewModel.totalCount).round()}%'
                : null,
            trend: viewModel.activeCount > 0 ? TrendType.up : TrendType.neutral,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Total Faturado',
            value: viewModel.totalSpentAll.formatToBRL(),
            comparison: 'de todos os clientes',
            icon: Icons.attach_money_rounded,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Novos (30 dias)',
            value: '${viewModel.recentCount}',
            comparison: viewModel.recentCount > 0
                ? 'nos últimos 30 dias'
                : 'nenhum recente',
            trend: viewModel.recentCount > 0 ? TrendType.up : TrendType.neutral,
            icon: Icons.person_add_alt_1_rounded,
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
        _buildFilterDropdown<CustomerStatusFilter>(
          value: viewModel.statusFilter,
          items: const {
            CustomerStatusFilter.all: 'Todos os status',
            CustomerStatusFilter.active: 'Ativos (compraram)',
            CustomerStatusFilter.inactive: 'Inativos',
          },
          onChanged: (v) =>
              presenter.setStatusFilter(v ?? CustomerStatusFilter.all),
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Período dropdown
        _buildFilterDropdown<CustomerPurchasePeriod>(
          value: viewModel.purchasePeriod,
          items: const {
            CustomerPurchasePeriod.all: 'Todos os períodos',
            CustomerPurchasePeriod.last7Days: 'Últimos 7 dias',
            CustomerPurchasePeriod.last30Days: 'Últimos 30 dias',
            CustomerPurchasePeriod.last90Days: 'Últimos 90 dias',
          },
          onChanged: (v) =>
              presenter.setPurchasePeriod(v ?? CustomerPurchasePeriod.all),
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(width: DSSpacing.sm),

        // Ordenação dropdown
        _buildFilterDropdown<CustomerSortOption>(
          value: viewModel.sortOption,
          items: const {
            CustomerSortOption.newestFirst: 'Mais Recentes',
            CustomerSortOption.oldestFirst: 'Mais Antigos',
            CustomerSortOption.nameAZ: 'Nome A–Z',
            CustomerSortOption.nameZA: 'Nome Z–A',
            CustomerSortOption.lastPurchaseRecent: 'Ult. Compra Recente',
            CustomerSortOption.lastPurchaseOld: 'Ult. Compra Antiga',
            CustomerSortOption.totalSpentHigh: 'Maior Gasto',
            CustomerSortOption.totalSpentLow: 'Menor Gasto',
          },
          onChanged: (v) =>
              presenter.setSortOption(v ?? CustomerSortOption.newestFirst),
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
              hintText: 'Buscar cliente...',
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
      return const LoadingIndicator(message: 'Carregando clientes...');
    }

    if (viewModel.allCustomers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Nenhum cliente cadastrado',
        message: 'Comece adicionando seu primeiro cliente.',
        actionLabel: 'Novo Cliente',
        onAction: () => CustomersCoordinator.navigateToCreate(context),
      );
    }

    if (viewModel.filteredCustomers.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Nenhum cliente encontrado',
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
            child: Text('Todos os Clientes', style: textStyles.headline3),
          ),

          // Divider
          Divider(height: 1, color: colors.divider),

          // Table Header
          _buildTableHeader(colors, textStyles),

          // Table Rows
          ...viewModel.filteredCustomers.map((customer) {
            final isLast = customer == viewModel.filteredCustomers.last;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CustomerTableRow(
                  customer: customer,
                  colors: colors,
                  textStyles: textStyles,
                  onTap: () =>
                      CustomersCoordinator.navigateToEdit(context, customer),
                  onDelete: () => presenter.deleteCustomer(customer),
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
          Expanded(flex: 4, child: Text('Cliente', style: headerStyle)),
          Expanded(flex: 3, child: Text('Email', style: headerStyle)),
          Expanded(flex: 2, child: Text('Última Compra', style: headerStyle)),
          Expanded(flex: 2, child: Text('Total Gasto', style: headerStyle)),
          Expanded(flex: 2, child: Text('Status', style: headerStyle)),
          const SizedBox(width: 50, child: Text('')),
        ],
      ),
    );
  }
}

/// Linha de cliente na tabela — widget separado com hover animado.
class _CustomerTableRow extends StatefulWidget {
  final CustomerModel customer;
  final DSColors colors;
  final DSTextStyle textStyles;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _CustomerTableRow({
    required this.customer,
    required this.colors,
    required this.textStyles,
    this.onTap,
    this.onDelete,
  });

  @override
  State<_CustomerTableRow> createState() => _CustomerTableRowState();
}

class _CustomerTableRowState extends State<_CustomerTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final textStyles = widget.textStyles;
    final customer = widget.customer;

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
              // Cliente (avatar + nome + whatsapp)
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primarySurface,
                        borderRadius: BorderRadius.circular(
                          DSSpacing.radiusFull,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                          style: textStyles.labelLarge.copyWith(
                            color: colors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DSSpacing.md),

                    // Nome + WhatsApp
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: textStyles.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (customer.whatsapp.isNotEmpty) ...[
                            const SizedBox(height: DSSpacing.xxs),
                            Text(
                              _formatWhatsApp(customer.whatsapp),
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

              // Email
              Expanded(
                flex: 3,
                child: Text(
                  customer.email ?? '—',
                  style: textStyles.bodySmall.copyWith(
                    color: customer.email != null
                        ? colors.textSecondary
                        : colors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Última Compra
              Expanded(
                flex: 2,
                child: Text(
                  _formatDate(customer.lastPurchaseAt),
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),

              // Total Gasto
              Expanded(
                flex: 2,
                child: Text(
                  (customer.totalSpent ?? 0).formatToBRL(),
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
                    label: (customer.purchaseCount ?? 0) > 0
                        ? 'Ativo'
                        : 'Inativo',
                    type: (customer.purchaseCount ?? 0) > 0
                        ? DSBadgeType.success
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

  String _formatWhatsApp(String phone) {
    if (phone.length == 11) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
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
