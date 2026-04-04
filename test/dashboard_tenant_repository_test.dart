import 'package:flutter_test/flutter_test.dart';
import 'package:saas_manu/Scenes/DashboardTenant/DashboardTenantRepository.dart';

void main() {
  group('DashboardTenantRepository helpers', () {
    test('saleTotalFromMap suporta total e total_value', () {
      expect(DashboardTenantRepository.saleTotalFromMap({'total': 42.5}), 42.5);
      expect(
        DashboardTenantRepository.saleTotalFromMap({'total_value': 19}),
        19,
      );
      expect(DashboardTenantRepository.saleTotalFromMap({}), 0);
    });

    test('saleItemCountFromMap usa item_count e fallback para items', () {
      expect(
        DashboardTenantRepository.saleItemCountFromMap({'item_count': 7}),
        7,
      );
      expect(
        DashboardTenantRepository.saleItemCountFromMap({
          'items': [
            {'quantity': 2},
            {'quantity': 3},
            {'quantity': 1},
          ],
        }),
        6,
      );
      expect(DashboardTenantRepository.saleItemCountFromMap({}), 0);
    });

    test('previousMonthComparableDate respeita meses com menos dias', () {
      expect(
        DashboardTenantRepository.previousMonthComparableDate(
          DateTime(2026, 3, 31),
        ),
        DateTime(2026, 2, 28),
      );
      expect(
        DashboardTenantRepository.previousMonthComparableDate(
          DateTime(2024, 3, 31),
        ),
        DateTime(2024, 2, 29),
      );
      expect(
        DashboardTenantRepository.previousMonthComparableDate(
          DateTime(2026, 5, 15),
        ),
        DateTime(2026, 4, 15),
      );
    });
  });
}
