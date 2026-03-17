import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../SuperAdminDashboardPresenter.dart';
import '../SuperAdminDashboardViewModel.dart';
import '../Widgets/ActivityTimeline.dart';
import '../Widgets/CriticalAlerts.dart';
import '../Widgets/PlanDistributionChart.dart';
import '../Widgets/TenantGrowthChart.dart';
import '../Widgets/TopTenantsTable.dart';

/// View Mobile do Dashboard SuperAdmin.
class SuperAdminDashboardMobileView extends StatelessWidget {
  final SuperAdminDashboardPresenter presenter;
  final SuperAdminDashboardViewModel viewModel;
  final VoidCallback onNavigateToTenants;

  const SuperAdminDashboardMobileView({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.onNavigateToTenants,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final vm = viewModel;

    if (vm.isLoading) {
      return const LoadingIndicator(message: 'Carregando dashboard...');
    }

    return RefreshIndicator(
      onRefresh: presenter.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DSSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: colors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: DSSpacing.xs),
                Text('Super Admin', style: textStyles.headline3),
                const Spacer(),
                if (vm.analyticsLastUpdated != null)
                  Text(
                    vm.analyticsAgeLabel,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DSSpacing.base),

            // ── Vendas Globais ──
            _buildSectionLabel('VENDAS GLOBAIS', textStyles, colors),
            const SizedBox(height: DSSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _miniMetricCard(
                    'Vendas Hoje',
                    vm.totalSalesToday.formatToBRL(),
                    '${vm.salesCountToday} vendas',
                    Icons.point_of_sale,
                    colors.green,
                    colors,
                    textStyles,
                  ),
                ),
                const SizedBox(width: DSSpacing.sm),
                Expanded(
                  child: _miniMetricCard(
                    'Vendas Mês',
                    vm.totalSalesMonth.formatToBRL(),
                    '${vm.salesCountMonth} vendas',
                    Icons.calendar_month,
                    colors.blue,
                    colors,
                    textStyles,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _miniMetricCard(
                    'Clientes',
                    vm.totalCustomers.toString(),
                    '+${vm.newCustomersMonth} este mês',
                    Icons.people,
                    colors.orange,
                    colors,
                    textStyles,
                  ),
                ),
                const SizedBox(width: DSSpacing.sm),
                Expanded(
                  child: _miniMetricCard(
                    'Ticket Médio',
                    vm.averageTicketMonth.formatToBRL(),
                    'Média do mês',
                    Icons.receipt_long,
                    colors.green,
                    colors,
                    textStyles,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.xl),

            // ── Métricas de Tenants ──
            _buildSectionLabel('PLATAFORMA', textStyles, colors),
            const SizedBox(height: DSSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _miniMetricCard(
                    'Tenants',
                    vm.totalTenants.toString(),
                    '+${vm.newTenantsThisMonth}',
                    Icons.business,
                    colors.blue,
                    colors,
                    textStyles,
                  ),
                ),
                const SizedBox(width: DSSpacing.sm),
                Expanded(
                  child: _miniMetricCard(
                    'Ativos',
                    vm.activeTenants.toString(),
                    '${vm.activePercentage.toStringAsFixed(0)}%',
                    Icons.check_circle,
                    colors.green,
                    colors,
                    textStyles,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _miniMetricCard(
                    'Trial',
                    vm.trialTenants.toString(),
                    '${vm.trialExpiringIn7Days} expirando',
                    Icons.timer,
                    colors.orange,
                    colors,
                    textStyles,
                  ),
                ),
                const SizedBox(width: DSSpacing.sm),
                Expanded(
                  child: _miniMetricCard(
                    'MRR',
                    vm.mrr.formatToBRL(),
                    '${vm.paidCount}P + ${vm.trialCount}T',
                    Icons.attach_money,
                    colors.green,
                    colors,
                    textStyles,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.xl),

            // Gráficos
            TenantGrowthChart(growthData: vm.tenantGrowth),
            const SizedBox(height: DSSpacing.base),
            PlanDistributionChart(
              trialCount: vm.trialCount,
              monthlyStandardCount: vm.monthlyStandardCount,
              monthlyProCount: vm.monthlyProCount,
              quarterlyStandardCount: vm.quarterlyStandardCount,
              quarterlyProCount: vm.quarterlyProCount,
            ),
            const SizedBox(height: DSSpacing.xl),

            // Top Tenants
            if (vm.topTenants.isNotEmpty) ...[
              TopTenantsTable(topTenants: vm.topTenants),
              const SizedBox(height: DSSpacing.xl),
            ],

            // Alertas
            if (vm.hasAlerts) ...[
              CriticalAlerts(
                trialExpiring: vm.trialExpiringSoon,
                inactiveCount: vm.inactiveCount,
                onViewTrialExpiring: onNavigateToTenants,
                onViewInactive: onNavigateToTenants,
              ),
              const SizedBox(height: DSSpacing.xl),
            ],

            // Atividades
            ActivityTimeline(activities: vm.recentActivities),
            const SizedBox(height: DSSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    String title,
    DSTextStyle textStyles,
    DSColors colors,
  ) {
    return Text(
      title,
      style: textStyles.overline.copyWith(
        color: colors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _miniMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
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
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: DSSpacing.xxs),
              Expanded(
                child: Text(
                  title,
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xxs),
          Text(value, style: textStyles.headline3.copyWith(fontSize: 18)),
          Text(
            subtitle,
            style: textStyles.bodySmall.copyWith(
              color: colors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
