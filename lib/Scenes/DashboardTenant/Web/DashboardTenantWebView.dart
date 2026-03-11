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

/// Dashboard Tenant - Layout Web (>= 1000px).
///
/// 4 metric cards em linha, gráfico + vendas recentes lado a lado,
/// ações rápidas e alertas.
class DashboardTenantWebView extends StatelessWidget {
  final DashboardTenantPresenter presenter;
  final DashboardTenantViewModel viewModel;

  const DashboardTenantWebView({
    super.key,
    required this.presenter,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.pagePaddingHorizontalWeb,
          vertical: DSSpacing.pagePaddingVerticalWeb,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                4,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.sm,
                    ),
                    child: DSShimmer.metricCard(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DSSpacing.xl),
            DSShimmer.metricCard(height: 260),
            const SizedBox(height: DSSpacing.base),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: DSSpacing.sm),
                child: DSShimmer.listTile(),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: presenter.refresh,
      color: DSColors().primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.pagePaddingHorizontalWeb,
          vertical: DSSpacing.pagePaddingVerticalWeb,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alertas
            AlertsWidget(
              alerts: viewModel.alerts,
              onDismiss: presenter.dismissAlert,
              onAction: presenter.handleAlertAction,
            ),

            // Seção 1: Métricas (4 cards em linha)
            _buildMetricCards(),
            const SizedBox(height: DSSpacing.xl),

            // Seção 2 + 3: Gráfico + Vendas Recentes (lado a lado)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gráfico (60%)
                Expanded(
                  flex: 3,
                  child: SalesChartWidget(salesData: viewModel.salesLast7Days),
                ),
                const SizedBox(width: DSSpacing.xl),

                // Vendas Recentes (40%)
                Expanded(
                  flex: 2,
                  child: RecentSalesWidget(
                    sales: viewModel.recentSales,
                    onViewAll: presenter.navigateToAllSales,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.xl),

            // Seção 4: Ações Rápidas
            QuickActionsWidget(
              isWeb: true,
              onNewSale: presenter.navigateToNewSale,
              onNewProduct: presenter.navigateToNewProduct,
              onNewCustomer: presenter.navigateToNewCustomer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    return Row(
      children: [
        // Card 1: Vendas Hoje
        Expanded(
          child: DSMetricCard(
            title: 'Vendas Hoje',
            value: viewModel.salesToday.formatToBRL(),
            icon: Icons.attach_money_rounded,
            comparison: _formatPercentChange(viewModel.salesTodayChangePercent),
            trend: _trendFromPercent(viewModel.salesTodayChangePercent),
          ),
        ),
        const SizedBox(width: DSSpacing.md),

        // Card 2: Vendas do Mês
        Expanded(
          child: DSMetricCard(
            title: 'Vendas do Mês',
            value: viewModel.salesThisMonth.formatToBRL(),
            icon: Icons.trending_up_rounded,
            comparison: _formatPercentChange(viewModel.salesMonthChangePercent),
            trend: _trendFromPercent(viewModel.salesMonthChangePercent),
          ),
        ),
        const SizedBox(width: DSSpacing.md),

        // Card 3: Total de Clientes
        Expanded(
          child: DSMetricCard(
            title: 'Total de Clientes',
            value: viewModel.totalCustomers.toString(),
            icon: Icons.people_alt_rounded,
            comparison: viewModel.newCustomersThisMonth > 0
                ? '+${viewModel.newCustomersThisMonth} este mês'
                : null,
            trend: viewModel.newCustomersThisMonth > 0 ? TrendType.up : null,
          ),
        ),
        const SizedBox(width: DSSpacing.md),

        // Card 4: Ticket Médio
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
