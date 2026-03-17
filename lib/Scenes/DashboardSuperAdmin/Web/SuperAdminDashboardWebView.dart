import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
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

/// View Web do Dashboard SuperAdmin.
class SuperAdminDashboardWebView extends StatelessWidget {
  final SuperAdminDashboardPresenter presenter;
  final SuperAdminDashboardViewModel viewModel;
  final VoidCallback onNavigateToTenants;

  const SuperAdminDashboardWebView({
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.pagePaddingHorizontalWeb,
        vertical: DSSpacing.pagePaddingVerticalWeb,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: colors.primaryColor,
                size: 28,
              ),
              const SizedBox(width: DSSpacing.sm),
              Text('Dashboard Super Admin', style: textStyles.headline2),
              const Spacer(),
              if (vm.analyticsLastUpdated != null)
                Padding(
                  padding: const EdgeInsets.only(right: DSSpacing.sm),
                  child: Text(
                    vm.analyticsAgeLabel,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Atualizar (forçar recálculo)',
                onPressed: presenter.refresh,
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // ── Analytics Globais (Vendas Agregadas) ──
          _buildSectionTitle(
            'Vendas Globais',
            Icons.trending_up_rounded,
            colors,
            textStyles,
          ),
          const SizedBox(height: DSSpacing.md),
          Row(
            children: [
              Expanded(
                child: DSMetricCard(
                  title: 'Vendas Hoje',
                  value: vm.totalSalesToday.formatToBRL(),
                  comparison: '${vm.salesCountToday} vendas',
                  trend: vm.salesCountToday > 0
                      ? TrendType.up
                      : TrendType.neutral,
                  icon: Icons.point_of_sale_rounded,
                  color: colors.greenLight,
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: DSMetricCard(
                  title: 'Vendas do Mês',
                  value: vm.totalSalesMonth.formatToBRL(),
                  comparison: '${vm.salesCountMonth} vendas',
                  trend: vm.salesCountMonth > 0
                      ? TrendType.up
                      : TrendType.neutral,
                  icon: Icons.calendar_month_rounded,
                  color: colors.blueLight,
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: DSMetricCard(
                  title: 'Total de Clientes',
                  value: vm.totalCustomers.toString(),
                  comparison: '+${vm.newCustomersMonth} este mês',
                  trend: vm.newCustomersMonth > 0
                      ? TrendType.up
                      : TrendType.neutral,
                  icon: Icons.people_rounded,
                  color: colors.orangeLight,
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: DSMetricCard(
                  title: 'Ticket Médio',
                  value: vm.averageTicketMonth.formatToBRL(),
                  comparison: 'Média do mês',
                  trend: TrendType.neutral,
                  icon: Icons.receipt_long_rounded,
                  color: colors.greenLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // ── Métricas de Tenants ──
          _buildSectionTitle(
            'Plataforma',
            Icons.business_rounded,
            colors,
            textStyles,
          ),
          const SizedBox(height: DSSpacing.md),
          Row(
            children: [
              Expanded(
                child: DSMetricCard(
                  title: 'Total de Tenants',
                  value: vm.totalTenants.toString(),
                  comparison: '+${vm.newTenantsThisMonth} este mês',
                  trend: vm.newTenantsThisMonth > 0
                      ? TrendType.up
                      : TrendType.neutral,
                  icon: Icons.business_rounded,
                  color: colors.blueLight,
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: DSMetricCard(
                  title: 'Tenants Ativos',
                  value: vm.activeTenants.toString(),
                  comparison:
                      '${vm.activePercentage.toStringAsFixed(0)}% do total',
                  trend: TrendType.up,
                  icon: Icons.check_circle_rounded,
                  color: colors.greenLight,
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: DSMetricCard(
                  title: 'Tenants em Trial',
                  value: vm.trialTenants.toString(),
                  comparison: '${vm.trialExpiringIn7Days} expiram em 7 dias',
                  trend: vm.trialExpiringIn7Days > 0
                      ? TrendType.down
                      : TrendType.neutral,
                  icon: Icons.timer_rounded,
                  color: colors.orangeLight,
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: DSMetricCard(
                  title: 'Receita Mensal (MRR)',
                  value: vm.mrr.formatToBRL(),
                  comparison: '${vm.paidCount} Pagos + ${vm.trialCount} Trial',
                  trend: TrendType.up,
                  icon: Icons.attach_money_rounded,
                  color: colors.greenLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // ── Top Tenants + Gráficos ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TenantGrowthChart(growthData: vm.tenantGrowth),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                flex: 2,
                child: PlanDistributionChart(
                  trialCount: vm.trialCount,
                  monthlyStandardCount: vm.monthlyStandardCount,
                  monthlyProCount: vm.monthlyProCount,
                  quarterlyStandardCount: vm.quarterlyStandardCount,
                  quarterlyProCount: vm.quarterlyProCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // ── Top Tenants por Vendas ──
          if (vm.topTenants.isNotEmpty) ...[
            TopTenantsTable(topTenants: vm.topTenants),
            const SizedBox(height: DSSpacing.xl),
          ],

          // Alertas + Atividades
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    CriticalAlerts(
                      trialExpiring: vm.trialExpiringSoon,
                      inactiveCount: vm.inactiveCount,
                      onViewTrialExpiring: onNavigateToTenants,
                      onViewInactive: onNavigateToTenants,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: ActivityTimeline(activities: vm.recentActivities),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        Icon(icon, color: colors.textSecondary, size: 20),
        const SizedBox(width: DSSpacing.xs),
        Text(
          title,
          style: textStyles.headline3.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
