import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../StockAlertsPresenter.dart';
import '../StockAlertsViewModel.dart';
import '../Widgets/StockAlertCard.dart';

/// View Mobile da listagem de avisos de estoque.
class StockAlertsMobileView extends StatelessWidget {
  final StockAlertsPresenter presenter;
  final TextEditingController searchController;
  final void Function(String productId) onDismiss;
  final void Function(String productId) onNotify;
  final void Function(StockAlertTab tab) onTabChange;
  final VoidCallback onClearProductFilter;

  const StockAlertsMobileView({
    super.key,
    required this.presenter,
    required this.searchController,
    required this.onDismiss,
    required this.onNotify,
    required this.onTabChange,
    required this.onClearProductFilter,
  });

  @override
  Widget build(BuildContext context) {
    final vm = presenter.viewModel;
    final colors = DSColors();
    final textStyles = DSTextStyle();

    if (vm.isLoading) {
      return const LoadingIndicator(message: 'Carregando avisos de estoque...');
    }

    return RefreshIndicator(
      onRefresh: () async => presenter.startWatchingPending(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(DSSpacing.base),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniCard(
                          'Produtos',
                          vm.pendingCount.toString(),
                          vm.pendingCount > 0 ? colors.orange : colors.green,
                          colors,
                          textStyles,
                        ),
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      Expanded(
                        child: _buildMiniCard(
                          'Clientes',
                          vm.uniqueCustomersCount.toString(),
                          colors.secundaryColor,
                          colors,
                          textStyles,
                        ),
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      Expanded(
                        child: _buildMiniCard(
                          'Pedidos',
                          vm.pendingRequestsCount.toString(),
                          colors.primaryColor,
                          colors,
                          textStyles,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.base),
                  if (vm.productRanking.isNotEmpty) ...[
                    _buildCompactRanking(vm, colors, textStyles),
                    const SizedBox(height: DSSpacing.base),
                  ],
                  TextField(
                    controller: searchController,
                    onChanged: presenter.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar por cliente ou produto...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.base,
                        vertical: DSSpacing.sm,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                searchController.clear();
                                presenter.search('');
                              },
                            )
                          : null,
                    ),
                  ),
                  if (vm.hasScopedProductFilter) ...[
                    const SizedBox(height: DSSpacing.sm),
                    _buildProductScope(vm, colors, textStyles),
                  ],
                  const SizedBox(height: DSSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: StockAlertTab.values.map((tab) {
                        final isSelected = vm.currentTab == tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: DSSpacing.xs),
                          child: ChoiceChip(
                            label: Text(tab.label),
                            selected: isSelected,
                            onSelected: (_) => onTabChange(tab),
                            selectedColor: colors.primarySurface,
                            labelStyle: textStyles.bodySmall.copyWith(
                              color: isSelected
                                  ? colors.primaryColor
                                  : colors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (vm.currentTab == StockAlertTab.pending)
            _buildPendingContent(vm)
          else
            _buildResolvedContent(vm),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCompactRanking(
    StockAlertsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    final top = vm.productRanking.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.sm),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mais desejados',
            style: textStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: DSSpacing.xs),
          ...top.asMap().entries.map((entry) {
            final idx = entry.key;
            final product = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Text('${idx + 1}º', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: DSSpacing.xs),
                  Expanded(
                    child: Text(
                      product.productName,
                      style: textStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${product.customerCount}x',
                    style: textStyles.caption.copyWith(
                      color: colors.secundaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductScope(
    StockAlertsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.sm),
      decoration: BoxDecoration(
        color: colors.primarySurface,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        border: Border.all(color: colors.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrando por produto',
            style: textStyles.caption.copyWith(
              color: colors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            vm.productFilterName ?? 'Produto selecionado',
            style: textStyles.bodySmall.copyWith(color: colors.primaryColor),
          ),
          const SizedBox(height: DSSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onClearProductFilter,
              child: const Text('Limpar filtro'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingContent(StockAlertsViewModel vm) {
    if (vm.filteredPending.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.notifications_none_rounded,
          title: vm.hasSearch
              ? 'Nenhum aviso encontrado'
              : 'Nenhum aviso pendente',
          message: vm.hasSearch
              ? 'Tente ajustar a busca'
              : 'Quando clientes pedirem reposição de um produto, ele aparecerá aqui',
          actionLabel: vm.hasSearch ? 'Limpar Busca' : null,
          onAction: vm.hasSearch ? presenter.clearSearch : null,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.base),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final group = vm.filteredPending[index];
          return StockAlertCard(
            group: group,
            isActionInProgress: vm.actionInProgressProductId == group.productId,
            onDismiss: () => onDismiss(group.productId),
            onNotify: () => onNotify(group.productId),
          );
        }, childCount: vm.filteredPending.length),
      ),
    );
  }

  Widget _buildResolvedContent(StockAlertsViewModel vm) {
    if (vm.isLoadingResolved) {
      return const SliverFillRemaining(
        child: LoadingIndicator(message: 'Carregando resolvidos...'),
      );
    }

    if (vm.filteredResolved.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'Nenhum aviso resolvido',
          message: 'Avisos resolvidos aparecerão aqui',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.base),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final group = vm.filteredResolved[index];
          return StockAlertCard(group: group);
        }, childCount: vm.filteredResolved.length),
      ),
    );
  }

  Widget _buildMiniCard(
    String title,
    String value,
    Color valueColor,
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
          Text(value, style: textStyles.headline2.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
