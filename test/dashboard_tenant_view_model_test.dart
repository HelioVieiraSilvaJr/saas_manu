import 'package:flutter_test/flutter_test.dart';
import 'package:saas_manu/Scenes/DashboardTenant/DashboardTenantViewModel.dart';

void main() {
  group('DashboardTenantViewModel computed metrics', () {
    test('calcula ticket medio e variacoes quando ha base comparativa', () {
      const viewModel = DashboardTenantViewModel(
        salesToday: 150,
        salesYesterday: 100,
        salesThisMonth: 1200,
        salesLastMonthSamePeriod: 800,
        salesCountThisMonth: 6,
        salesCountLastMonth: 4,
      );

      expect(viewModel.ticketMedioThisMonth, 200);
      expect(viewModel.ticketMedioLastMonth, 200);
      expect(viewModel.salesTodayChangePercent, 50);
      expect(viewModel.salesMonthChangePercent, 50);
      expect(viewModel.ticketMedioChangePercent, 0);
    });

    test('retorna 100 quando periodo atual tem valor e comparativo era zero', () {
      const viewModel = DashboardTenantViewModel(
        salesToday: 80,
        salesYesterday: 0,
        salesThisMonth: 500,
        salesLastMonthSamePeriod: 0,
        salesCountThisMonth: 5,
        salesCountLastMonth: 0,
      );

      expect(viewModel.salesTodayChangePercent, 100);
      expect(viewModel.salesMonthChangePercent, 100);
      expect(viewModel.ticketMedioLastMonth, 0);
      expect(viewModel.ticketMedioChangePercent, 100);
    });

    test('retorna null quando ambos periodos estao zerados', () {
      const viewModel = DashboardTenantViewModel();

      expect(viewModel.salesTodayChangePercent, isNull);
      expect(viewModel.salesMonthChangePercent, isNull);
      expect(viewModel.ticketMedioChangePercent, isNull);
    });

    test('copyWith preserva erro quando clearError esta desabilitado', () {
      const original = DashboardTenantViewModel(errorMessage: 'falhou');

      final updated = original.copyWith(
        isLoading: false,
        pendingSalesCount: 3,
        clearError: false,
      );

      expect(updated.isLoading, isFalse);
      expect(updated.pendingSalesCount, 3);
      expect(updated.errorMessage, 'falhou');
    });
  });
}
