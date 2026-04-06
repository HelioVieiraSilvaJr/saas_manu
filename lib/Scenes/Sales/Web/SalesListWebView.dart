import 'package:flutter/material.dart';
import '../../../Commons/Enums/OrderStatus.dart';
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

String _salesFormatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}

class SalesListWebView extends StatelessWidget {
  final SalesListPresenter presenter;
  final TextEditingController searchController;
  final VoidCallback onNewSale;
  final void Function(String saleId) onViewDetails;
  final void Function(String saleId) onDeleteSale;
  final void Function(String saleId) onSendPaymentRequest;
  final void Function(String saleId) onConfirmPayment;
  final void Function(String saleId) onCancelSale;

  const SalesListWebView({
    super.key,
    required this.presenter,
    required this.searchController,
    required this.onNewSale,
    required this.onViewDetails,
    required this.onDeleteSale,
    required this.onSendPaymentRequest,
    required this.onConfirmPayment,
    required this.onCancelSale,
  });

  static const List<String> _monthNames = [
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  String _formatMonthYear(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDayMonth(DateTime date) {
    return '${date.day} de ${_monthNames[date.month - 1]}';
  }

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
          _buildHeader(vm, colors, textStyles),
          const SizedBox(height: DSSpacing.lg),
          _buildMetricCards(vm),
          const SizedBox(height: DSSpacing.lg),
          _buildFiltersBar(vm, colors, textStyles),
          const SizedBox(height: DSSpacing.base),
          _buildDayNavigator(vm, colors, textStyles),
          const SizedBox(height: DSSpacing.lg),
          _buildContent(vm, colors, textStyles),
        ],
      ),
    );
  }

  Widget _buildHeader(
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
                'Hoje permanece visivel e os dias anteriores ficam organizados para acompanhamento e fechamento.',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        DSButton.primary(
          label: 'Nova Venda',
          icon: Icons.add_shopping_cart_rounded,
          onTap: onNewSale,
        ),
      ],
    );
  }

  Widget _buildMetricCards(SalesListViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: DSMetricCard(
            title: 'Hoje',
            value: vm.todayTotal.formatToBRL(),
            comparison: '${vm.todayCount} vendas',
            trend: vm.todayCount > 0 ? TrendType.up : TrendType.neutral,
            icon: Icons.today_rounded,
            compact: true,
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
            compact: true,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Ticket Médio',
            value: vm.averageTicket.formatToBRL(),
            comparison: 'por venda',
            icon: Icons.receipt_long_rounded,
            compact: true,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Exibidas',
            value: '${vm.filteredCount}',
            comparison: '${vm.totalCount} carregadas',
            icon: Icons.point_of_sale_rounded,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersBar(
    SalesListViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    final selectedMonth = DateTime(
      vm.selectedDayOrToday.year,
      vm.selectedDayOrToday.month,
    );

    return Wrap(
      spacing: DSSpacing.sm,
      runSpacing: DSSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildFilterDropdown<SaleStatusFilter>(
          value: vm.statusFilter,
          items: const {
            SaleStatusFilter.all: 'Todos os status',
            SaleStatusFilter.pending: 'Pendentes',
            SaleStatusFilter.paymentSent: 'Cobrança Enviada',
            SaleStatusFilter.confirmed: 'Pagas',
            SaleStatusFilter.cancelled: 'Canceladas',
          },
          onChanged: (value) =>
              presenter.setStatusFilter(value ?? SaleStatusFilter.all),
          colors: colors,
          textStyles: textStyles,
        ),
        _buildFilterDropdown<SaleSourceFilter>(
          value: vm.sourceFilter,
          items: const {
            SaleSourceFilter.all: 'Todas as origens',
            SaleSourceFilter.manual: 'Manual',
            SaleSourceFilter.whatsappAutomation: 'WhatsApp Bot',
          },
          onChanged: (value) =>
              presenter.setSourceFilter(value ?? SaleSourceFilter.all),
          colors: colors,
          textStyles: textStyles,
        ),
        _buildFilterDropdown<SaleSortOption>(
          value: vm.sortOption,
          items: const {
            SaleSortOption.newestFirst: 'Mais recentes',
            SaleSortOption.oldestFirst: 'Mais antigas',
            SaleSortOption.totalHighest: 'Valor maior',
            SaleSortOption.totalLowest: 'Valor menor',
            SaleSortOption.customerAZ: 'Cliente A-Z',
            SaleSortOption.customerZA: 'Cliente Z-A',
          },
          onChanged: (value) =>
              presenter.setSortOption(value ?? SaleSortOption.newestFirst),
          colors: colors,
          textStyles: textStyles,
          icon: Icons.sort_rounded,
        ),
        _buildFilterDropdown<DateTime>(
          value: selectedMonth,
          items: {
            for (final month in vm.availableMonths)
              month: _formatMonthYear(month),
          },
          onChanged: (value) {
            if (value != null) presenter.setSelectedMonth(value);
          },
          colors: colors,
          textStyles: textStyles,
          icon: Icons.calendar_today_rounded,
        ),
        if (vm.hasActiveFilters || vm.hasSearch)
          _buildClearFiltersButton(colors, textStyles),
        SizedBox(
          width: 300,
          child: TextField(
            controller: searchController,
            onChanged: presenter.search,
            style: textStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Buscar venda...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: vm.hasSearch
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                        presenter.search('');
                      },
                      icon: const Icon(Icons.close_rounded),
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
                (entry) => DropdownMenuItem<T>(
                  value: entry.key,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: colors.textSecondary),
                        const SizedBox(width: DSSpacing.xs),
                      ],
                      Text(entry.value),
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

  Widget _buildClearFiltersButton(DSColors colors, DSTextStyle textStyles) {
    return InkWell(
      onTap: () {
        searchController.clear();
        presenter.clearFilters();
      },
      borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
        decoration: BoxDecoration(
          color: colors.redLight,
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          border: Border.all(color: colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_off_rounded, size: 16, color: colors.red),
            const SizedBox(width: DSSpacing.xs),
            Text(
              'Limpar',
              style: textStyles.bodySmall.copyWith(color: colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayNavigator(
    SalesListViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          DSButton.ghost(
            label: 'Hoje',
            icon: Icons.today_rounded,
            onTap: vm.isSelectedDayToday ? null : presenter.goToToday,
          ),
          const SizedBox(width: DSSpacing.sm),
          _NavigatorIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: presenter.goToPreviousDay,
          ),
          const SizedBox(width: DSSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dia selecionado', style: textStyles.caption),
                const SizedBox(height: DSSpacing.xxs),
                Text(
                  _formatSelectedDay(vm.selectedDayOrToday),
                  style: textStyles.labelLarge,
                ),
              ],
            ),
          ),
          const SizedBox(width: DSSpacing.sm),
          _NavigatorIconButton(
            icon: Icons.chevron_right_rounded,
            onTap: vm.isSelectedDayToday ? null : presenter.goToNextDay,
          ),
        ],
      ),
    );
  }

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
            : 'Ajuste os filtros aplicados para localizar as vendas.',
        actionLabel: 'Limpar filtros',
        onAction: () {
          searchController.clear();
          presenter.clearFilters();
        },
      );
    }

    return Column(
      children: [
        _buildDaySection(
          title: 'Hoje',
          subtitle: 'Vendas do dia atual sempre visiveis',
          openSales: vm.todayOpenSales,
          closedSales: vm.todayClosedSales,
          colors: colors,
          textStyles: textStyles,
        ),
        if (!vm.isSelectedDayToday) ...[
          const SizedBox(height: DSSpacing.lg),
          _buildDaySection(
            title: _formatSelectedDay(vm.selectedDayOrToday),
            subtitle: 'Historico do dia selecionado',
            openSales: vm.selectedDayOpenSales,
            closedSales: vm.selectedDayClosedSales,
            colors: colors,
            textStyles: textStyles,
          ),
        ],
      ],
    );
  }

  Widget _buildDaySection({
    required String title,
    required String subtitle,
    required List<SaleModel> openSales,
    required List<SaleModel> closedSales,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textStyles.headline3),
        const SizedBox(height: DSSpacing.xxs),
        Text(
          subtitle,
          style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: DSSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final useRow = constraints.maxWidth >= 1200;
            final openCard = _buildSalesGroupCard(
              title: 'Em aberto',
              count: openSales.length,
              sales: openSales,
              emptyMessage: 'Nenhuma venda em aberto neste dia.',
              colors: colors,
              textStyles: textStyles,
            );
            final closedCard = _buildSalesGroupCard(
              title: 'Finalizadas',
              count: closedSales.length,
              sales: closedSales,
              emptyMessage: 'Nenhuma venda finalizada neste dia.',
              colors: colors,
              textStyles: textStyles,
            );

            if (useRow) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: openCard),
                  const SizedBox(width: DSSpacing.base),
                  Expanded(child: closedCard),
                ],
              );
            }

            return Column(
              children: [
                openCard,
                const SizedBox(height: DSSpacing.base),
                closedCard,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSalesGroupCard({
    required String title,
    required int count,
    required List<SaleModel> sales,
    required String emptyMessage,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DSSpacing.lg,
              DSSpacing.lg,
              DSSpacing.lg,
              DSSpacing.base,
            ),
            child: Row(
              children: [
                Text(title, style: textStyles.labelLarge),
                const SizedBox(width: DSSpacing.xs),
                DSBadge(
                  label: '$count',
                  type: title == 'Em aberto'
                      ? DSBadgeType.warning
                      : DSBadgeType.success,
                  size: DSBadgeSize.small,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          if (sales.isEmpty)
            Padding(
              padding: const EdgeInsets.all(DSSpacing.lg),
              child: Text(
                emptyMessage,
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            )
          else ...[
            _buildTableHeader(colors, textStyles),
            ...sales.map((sale) {
              final isLast = sale == sales.last;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SaleTableRow(
                    sale: sale,
                    colors: colors,
                    textStyles: textStyles,
                    onTap: () => onViewDetails(sale.uid),
                    onDelete: () => onDeleteSale(sale.uid),
                    onSendPaymentRequest: () => onSendPaymentRequest(sale.uid),
                    onConfirmPayment: () => onConfirmPayment(sale.uid),
                    onCancelSale: () => onCancelSale(sale.uid),
                  ),
                  if (!isLast) Divider(height: 1, color: colors.divider),
                ],
              );
            }),
          ],
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
          Expanded(flex: 3, child: Text('Ações', style: headerStyle)),
        ],
      ),
    );
  }

  String _formatSelectedDay(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (normalizedDate == normalizedToday) return 'Hoje';
    return _formatDayMonth(date);
  }
}

class _NavigatorIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavigatorIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          color: onTap == null
              ? colors.scaffoldBackground
              : colors.cardBackground,
        ),
        child: Icon(icon, color: onTap == null ? colors.textTertiary : null),
      ),
    );
  }
}

class _SaleTableRow extends StatefulWidget {
  final SaleModel sale;
  final DSColors colors;
  final DSTextStyle textStyles;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSendPaymentRequest;
  final VoidCallback? onConfirmPayment;
  final VoidCallback? onCancelSale;

  const _SaleTableRow({
    required this.sale,
    required this.colors,
    required this.textStyles,
    this.onTap,
    this.onDelete,
    this.onSendPaymentRequest,
    this.onConfirmPayment,
    this.onCancelSale,
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
                      _salesFormatDateTime(sale.createdAt),
                      style: textStyles.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
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
                    const SizedBox(height: DSSpacing.xxs),
                    Text(
                      '${sale.itemsCount} ${sale.itemsCount == 1 ? 'item' : 'itens'}',
                      style: textStyles.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  sale.total.formatToBRL(),
                  style: textStyles.labelLarge,
                ),
              ),
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
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: DSSpacing.xs,
                  runSpacing: DSSpacing.xs,
                  children: [
                    if (sale.canSendPaymentRequest)
                      _QuickActionButton(
                        label: 'Cobrar',
                        icon: Icons.send_rounded,
                        color: colors.blue,
                        bgColor: colors.blueLight,
                        onTap: widget.onSendPaymentRequest,
                      ),
                    if (sale.canConfirmPayment)
                      _QuickActionButton(
                        label: 'Pago',
                        icon: Icons.check_circle_rounded,
                        color: colors.green,
                        bgColor: colors.greenLight,
                        onTap: widget.onConfirmPayment,
                      ),
                    if (sale.canCancel && !sale.isConfirmed)
                      _QuickActionButton(
                        label: 'Cancelar',
                        icon: Icons.cancel_rounded,
                        color: colors.red,
                        bgColor: colors.redLight,
                        onTap: widget.onCancelSale,
                      ),
                    if (sale.isConfirmed && sale.orderStatus != null)
                      DSBadge(
                        label: sale.orderStatus!.label,
                        type: _orderStatusBadgeType(sale.orderStatus!),
                        size: DSBadgeSize.small,
                      ),
                    if (sale.isCancelled)
                      Text(
                        'Sem pendencias',
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textTertiary,
                        ),
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
      case SaleStatus.payment_sent:
        return DSBadgeType.info;
      case SaleStatus.cancelled:
        return DSBadgeType.error;
    }
  }

  DSBadgeType _orderStatusBadgeType(OrderStatus status) {
    switch (status) {
      case OrderStatus.awaiting_processing:
        return DSBadgeType.warning;
      case OrderStatus.preparing:
        return DSBadgeType.info;
      case OrderStatus.packing:
        return DSBadgeType.info;
      case OrderStatus.awaiting_pickup:
        return DSBadgeType.primary;
      case OrderStatus.ready_for_shipping:
        return DSBadgeType.primary;
      case OrderStatus.shipped:
        return DSBadgeType.primary;
      case OrderStatus.completed:
        return DSBadgeType.success;
    }
  }
}

class _QuickActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.sm,
            vertical: DSSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : widget.bgColor,
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            border: Border.all(
              color: _hovered
                  ? widget.color
                  : widget.color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: widget.color),
              const SizedBox(width: DSSpacing.xxs),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
