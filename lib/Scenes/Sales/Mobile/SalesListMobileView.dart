import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';

import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../SalesListPresenter.dart';
import '../SalesListViewModel.dart';
import '../Widgets/SaleListItem.dart';

/// View Mobile da listagem de vendas.
class SalesListMobileView extends StatelessWidget {
  final SalesListPresenter presenter;
  final TextEditingController searchController;
  final VoidCallback onNewSale;
  final void Function(String saleId) onViewDetails;
  final void Function(String saleId) onDeleteSale;
  final VoidCallback onRefresh;

  const SalesListMobileView({
    super.key,
    required this.presenter,
    required this.searchController,
    required this.onNewSale,
    required this.onViewDetails,
    required this.onDeleteSale,
    required this.onRefresh,
  });

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
              // Mini-Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DSSpacing.base),
                  child: Column(
                    children: [
                      // Métricas em row
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

                      // Busca
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: DSSpacing.base,
                            vertical: DSSpacing.sm,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    presenter.search('');
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.sm),

                      // Filtros compactos
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Status
                            _buildCompactDropdown<SaleStatusFilter>(
                              value: vm.statusFilter,
                              items: SaleStatusFilter.values,
                              labelBuilder: (f) => f.label,
                              onChanged: (v) {
                                if (v != null) {
                                  presenter.setStatusFilter(v);
                                }
                              },
                              colors: colors,
                              textStyles: textStyles,
                            ),
                            const SizedBox(width: DSSpacing.xs),
                            // Origem
                            _buildCompactDropdown<SaleSourceFilter>(
                              value: vm.sourceFilter,
                              items: SaleSourceFilter.values,
                              labelBuilder: (f) => f.label,
                              onChanged: (v) {
                                if (v != null) {
                                  presenter.setSourceFilter(v);
                                }
                              },
                              colors: colors,
                              textStyles: textStyles,
                            ),
                            const SizedBox(width: DSSpacing.xs),
                            // Período
                            _buildCompactDropdown<SalePeriodFilter>(
                              value: vm.periodFilter,
                              items: SalePeriodFilter.values,
                              labelBuilder: (f) => f.label,
                              onChanged: (v) {
                                if (v != null) {
                                  presenter.setPeriodFilter(v);
                                }
                              },
                              colors: colors,
                              textStyles: textStyles,
                            ),
                            if (vm.hasActiveFilters) ...[
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
                      const SizedBox(height: DSSpacing.sm),

                      // Contagem
                      Row(
                        children: [
                          Text(
                            '${vm.filteredCount} ${vm.filteredCount == 1 ? 'venda' : 'vendas'}',
                            style: textStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Lista
              vm.allSales.isEmpty
                  ? const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.point_of_sale,
                        title: 'Nenhuma venda registrada',
                        message: 'Crie sua primeira venda para começar.',
                      ),
                    )
                  : vm.filteredSales.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: vm.hasSearch
                            ? 'Nenhuma venda encontrada'
                            : 'Nenhum resultado',
                        message: vm.hasSearch
                            ? 'Tente buscar com outros termos.'
                            : 'Ajuste os filtros.',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.base,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final sale = vm.filteredSales[index];
                          return SaleListItem(
                            sale: sale,
                            isWeb: false,
                            onTap: () => onViewDetails(sale.uid),
                            onDelete: () => onDeleteSale(sale.uid),
                          );
                        }, childCount: vm.filteredSales.length),
                      ),
                    ),

              // Bottom spacing for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),

        // FAB
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
