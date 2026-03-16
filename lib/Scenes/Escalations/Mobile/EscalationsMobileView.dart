import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../EscalationsPresenter.dart';
import '../EscalationsViewModel.dart';
import '../Widgets/EscalationCard.dart';

/// View Mobile da listagem de atendimentos escalados.
class EscalationsMobileView extends StatelessWidget {
  final EscalationsPresenter presenter;
  final TextEditingController searchController;
  final void Function(String escalationId) onAssume;
  final void Function(String escalationId, String customerId) onComplete;
  final void Function(EscalationTab tab) onTabChange;

  const EscalationsMobileView({
    super.key,
    required this.presenter,
    required this.searchController,
    required this.onAssume,
    required this.onComplete,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final vm = presenter.viewModel;
    final colors = DSColors();
    final textStyles = DSTextStyle();

    if (vm.isLoading) {
      return const LoadingIndicator(message: 'Carregando atendimentos...');
    }

    return RefreshIndicator(
      onRefresh: () async => presenter.startWatchingActive(),
      child: CustomScrollView(
        slivers: [
          // Header compacto com métricas
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
                          '🔔 Pendentes',
                          vm.pendingCount.toString(),
                          vm.pendingCount > 0 ? colors.orange : colors.green,
                          colors,
                          textStyles,
                        ),
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      Expanded(
                        child: _buildMiniCard(
                          '💬 Atendendo',
                          vm.inProgressCount.toString(),
                          colors.secundaryColor,
                          colors,
                          textStyles,
                        ),
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      Expanded(
                        child: _buildMiniCard(
                          '📋 Total',
                          vm.activeCount.toString(),
                          colors.primaryColor,
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
                      hintText: 'Buscar por nome ou WhatsApp...',
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
                  const SizedBox(height: DSSpacing.sm),

                  // Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...EscalationTab.values.map((tab) {
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
                        }),

                        // Filtro inline (apenas na tab ativa)
                        if (vm.currentTab == EscalationTab.active) ...[
                          const SizedBox(width: DSSpacing.sm),
                          ...EscalationActiveFilter.values.map((filter) {
                            final isSelected = vm.activeFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: DSSpacing.xs,
                              ),
                              child: FilterChip(
                                label: Text(filter.label),
                                selected: isSelected,
                                onSelected: (_) =>
                                    presenter.setActiveFilter(filter),
                                selectedColor: colors.primarySurface,
                                labelStyle: textStyles.caption.copyWith(
                                  color: isSelected
                                      ? colors.primaryColor
                                      : colors.textSecondary,
                                ),
                              ),
                            );
                          }),
                        ],

                        if (vm.hasActiveFilters) ...[
                          const SizedBox(width: DSSpacing.xs),
                          ActionChip(
                            avatar: Icon(
                              Icons.filter_alt_off_rounded,
                              size: 16,
                              color: colors.red,
                            ),
                            label: Text('Limpar', style: textStyles.caption),
                            onPressed: () {
                              searchController.clear();
                              presenter.clearFilters();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo
          if (vm.currentTab == EscalationTab.active)
            _buildActiveContent(vm, colors, textStyles)
          else
            _buildCompletedContent(vm, colors, textStyles),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ──────────────────── Active Content ────────────────────

  Widget _buildActiveContent(
    EscalationsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    if (vm.filteredActive.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.support_agent_rounded,
          title: vm.hasActiveFilters || vm.hasSearch
              ? 'Nenhum atendimento encontrado'
              : 'Nenhum atendimento pendente',
          message: vm.hasActiveFilters || vm.hasSearch
              ? 'Tente ajustar os filtros'
              : 'Quando o Agente IA escalar, aparecerá aqui',
          actionLabel: vm.hasActiveFilters ? 'Limpar Filtros' : null,
          onAction: vm.hasActiveFilters ? presenter.clearFilters : null,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.base),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final escalation = vm.filteredActive[index];
          return EscalationCard(
            escalation: escalation,
            isActionInProgress: vm.actionInProgressId == escalation.uid,
            onAssume: escalation.isPending
                ? () => onAssume(escalation.uid)
                : null,
            onComplete: () => onComplete(escalation.uid, escalation.customerId),
            onWhatsApp: () => _openWhatsApp(escalation.customerWhatsapp),
          );
        }, childCount: vm.filteredActive.length),
      ),
    );
  }

  // ──────────────────── Completed Content ────────────────────

  Widget _buildCompletedContent(
    EscalationsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    if (vm.isLoadingCompleted) {
      return const SliverFillRemaining(
        child: LoadingIndicator(message: 'Carregando finalizados...'),
      );
    }

    if (vm.filteredCompleted.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'Nenhum atendimento finalizado',
          message: 'Atendimentos finalizados aparecerão aqui',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.base),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final escalation = vm.filteredCompleted[index];
          return EscalationCard(escalation: escalation);
        }, childCount: vm.filteredCompleted.length),
      ),
    );
  }

  // ──────────────────── Mini Card ────────────────────

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

  void _openWhatsApp(String whatsapp) {
    final cleanNumber = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/55$cleanNumber');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
