import 'StockAlertModel.dart';

/// Agrupa avisos de estoque por produto para exibição operacional.
class StockAlertGroupModel {
  final String productId;
  final String productName;
  final List<StockAlertModel> alerts;

  const StockAlertGroupModel({
    required this.productId,
    required this.productName,
    required this.alerts,
  });

  int get requestsCount => alerts.length;

  int get customerCount =>
      alerts.map((alert) => alert.customerId).toSet().length;

  int get totalDesiredQuantity =>
      alerts.fold(0, (sum, alert) => sum + alert.desiredQuantity);

  DateTime get oldestCreatedAt => alerts
      .map((alert) => alert.createdAt)
      .reduce((current, next) => current.isBefore(next) ? current : next);

  DateTime get newestCreatedAt => alerts
      .map((alert) => alert.createdAt)
      .reduce((current, next) => current.isAfter(next) ? current : next);

  bool get hasPendingAlerts => alerts.any((alert) => alert.isPending);

  String get waitTimeFormatted {
    final days = DateTime.now().difference(oldestCreatedAt).inDays;
    if (days <= 0) return 'Hoje';
    if (days == 1) return '1 dia';
    return '$days dias';
  }

  bool matchesQuery(String query) {
    final normalized = query.toLowerCase();
    if (productName.toLowerCase().contains(normalized)) return true;
    return alerts.any(
      (alert) =>
          alert.customerName.toLowerCase().contains(normalized) ||
          alert.customerWhatsapp.contains(normalized),
    );
  }
}
