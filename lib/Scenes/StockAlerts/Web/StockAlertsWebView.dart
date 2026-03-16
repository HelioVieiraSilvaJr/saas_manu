import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../StockAlertsPresenter.dart';
import '../StockAlertsViewModel.dart';
import '../Widgets/StockAlertCard.dart';

/// View Web da listagem de avisos de estoque.
class StockAlertsWebView extends StatelessWidget {
  final StockAlertsPresenter presenter;
  final TextEditingController searchController;
  final void Function(String alertId) onDismiss;
  final void Function(String alertId) onNotified;
  final void Function(StockAlertTab tab) onTabChange;

  const StockAlertsWebView({
    super.key,
    required this.presenter,
    required this.searchController,
    required this.onDismiss,
    required this.onNotified,
    required this.onTabChange,
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
          _buildHeader(vm, colors, textStyles),
          const SizedBox(height: DSSpacing.xl),
          _buildMetricCards(vm, colors),
          const SizedBox(height: DSSpacing.xl),
          if (vm.productRanking.isNotEmpty) ...[
            _buildProductRanking(vm, colors, textStyles),
            const SizedBox(height: DSSpacing.xl),
          ],
          _buildTabs(vm, colors, textStyles),
          const SizedBox(height: DSSpacing.lg),
          _buildSearchBar(vm, colors, textStyles),
          const SizedBox(height: DSSpacing.lg),
          _buildContent(vm, colors, textStyles),
        ],
      ),
    );
  }

  // ──────────────────── Header ────────────────────

  Widget _buildHeader(
    StockAlertsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Avisos de Estoque', style: textStyles.headline1),
                  if (vm.pendingCount > 0) ...[
                    const SizedBox(width: DSSpacing.sm),
                    _PulsingBadge(count: vm.pendingCount, colors: colors),
                  ],
                ],
              ),
              const SizedBox(height: DSSpacing.xs),
              Text(
                'Clientes aguardando reposição de estoque para serem notificados',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────── Metrics ────────────────────

  Widget _buildMetricCards(StockAlertsViewModel vm, DSColors colors) {
    return Row(
      children: [
        Expanded(
          child: DSMetricCard(
            title: 'Avisos Pendentes',
            value: vm.pendingCount.toString(),
            comparison: 'aguardando reposição',
            icon: Icons.notifications_active_rounded,
            color: vm.pendingCount > 0 ? colors.orange : colors.green,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Clientes Únicos',
            value: vm.uniqueCustomersCount.toString(),
            comparison: 'clientes esperando',
            icon: Icons.people_rounded,
            color: colors.secundaryColor,
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Produtos Desejados',
            value: vm.productRanking.length.toString(),
            comparison: 'produtos sem estoque',
            icon: Icons.inventory_2_rounded,
          ),
        ),
      ],
    );
  }

  // ──────────────────── Product Ranking ────────────────────

  Widget _buildProductRanking(
    StockAlertsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    final top = vm.productRanking.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: DSSpacing.elevationSmBlur,
            offset: Offset(0, DSSpacing.elevationSmOffset),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 Ranking de Produtos Mais Desejados',
            style: textStyles.labelLarge,
          ),
          const SizedBox(height: DSSpacing.sm),
          ...top.asMap().entries.map((entry) {
            final idx = entry.key;
            final product = entry.value;
            final medal = idx == 0
                ? '🥇'
                : idx == 1
                ? '🥈'
                : idx == 2
                ? '🥉'
                : '${idx + 1}º';

            return Padding(
              padding: const EdgeInsets.only(bottom: DSSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      medal,
                      style: textStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.sm),
                  Expanded(
                    child: Text(
                      product.productName,
                      style: textStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secundaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product.customerCount} clientes',
                      style: textStyles.caption.copyWith(
                        color: colors.secundaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: DSSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Qtd: ${product.totalDesiredQuantity}',
                      style: textStyles.caption.copyWith(
                        color: colors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
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

  // ──────────────────── Tabs ────────────────────

  Widget _buildTabs(
    StockAlertsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: StockAlertTab.values.map((tab) {
        final isSelected = vm.currentTab == tab;
        return Padding(
          padding: const EdgeInsets.only(right: DSSpacing.sm),
          child: ChoiceChip(
            label: Text(tab.label),
            selected: isSelected,
            onSelected: (_) => onTabChange(tab),
            selectedColor: colors.primarySurface,
            labelStyle: textStyles.bodyMedium.copyWith(
              color: isSelected ? colors.primaryColor : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────── Search ────────────────────

  Widget _buildSearchBar(
    StockAlertsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return TextField(
      controller: searchController,
      onChanged: presenter.search,
      decoration: InputDecoration(
        hintText: 'Buscar por cliente, WhatsApp ou produto...',
        prefixIcon: const Icon(Icons.search_rounded),
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
    );
  }

  // ──────────────────── Content ────────────────────

  Widget _buildContent(
    StockAlertsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    if (vm.isLoading) {
      return const LoadingIndicator(message: 'Carregando avisos de estoque...');
    }

    if (vm.currentTab == StockAlertTab.pending) {
      return _buildPendingList(vm, colors);
    } else {
      return _buildResolvedList(vm, colors);
    }
  }

  Widget _buildPendingList(StockAlertsViewModel vm, DSColors colors) {
    if (vm.filteredPending.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none_rounded,
        title: vm.hasSearch
            ? 'Nenhum aviso encontrado'
            : 'Nenhum aviso pendente',
        message: vm.hasSearch
            ? 'Tente ajustar a busca'
            : 'Quando um cliente solicitar aviso de reposição, ele aparecerá aqui',
        actionLabel: vm.hasSearch ? 'Limpar Busca' : null,
        onAction: vm.hasSearch ? presenter.clearSearch : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: vm.filteredPending
          .map(
            (alert) => StockAlertCard(
              alert: alert,
              isActionInProgress: vm.actionInProgressId == alert.uid,
              onDismiss: () => onDismiss(alert.uid),
              onNotified: () => onNotified(alert.uid),
              onWhatsApp: () => _openWhatsApp(alert.customerWhatsapp),
            ),
          )
          .toList(),
    );
  }

  Widget _buildResolvedList(StockAlertsViewModel vm, DSColors colors) {
    if (vm.isLoadingResolved) {
      return const LoadingIndicator(message: 'Carregando resolvidos...');
    }

    if (vm.filteredResolved.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Nenhum aviso resolvido',
        message: 'Avisos resolvidos aparecerão aqui',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: vm.filteredResolved
          .map((alert) => StockAlertCard(alert: alert))
          .toList(),
    );
  }

  void _openWhatsApp(String whatsapp) {
    final cleanNumber = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/55$cleanNumber');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Badge pulsante para indicar pendentes.
class _PulsingBadge extends StatefulWidget {
  final int count;
  final DSColors colors;

  const _PulsingBadge({required this.count, required this.colors});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.scale(
        scale: _animation.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${widget.count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
