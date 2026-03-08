import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../SalesListPresenter.dart';
import '../SalesListViewModel.dart';
import '../Widgets/SaleListItem.dart';

/// View Web da listagem de vendas.
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

    if (vm.isLoading) {
      return const LoadingIndicator(message: 'Carregando vendas...');
    }

    return Padding(
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini-Cards Métricas
          Row(
            children: [
              Expanded(
                child: DSMetricCard(
                  title: 'Hoje',
                  value: vm.todayTotal.formatToBRL(),
                  comparison: '${vm.todayCount} vendas',
                  trend: TrendType.neutral,
                  icon: Icons.today,
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: DSMetricCard(
                  title: 'Este Mês',
                  value: vm.monthTotal.formatToBRL(),
                  comparison: '${vm.monthCount} vendas',
                  trend: TrendType.neutral,
                  icon: Icons.calendar_month,
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: DSMetricCard(
                  title: 'Ticket Médio',
                  value: vm.averageTicket.formatToBRL(),
                  icon: Icons.receipt_long,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // Header
          Row(
            children: [
              Text('Vendas (${vm.filteredCount})', style: textStyles.headline2),
              const Spacer(),
              DSButton.primary(
                label: 'Nova Venda',
                icon: Icons.add_shopping_cart,
                onTap: onNewSale,
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.base),

          // Busca e Filtros
          Row(
            children: [
              // Busca
              Expanded(
                flex: 3,
                child: TextField(
                  controller: searchController,
                  onChanged: presenter.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar vendas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
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
              ),
              const SizedBox(width: DSSpacing.sm),

              // Status
              Expanded(
                child: DropdownButtonFormField<SaleStatusFilter>(
                  value: vm.statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.sm,
                      vertical: DSSpacing.sm,
                    ),
                  ),
                  items: SaleStatusFilter.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label, style: textStyles.bodySmall),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) presenter.setStatusFilter(v);
                  },
                ),
              ),
              const SizedBox(width: DSSpacing.sm),

              // Origem
              Expanded(
                child: DropdownButtonFormField<SaleSourceFilter>(
                  value: vm.sourceFilter,
                  decoration: InputDecoration(
                    labelText: 'Origem',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.sm,
                      vertical: DSSpacing.sm,
                    ),
                  ),
                  items: SaleSourceFilter.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label, style: textStyles.bodySmall),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) presenter.setSourceFilter(v);
                  },
                ),
              ),
              const SizedBox(width: DSSpacing.sm),

              // Período
              Expanded(
                child: DropdownButtonFormField<SalePeriodFilter>(
                  value: vm.periodFilter,
                  decoration: InputDecoration(
                    labelText: 'Período',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.sm,
                      vertical: DSSpacing.sm,
                    ),
                  ),
                  items: SalePeriodFilter.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label, style: textStyles.bodySmall),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) presenter.setPeriodFilter(v);
                  },
                ),
              ),
              const SizedBox(width: DSSpacing.sm),

              // Ordenação
              Expanded(
                child: DropdownButtonFormField<SaleSortOption>(
                  value: vm.sortOption,
                  decoration: InputDecoration(
                    labelText: 'Ordenar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.sm,
                      vertical: DSSpacing.sm,
                    ),
                  ),
                  items: SaleSortOption.values
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Text(o.label, style: textStyles.bodySmall),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) presenter.setSortOption(v);
                  },
                ),
              ),

              // Limpar filtros
              if (vm.hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.only(left: DSSpacing.sm),
                  child: IconButton(
                    icon: Icon(Icons.filter_alt_off, color: colors.red),
                    tooltip: 'Limpar filtros',
                    onPressed: () {
                      searchController.clear();
                      presenter.clearFilters();
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: DSSpacing.base),

          // Lista
          Expanded(child: _buildList(vm, colors)),
        ],
      ),
    );
  }

  Widget _buildList(SalesListViewModel vm, DSColors colors) {
    if (vm.allSales.isEmpty) {
      return const EmptyState(
        icon: Icons.point_of_sale,
        title: 'Nenhuma venda registrada',
        message: 'Crie sua primeira venda para começar.',
      );
    }

    if (vm.filteredSales.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: vm.hasSearch
            ? 'Nenhuma venda encontrada'
            : 'Nenhum resultado com esses filtros',
        message: vm.hasSearch
            ? 'Tente buscar com outros termos.'
            : 'Ajuste os filtros para ver resultados.',
      );
    }

    return ListView.builder(
      itemCount: vm.filteredSales.length,
      itemBuilder: (context, index) {
        final sale = vm.filteredSales[index];
        return SaleListItem(
          sale: sale,
          isWeb: true,
          onTap: () => onViewDetails(sale.uid),
          onDelete: () => onDeleteSale(sale.uid),
        );
      },
    );
  }
}
