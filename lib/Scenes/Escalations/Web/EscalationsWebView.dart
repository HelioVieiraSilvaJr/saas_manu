import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../EscalationsPresenter.dart';
import '../EscalationsViewModel.dart';
import '../Widgets/EscalationCard.dart';

/// View Web da listagem de atendimentos escalados.
class EscalationsWebView extends StatelessWidget {
  final EscalationsPresenter presenter;
  final TextEditingController searchController;
  final void Function(String escalationId) onAssume;
  final void Function(String escalationId, String customerId) onComplete;
  final void Function(EscalationTab tab) onTabChange;

  const EscalationsWebView({
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
          _buildTabs(vm, colors, textStyles),
          const SizedBox(height: DSSpacing.lg),
          if (vm.currentTab == EscalationTab.active)
            _buildFiltersBar(vm, colors, textStyles),
          if (vm.currentTab == EscalationTab.active)
            const SizedBox(height: DSSpacing.lg),
          _buildContent(vm, colors, textStyles),
        ],
      ),
    );
  }

  // ──────────────────── Header ────────────────────

  Widget _buildHeader(
    EscalationsViewModel vm,
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
                  Text('Atendimentos', style: textStyles.headline1),
                  if (vm.pendingCount > 0) ...[
                    const SizedBox(width: DSSpacing.sm),
                    _PulsingBadge(count: vm.pendingCount, colors: colors),
                  ],
                ],
              ),
              const SizedBox(height: DSSpacing.xs),
              Text(
                'Atendimentos escalados pelo Agente IA para atendimento humano',
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

  Widget _buildMetricCards(EscalationsViewModel vm, DSColors colors) {
    return Row(
      children: [
        Expanded(
          child: DSMetricCard(
            title: 'Pendentes',
            value: vm.pendingCount.toString(),
            comparison: 'aguardando atendente',
            icon: Icons.notification_important_rounded,
            color: vm.pendingCount > 0
                ? colors.orange.withAlpha(50)
                : colors.green.withAlpha(50),
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Em Atendimento',
            value: vm.inProgressCount.toString(),
            comparison: 'sendo atendidos',
            icon: Icons.headset_mic_rounded,
            color: colors.secundaryColor.withAlpha(50),
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        Expanded(
          child: DSMetricCard(
            title: 'Total Ativos',
            value: vm.activeCount.toString(),
            comparison: 'atendimentos abertos',
            icon: Icons.support_agent_rounded,
          ),
        ),
      ],
    );
  }

  // ──────────────────── Tabs ────────────────────

  Widget _buildTabs(
    EscalationsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: EscalationTab.values.map((tab) {
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

  // ──────────────────── Filters ────────────────────

  Widget _buildFiltersBar(
    EscalationsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        // Busca
        Expanded(
          flex: 2,
          child: TextField(
            controller: searchController,
            onChanged: presenter.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou WhatsApp...',
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
          ),
        ),
        const SizedBox(width: DSSpacing.base),
        // Filtro chips
        ...EscalationActiveFilter.values.map((filter) {
          final isSelected = vm.activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: DSSpacing.xs),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => presenter.setActiveFilter(filter),
              selectedColor: colors.primarySurface,
              labelStyle: textStyles.bodySmall.copyWith(
                color: isSelected ? colors.primaryColor : colors.textSecondary,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ──────────────────── Content ────────────────────

  Widget _buildContent(
    EscalationsViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    if (vm.isLoading) {
      return const LoadingIndicator(message: 'Carregando atendimentos...');
    }

    if (vm.currentTab == EscalationTab.active) {
      return _buildActiveList(vm, colors);
    } else {
      return _buildCompletedList(vm, colors);
    }
  }

  Widget _buildActiveList(EscalationsViewModel vm, DSColors colors) {
    if (vm.filteredActive.isEmpty) {
      return EmptyState(
        icon: Icons.support_agent_rounded,
        title: vm.hasActiveFilters || vm.hasSearch
            ? 'Nenhum atendimento encontrado'
            : 'Nenhum atendimento pendente',
        message: vm.hasActiveFilters || vm.hasSearch
            ? 'Tente ajustar os filtros'
            : 'Quando o Agente IA escalar um atendimento, ele aparecerá aqui',
        actionLabel: vm.hasActiveFilters ? 'Limpar Filtros' : null,
        onAction: vm.hasActiveFilters ? presenter.clearFilters : null,
      );
    }

    // Separar pendentes e em atendimento
    final pendentes = vm.filteredActive.where((e) => e.isPending).toList();
    final emAtendimento = vm.filteredActive
        .where((e) => e.isInProgress)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pendentes.isNotEmpty) ...[
          _buildSectionLabel('🔔 Pendentes (${pendentes.length})', colors),
          const SizedBox(height: DSSpacing.sm),
          ...pendentes.map(
            (e) => EscalationCard(
              escalation: e,
              isActionInProgress: vm.actionInProgressId == e.uid,
              onAssume: () => onAssume(e.uid),
              onComplete: () => onComplete(e.uid, e.customerId),
              onWhatsApp: () => _openWhatsApp(e.customerWhatsapp),
            ),
          ),
        ],
        if (emAtendimento.isNotEmpty) ...[
          const SizedBox(height: DSSpacing.lg),
          _buildSectionLabel(
            '💬 Em Atendimento (${emAtendimento.length})',
            colors,
          ),
          const SizedBox(height: DSSpacing.sm),
          ...emAtendimento.map(
            (e) => EscalationCard(
              escalation: e,
              isActionInProgress: vm.actionInProgressId == e.uid,
              onComplete: () => onComplete(e.uid, e.customerId),
              onWhatsApp: () => _openWhatsApp(e.customerWhatsapp),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedList(EscalationsViewModel vm, DSColors colors) {
    if (vm.isLoadingCompleted) {
      return const LoadingIndicator(message: 'Carregando finalizados...');
    }

    if (vm.filteredCompleted.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Nenhum atendimento finalizado',
        message: 'Atendimentos finalizados aparecerão aqui',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: vm.filteredCompleted
          .map((e) => EscalationCard(escalation: e))
          .toList(),
    );
  }

  Widget _buildSectionLabel(String text, DSColors colors) {
    final textStyles = DSTextStyle();
    return Text(
      text,
      style: textStyles.labelLarge.copyWith(color: colors.textSecondary),
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
