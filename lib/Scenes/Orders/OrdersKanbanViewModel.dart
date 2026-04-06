import '../../Commons/Enums/OrderStatus.dart';
import '../../Commons/Models/SaleModel.dart';

/// Sentinel para distinguir "não passou parâmetro" de "passou null".
const _sentinel = Object();

/// ViewModel do Kanban de pedidos.
class OrdersKanbanViewModel {
  final bool isLoading;
  final List<SaleModel> allOrders;
  final List<OrderStatus> visibleStatuses;
  final String? errorMessage;
  final String? movingOrderId;

  const OrdersKanbanViewModel({
    this.isLoading = true,
    this.allOrders = const [],
    this.visibleStatuses = OrderStatus.defaultVisibleStatuses,
    this.errorMessage,
    this.movingOrderId,
  });

  /// Pedidos filtrados por status.
  /// Para "completed", limita aos últimos 7 dias.
  List<SaleModel> ordersByStatus(OrderStatus status) {
    if (status == OrderStatus.completed) {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      return allOrders
          .where(
            (o) =>
                o.orderStatus == status &&
                (o.updatedAt ?? o.createdAt).isAfter(sevenDaysAgo),
          )
          .toList();
    }
    return allOrders.where((o) => o.orderStatus == status).toList();
  }

  /// Contagem por status (usa mesma lógica de filtragem).
  int countByStatus(OrderStatus status) => ordersByStatus(status).length;

  /// Total de pedidos ativos (não concluídos).
  int get activeOrdersCount =>
      allOrders.where((o) => o.orderStatus != OrderStatus.completed).length;

  /// Total de pedidos concluídos (últimos 7 dias, visíveis no Kanban).
  int get completedCount => countByStatus(OrderStatus.completed);

  /// Total geral de concluídos (para referência).
  int get allCompletedCount =>
      allOrders.where((o) => o.orderStatus == OrderStatus.completed).length;

  OrdersKanbanViewModel copyWith({
    bool? isLoading,
    List<SaleModel>? allOrders,
    List<OrderStatus>? visibleStatuses,
    String? errorMessage,
    Object? movingOrderId = _sentinel,
  }) {
    return OrdersKanbanViewModel(
      isLoading: isLoading ?? this.isLoading,
      allOrders: allOrders ?? this.allOrders,
      visibleStatuses: visibleStatuses ?? this.visibleStatuses,
      errorMessage: errorMessage ?? this.errorMessage,
      movingOrderId: movingOrderId == _sentinel
          ? this.movingOrderId
          : movingOrderId as String?,
    );
  }
}
