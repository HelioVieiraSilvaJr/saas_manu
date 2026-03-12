import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Commons/Enums/OrderStatus.dart';
import '../Sales/SalesRepository.dart';
import 'OrdersKanbanViewModel.dart';

/// Presenter do Kanban de pedidos.
///
/// Gerencia carregamento e movimentação de pedidos na esteira.
class OrdersKanbanPresenter {
  final SalesRepository _repository = SalesRepository();

  OrdersKanbanViewModel _viewModel = const OrdersKanbanViewModel();
  OrdersKanbanViewModel get viewModel => _viewModel;

  VoidCallback? onUpdate;

  StreamSubscription? _ordersSubscription;

  // MARK: - Carregamento

  /// Carrega pedidos confirmados inicialmente.
  Future<void> loadOrders() async {
    _viewModel = _viewModel.copyWith(isLoading: true);
    onUpdate?.call();

    final orders = await _repository.getConfirmedOrders();

    _viewModel = _viewModel.copyWith(isLoading: false, allOrders: orders);
    onUpdate?.call();
  }

  /// Inicia escuta em tempo real dos pedidos.
  void watchOrders() {
    _ordersSubscription?.cancel();
    _ordersSubscription = _repository.watchConfirmedOrders().listen((orders) {
      _viewModel = _viewModel.copyWith(isLoading: false, allOrders: orders);
      onUpdate?.call();
    });
  }

  // MARK: - Movimentação

  /// Move pedido para o próximo status.
  Future<bool> moveToNext(String saleId) async {
    final order = _viewModel.allOrders
        .where((o) => o.uid == saleId)
        .firstOrNull;

    if (order == null || order.orderStatus == null) return false;

    final nextStatus = order.orderStatus!.next;
    if (nextStatus == null) return false;

    _viewModel = _viewModel.copyWith(movingOrderId: saleId);
    onUpdate?.call();

    final success = await _repository.updateOrderStatus(saleId, nextStatus);

    _viewModel = _viewModel.copyWith(movingOrderId: null);

    if (success) {
      await loadOrders();
    } else {
      onUpdate?.call();
    }

    return success;
  }

  /// Move pedido para o status anterior.
  Future<bool> moveToPrevious(String saleId) async {
    final order = _viewModel.allOrders
        .where((o) => o.uid == saleId)
        .firstOrNull;

    if (order == null || order.orderStatus == null) return false;

    final previousStatus = order.orderStatus!.previous;
    if (previousStatus == null) return false;

    _viewModel = _viewModel.copyWith(movingOrderId: saleId);
    onUpdate?.call();

    final success = await _repository.updateOrderStatus(saleId, previousStatus);

    _viewModel = _viewModel.copyWith(movingOrderId: null);

    if (success) {
      await loadOrders();
    } else {
      onUpdate?.call();
    }

    return success;
  }

  /// Move pedido para um status específico.
  Future<bool> moveToStatus(String saleId, OrderStatus status) async {
    _viewModel = _viewModel.copyWith(movingOrderId: saleId);
    onUpdate?.call();

    final success = await _repository.updateOrderStatus(saleId, status);

    _viewModel = _viewModel.copyWith(movingOrderId: null);

    if (success) {
      await loadOrders();
    } else {
      onUpdate?.call();
    }

    return success;
  }

  // MARK: - Dispose

  void dispose() {
    _ordersSubscription?.cancel();
  }
}
