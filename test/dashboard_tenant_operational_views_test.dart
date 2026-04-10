import 'package:saas_manu/Scenes/DashboardTenant/DashboardTenantViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard operational state', () {
    test('hasOperationalMetrics fica true quando existe qualquer pendencia', () {
      const viewModel = DashboardTenantViewModel(
        pendingEscalationsCount: 1,
        pendingStockAlertsCount: 0,
        pendingSalesCount: 0,
        paymentSentSalesCount: 0,
        abandonedCartsCount: 0,
      );

      expect(viewModel.hasOperationalMetrics, isTrue);
    });

    test('hasOperationalMetrics fica false quando nao existe pendencia', () {
      const viewModel = DashboardTenantViewModel(
        pendingEscalationsCount: 0,
        pendingStockAlertsCount: 0,
        pendingSalesCount: 0,
        paymentSentSalesCount: 0,
        abandonedCartsCount: 0,
      );

      expect(viewModel.hasOperationalMetrics, isFalse);
    });

    test('hasOperationalMetrics cobre todas as novas contagens operacionais', () {
      const scenarios = [
        DashboardTenantViewModel(pendingStockAlertsCount: 2),
        DashboardTenantViewModel(pendingSalesCount: 3),
        DashboardTenantViewModel(paymentSentSalesCount: 4),
        DashboardTenantViewModel(abandonedCartsCount: 5),
      ];

      for (final viewModel in scenarios) {
        expect(viewModel.hasOperationalMetrics, isTrue);
      }
    });
  });
}
