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
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: colors.primaryColor,
                size: 28,
              ),
              const SizedBox(width: DSSpacing.sm),
              Text('Dashboard Super Admin', style: textStyles.headline2),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
                onPressed: presenter.refresh,
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // 4 Metric Cards
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
                  icon: Icons.business,
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
                  icon: Icons.check_circle,
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
                  icon: Icons.timer,
                  color: colors.orangeLight,
                ),
              ),
              const SizedBox(width: DSSpacing.base),
              Expanded(
                child: DSMetricCard(
                  title: 'Receita Mensal (MRR)',
                  value: vm.mrr.formatToBRL(),
                  comparison: '${vm.basicCount} Basic + ${vm.fullCount} Full',
                  trend: TrendType.up,
                  icon: Icons.attach_money,
                  color: colors.greenLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // Gráficos
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
                  basicCount: vm.basicCount,
                  fullCount: vm.fullCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

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
}
