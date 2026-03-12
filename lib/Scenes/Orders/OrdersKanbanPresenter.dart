import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Commons/Enums/OrderStatus.dart';
import '../Sales/SalesRepository.dart';
import 'OrdersKanbanViewModel.dart';

/// Presenter do Kanban de pedidos.
///
/// Gerencia carregamento e movimentação de pedidos na esteira.
/// Usa o cache do SalesRepository e optimistic updates para
/// evitar re-downloads desnecessários do Firestore.
class OrdersKanbanPresenter {
  final SalesRepository _repository = SalesRepository();

  OrdersKanbanViewModel _viewModel = const OrdersKanbanViewModel();
  OrdersKanbanViewModel get viewModel => _viewModel;

  VoidCallback? onUpdate;

  StreamSubscription? _ordersSubscription;

  // MARK: - Carregamento

  /// Carrega pedidos confirmados (usa cache se disponível).
  Future<void> loadOrders({bool forceRefresh = false}) async {
    // Se há dados no cache, mostra imediatamente sem loading
    final cachedOrders = SalesRepository.salesCache.data
        .where((s) => s.isConfirmed)
        .toList();

    if (cachedOrders.isNotEmpty && !forceRefresh) {
      _viewModel = _viewModel.copyWith(
        isLoading: false,
        allOrders: cachedOrders,
      );
      onUpdate?.call();
      return;
    }

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
      // Atualiza cache global com os dados confirmados
      _viewModel = _viewModel.copyWith(isLoading: false, allOrders: orders);
      onUpdate?.call();
    });
  }

  // MARK: - Movimentação (Optimistic Updates)

  /// Move pedido para o próximo status.
  Future<bool> moveToNext(String saleId) async {
    final order = _viewModel.allOrders
        .where((o) => o.uid == saleId)
        .firstOrNull;

    if (order == null || order.orderStatus == null) return false;

    final nextStatus = order.orderStatus!.next;
    if (nextStatus == null) return false;

    // Optimistic: atualiza localmente primeiro
    _applyOptimisticMove(saleId, nextStatus);

    final success = await _repository.updateOrderStatus(saleId, nextStatus);

    if (!success) {
      // Rollback: reverte para status anterior
      _applyOptimisticMove(saleId, order.orderStatus!);
    } else {
      // Atualiza cache global
      SalesRepository.salesCache.updateWhere(
        (s) => s.uid == saleId,
        order.copyWith(orderStatus: nextStatus),
      );
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

    // Optimistic: atualiza localmente primeiro
    _applyOptimisticMove(saleId, previousStatus);

    final success = await _repository.updateOrderStatus(saleId, previousStatus);

    if (!success) {
      // Rollback
      _applyOptimisticMove(saleId, order.orderStatus!);
    } else {
      SalesRepository.salesCache.updateWhere(
        (s) => s.uid == saleId,
        order.copyWith(orderStatus: previousStatus),
      );
    }

    return success;
  }

  /// Move pedido para um status específico.
  Future<bool> moveToStatus(String saleId, OrderStatus status) async {
    final order = _viewModel.allOrders
        .where((o) => o.uid == saleId)
        .firstOrNull;

    if (order == null) return false;

    final oldStatus = order.orderStatus;

    _applyOptimisticMove(saleId, status);

    final success = await _repository.updateOrderStatus(saleId, status);

    if (!success && oldStatus != null) {
      _applyOptimisticMove(saleId, oldStatus);
    } else if (success) {
      SalesRepository.salesCache.updateWhere(
        (s) => s.uid == saleId,
        order.copyWith(orderStatus: status),
      );
    }

    return success;
  }

  /// Aplica atualização otimista local (sem Firestore).
  void _applyOptimisticMove(String saleId, OrderStatus newStatus) {
    final updatedOrders = _viewModel.allOrders.map((o) {
      if (o.uid == saleId) {
        return o.copyWith(orderStatus: newStatus);
      }
      return o;
    }).toList();

    _viewModel = _viewModel.copyWith(
      allOrders: updatedOrders,
      movingOrderId: null,
    );
    onUpdate?.call();
  }

  // MARK: - Dispose

  void dispose() {
    _ordersSubscription?.cancel();
  }
}
