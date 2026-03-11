import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSMetricCard.dart';
import '../../../Commons/Widgets/DesignSystem/DSShimmer.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../DashboardTenantPresenter.dart';
import '../DashboardTenantViewModel.dart';
import '../Widgets/SalesChartWidget.dart';
import '../Widgets/RecentSalesWidget.dart';
import '../Widgets/QuickActionsWidget.dart';
import '../Widgets/AlertsWidget.dart';

/// Dashboard Tenant - Layout Mobile (< 1000px).
///
/// Cards empilhados (2 por linha), seções em coluna única.
class DashboardTenantMobileView extends StatelessWidget {
  final DashboardTenantPresenter presenter;
  final DashboardTenantViewModel viewModel;

  const DashboardTenantMobileView({
    super.key,
    required this.presenter,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(DSSpacing.base),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: DSShimmer.metricCard()),
                const SizedBox(width: DSSpacing.sm),
                Expanded(child: DSShimmer.metricCard()),
              ],
            ),
            const SizedBox(height: DSSpacing.sm),
            Row(
              children: [
                Expanded(child: DSShimmer.metricCard()),
                const SizedBox(width: DSSpacing.sm),
                Expanded(child: DSShimmer.metricCard()),
              ],
            ),
            const SizedBox(height: DSSpacing.base),
            DSShimmer.metricCard(height: 200),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: presenter.refresh,
      color: DSColors().primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DSSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alertas
            AlertsWidget(
              alerts: viewModel.alerts,
              onDismiss: presenter.dismissAlert,
              onAction: presenter.handleAlertAction,
            ),

            // Seção 1: Métricas (2x2 grid)
            _buildMetricCards(),
            const SizedBox(height: DSSpacing.base),

            // Seção 4: Ações Rápidas
            QuickActionsWidget(
              onNewSale: presenter.navigateToNewSale,
              onNewProduct: presenter.navigateToNewProduct,
              onNewCustomer: presenter.navigateToNewCustomer,
            ),
            const SizedBox(height: DSSpacing.base),

            // Seção 2: Gráfico
            SalesChartWidget(salesData: viewModel.salesLast7Days),
            const SizedBox(height: DSSpacing.base),

            // Seção 3: Vendas Recentes
            RecentSalesWidget(
              sales: viewModel.recentSales,
              onViewAll: presenter.navigateToAllSales,
            ),
            const SizedBox(height: DSSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    return Column(
      children: [
        // Linha 1: Vendas Hoje + Vendas do Mês
        Row(
          children: [
            Expanded(
              child: DSMetricCard(
                title: 'Vendas Hoje',
                value: viewModel.salesToday.formatToBRL(),
                icon: Icons.attach_money_rounded,
                comparison: _formatPercentChange(
                  viewModel.salesTodayChangePercent,
                ),
                trend: _trendFromPercent(viewModel.salesTodayChangePercent),
              ),
            ),
            const SizedBox(width: DSSpacing.sm),
            Expanded(
              child: DSMetricCard(
                title: 'Vendas do Mês',
                value: viewModel.salesThisMonth.formatToBRL(),
                icon: Icons.trending_up_rounded,
                comparison: _formatPercentChange(
                  viewModel.salesMonthChangePercent,
                ),
                trend: _trendFromPercent(viewModel.salesMonthChangePercent),
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.sm),

        // Linha 2: Clientes + Ticket Médio
        Row(
          children: [
            Expanded(
              child: DSMetricCard(
                title: 'Total de Clientes',
                value: viewModel.totalCustomers.toString(),
                icon: Icons.people_alt_rounded,
                comparison: viewModel.newCustomersThisMonth > 0
                    ? '+${viewModel.newCustomersThisMonth} este mês'
                    : null,
                trend: viewModel.newCustomersThisMonth > 0
                    ? TrendType.up
                    : null,
              ),
            ),
            const SizedBox(width: DSSpacing.sm),
            Expanded(
              child: DSMetricCard(
                title: 'Ticket Médio',
                value: viewModel.ticketMedioThisMonth.formatToBRL(),
                icon: Icons.gps_fixed_rounded,
                comparison: _formatPercentChange(
                  viewModel.ticketMedioChangePercent,
                ),
                trend: _trendFromPercent(viewModel.ticketMedioChangePercent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _formatPercentChange(double? percent) {
    if (percent == null) return null;
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }

  TrendType? _trendFromPercent(double? percent) {
    if (percent == null) return null;
    if (percent > 0) return TrendType.up;
    if (percent < 0) return TrendType.down;
    return TrendType.neutral;
  }
}
