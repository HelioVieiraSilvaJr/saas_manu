import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/SaleModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../SalesListPresenter.dart';
import '../SalesListViewModel.dart';
import '../Widgets/SaleListItem.dart';

class SalesListMobileView extends StatelessWidget {
  final SalesListPresenter presenter;
  final TextEditingController searchController;
  final VoidCallback onNewSale;
  final void Function(String saleId) onViewDetails;
  final void Function(String saleId) onDeleteSale;
  final void Function(String saleId) onSendPaymentRequest;
  final void Function(String saleId) onConfirmPayment;
  final void Function(String saleId) onCancelSale;
  final VoidCallback onRefresh;

  const SalesListMobileView({
    super.key,
    required this.presenter,
    required this.searchController,
    required this.onNewSale,
    required this.onViewDetails,
    required this.onDeleteSale,
    required this.onSendPaymentRequest,
    required this.onConfirmPayment,
    required this.onCancelSale,
    required this.onRefresh,
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

  String _formatMonthYearShort(DateTime date) {
    final month = _monthNames[date.month - 1];
    final shortMonth = month.length > 3 ? month.substring(0, 3) : month;
    return '$shortMonth/${date.year}';
  }

  String _formatSelectedDayLabel(DateTime date, {bool today = false}) {
    if (today) return 'Hoje';
    return '${date.day} de ${_monthNames[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = presenter.viewModel;
    final colors = DSColors();
    final textStyles = DSTextStyle();

    if (vm.isLoading) {
      return const LoadingIndicator(message: 'Carregando vendas...');
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DSSpacing.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniCard(
                              'Hoje',
                              vm.todayTotal.formatToBRL(),
                              '${vm.todayCount} vendas',
                              colors,
                              textStyles,
                            ),
                          ),
                          const SizedBox(width: DSSpacing.sm),
                          Expanded(
                            child: _buildMiniCard(
                              'Mês',
                              vm.monthTotal.formatToBRL(),
                              '${vm.monthCount} vendas',
                              colors,
                              textStyles,
                            ),
                          ),
                          const SizedBox(width: DSSpacing.sm),
                          Expanded(
                            child: _buildMiniCard(
                              'Ticket',
                              vm.averageTicket.formatToBRL(),
                              'médio',
                              colors,
                              textStyles,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DSSpacing.base),
                      TextField(
                        controller: searchController,
                        onChanged: presenter.search,
                        decoration: InputDecoration(
                          hintText: 'Buscar vendas...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DSSpacing.radiusSm,
                            ),
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    presenter.search('');
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCompactDropdown<SaleStatusFilter>(
                              value: vm.statusFilter,
                              items: SaleStatusFilter.values,
                              labelBuilder: (item) => item.label,
                              onChanged: (value) {
                                if (value != null) {
                                  presenter.setStatusFilter(value);
                                }
                              },
                              colors: colors,
                              textStyles: textStyles,
                            ),
                            const SizedBox(width: DSSpacing.xs),
                            _buildCompactDropdown<SaleSourceFilter>(
                              value: vm.sourceFilter,
                              items: SaleSourceFilter.values,
                              labelBuilder: (item) => item.label,
                              onChanged: (value) {
                                if (value != null) {
                                  presenter.setSourceFilter(value);
                                }
                              },
                              colors: colors,
                              textStyles: textStyles,
                            ),
                            const SizedBox(width: DSSpacing.xs),
                            _buildCompactDropdown<DateTime>(
                              value: DateTime(
                                vm.selectedDayOrToday.year,
                                vm.selectedDayOrToday.month,
                              ),
                              items: vm.availableMonths,
                              labelBuilder: (item) =>
                                  _formatMonthYearShort(item),
                              onChanged: (value) {
                                if (value != null) {
                                  presenter.setSelectedMonth(value);
                                }
                              },
                              colors: colors,
                              textStyles: textStyles,
                            ),
                            if (vm.hasActiveFilters || vm.hasSearch) ...[
                              const SizedBox(width: DSSpacing.xs),
                              ActionChip(
                                avatar: Icon(
                                  Icons.filter_alt_off,
                                  size: 16,
                                  color: colors.red,
                                ),
                                label: Text(
                                  'Limpar',
                                  style: textStyles.caption,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  presenter.clearFilters();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: DSSpacing.base),
                      _buildDayNavigator(vm, colors, textStyles),
                      const SizedBox(height: DSSpacing.base),
                    ],
                  ),
                ),
              ),
              if (vm.allSales.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.point_of_sale,
                    title: 'Nenhuma venda registrada',
                    message: 'Crie sua primeira venda para começar.',
                  ),
                )
              else if (vm.filteredSales.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'Nenhuma venda encontrada',
                    message: vm.hasSearch
                        ? 'Tente buscar com outros termos.'
                        : 'Ajuste os filtros.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.base,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSection(
                        title: 'Hoje',
                        openSales: vm.todayOpenSales,
                        closedSales: vm.todayClosedSales,
                        colors: colors,
                        textStyles: textStyles,
                      ),
                      if (!vm.isSelectedDayToday) ...[
                        const SizedBox(height: DSSpacing.base),
                        _buildSection(
                          title: _formatSelectedDayLabel(vm.selectedDayOrToday),
                          openSales: vm.selectedDayOpenSales,
                          closedSales: vm.selectedDayClosedSales,
                          colors: colors,
                          textStyles: textStyles,
                        ),
                      ],
                      const SizedBox(height: 88),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: DSSpacing.base,
          right: DSSpacing.base,
          child: FloatingActionButton.extended(
            heroTag: 'newSale',
            onPressed: onNewSale,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Nova Venda'),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<SaleModel> openSales,
    required List<SaleModel> closedSales,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textStyles.headline3),
        const SizedBox(height: DSSpacing.sm),
        _buildGroupCard(
          title: 'Em aberto',
          sales: openSales,
          badgeType: DSBadgeType.warning,
          emptyMessage: 'Nenhuma venda em aberto neste dia.',
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(height: DSSpacing.sm),
        _buildGroupCard(
          title: 'Finalizadas',
          sales: closedSales,
          badgeType: DSBadgeType.success,
          emptyMessage: 'Nenhuma venda finalizada neste dia.',
          colors: colors,
          textStyles: textStyles,
        ),
      ],
    );
  }

  Widget _buildGroupCard({
    required String title,
    required List<SaleModel> sales,
    required DSBadgeType badgeType,
    required String emptyMessage,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: textStyles.labelLarge),
              const SizedBox(width: DSSpacing.xs),
              DSBadge(
                label: '${sales.length}',
                type: badgeType,
                size: DSBadgeSize.small,
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.sm),
          if (sales.isEmpty)
            Text(
              emptyMessage,
              style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
            )
          else
            ...sales.map(
              (sale) => SaleListItem(
                sale: sale,
                isWeb: false,
                onTap: () => onViewDetails(sale.uid),
                onDelete: () => onDeleteSale(sale.uid),
                onSendPaymentRequest: () => onSendPaymentRequest(sale.uid),
                onConfirmPayment: () => onConfirmPayment(sale.uid),
                onCancelSale: () => onCancelSale(sale.uid),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayNavigator(
    SalesListViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.sm),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          _dayIconButton(
            Icons.chevron_left_rounded,
            presenter.goToPreviousDay,
            colors,
          ),
          const SizedBox(width: DSSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Dia selecionado', style: textStyles.caption),
                const SizedBox(height: DSSpacing.xxs),
                Text(
                  _formatSelectedDayLabel(
                    vm.selectedDayOrToday,
                    today: vm.isSelectedDayToday,
                  ),
                  style: textStyles.labelLarge,
                ),
              ],
            ),
          ),
          const SizedBox(width: DSSpacing.sm),
          _dayIconButton(
            Icons.chevron_right_rounded,
            vm.isSelectedDayToday ? null : presenter.goToNextDay,
            colors,
          ),
          const SizedBox(width: DSSpacing.sm),
          DSButton.ghost(
            label: 'Hoje',
            onTap: vm.isSelectedDayToday ? null : presenter.goToToday,
          ),
        ],
      ),
    );
  }

  Widget _dayIconButton(IconData icon, VoidCallback? onTap, DSColors colors) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        ),
        child: Icon(
          icon,
          color: onTap == null ? colors.textTertiary : colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMiniCard(
    String title,
    String value,
    String subtitle,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.sm),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textStyles.caption),
          const SizedBox(height: DSSpacing.xxs),
          Text(
            value,
            style: textStyles.labelLarge.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(subtitle, style: textStyles.caption),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          style: textStyles.caption.copyWith(color: colors.textPrimary),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
