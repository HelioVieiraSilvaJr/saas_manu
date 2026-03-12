import '../../Commons/Enums/OrderStatus.dart';
import '../../Commons/Models/SaleModel.dart';

/// ViewModel do Kanban de pedidos.
class OrdersKanbanViewModel {
  final bool isLoading;
  final List<SaleModel> allOrders;
  final String? errorMessage;
  final String? movingOrderId;

  const OrdersKanbanViewModel({
    this.isLoading = true,
    this.allOrders = const [],
    this.errorMessage,
    this.movingOrderId,
  });

  /// Pedidos filtrados por status.
  List<SaleModel> ordersByStatus(OrderStatus status) {
    return allOrders.where((o) => o.orderStatus == status).toList();
  }

  /// Contagem por status.
  int countByStatus(OrderStatus status) => ordersByStatus(status).length;

  /// Total de pedidos ativos (não concluídos).
  int get activeOrdersCount =>
      allOrders.where((o) => o.orderStatus != OrderStatus.completed).length;

  /// Total de pedidos concluídos.
  int get completedCount => countByStatus(OrderStatus.completed);

  OrdersKanbanViewModel copyWith({
    bool? isLoading,
    List<SaleModel>? allOrders,
    String? errorMessage,
    String? movingOrderId,
  }) {
    return OrdersKanbanViewModel(
      isLoading: isLoading ?? this.isLoading,
      allOrders: allOrders ?? this.allOrders,
      errorMessage: errorMessage ?? this.errorMessage,
      movingOrderId: movingOrderId ?? this.movingOrderId,
    );
  }
}
