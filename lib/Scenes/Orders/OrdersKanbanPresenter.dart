import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../Commons/Enums/OrderStatus.dart';
import '../../Sources/SessionManager.dart';
import '../Sales/SalesRepository.dart';
import 'OrdersKanbanViewModel.dart';

/// Presenter do Kanban de pedidos.
///
/// Gerencia carregamento e movimentação de pedidos na esteira.
/// Usa o cache do SalesRepository e optimistic updates para
/// evitar re-downloads desnecessários do Firestore.
class OrdersKanbanPresenter {
  final SalesRepository _repository = SalesRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OrdersKanbanViewModel _viewModel = const OrdersKanbanViewModel();
  OrdersKanbanViewModel get viewModel => _viewModel;

  VoidCallback? onUpdate;

  StreamSubscription? _ordersSubscription;

  DocumentReference<Map<String, dynamic>> get _tenantRef {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants').doc(tenantId);
  }

  CollectionReference<Map<String, dynamic>> get _salesCollection {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants/$tenantId/sales');
  }

  List<OrderStatus> _parseVisibleStatuses(dynamic rawValue) {
    final values = rawValue is Iterable ? rawValue : const [];
    final parsed = values
        .map((value) => OrderStatus.fromString(value.toString()))
        .where((status) => OrderStatus.configurableStatuses.contains(status))
        .toSet()
        .toList();

    if (!parsed.contains(OrderStatus.awaiting_processing)) {
      parsed.insert(0, OrderStatus.awaiting_processing);
    }
    if (!parsed.contains(OrderStatus.completed)) {
      parsed.add(OrderStatus.completed);
    }

    parsed.sort(
      (a, b) => OrderStatus.configurableStatuses
          .indexOf(a)
          .compareTo(OrderStatus.configurableStatuses.indexOf(b)),
    );

    return parsed.isEmpty ? OrderStatus.defaultVisibleStatuses : parsed;
  }

  Future<void> _loadBoardSettings() async {
    try {
      final tenantDoc = await _tenantRef.get();
      final visibleStatuses = _parseVisibleStatuses(
        tenantDoc.data()?['orders_board_visible_statuses'],
      );
      _viewModel = _viewModel.copyWith(visibleStatuses: visibleStatuses);
      onUpdate?.call();
    } catch (_) {
      _viewModel = _viewModel.copyWith(
        visibleStatuses: OrderStatus.defaultVisibleStatuses,
      );
      onUpdate?.call();
    }
  }

  // MARK: - Carregamento

  /// Carrega pedidos confirmados (usa cache se disponível).
  Future<void> loadOrders({bool forceRefresh = false}) async {
    await _loadBoardSettings();

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

  Future<bool> saveVisibleStatuses(List<OrderStatus> statuses) async {
    final normalized = statuses.toSet().toList()
      ..removeWhere(
        (status) => !OrderStatus.configurableStatuses.contains(status),
      );
    if (!normalized.contains(OrderStatus.awaiting_processing)) {
      normalized.insert(0, OrderStatus.awaiting_processing);
    }
    if (!normalized.contains(OrderStatus.completed)) {
      normalized.add(OrderStatus.completed);
    }
    normalized.sort(
      (a, b) => OrderStatus.configurableStatuses
          .indexOf(a)
          .compareTo(OrderStatus.configurableStatuses.indexOf(b)),
    );

    final removedStatuses = _viewModel.visibleStatuses
        .where((status) => !normalized.contains(status))
        .toList();

    try {
      await _tenantRef.set({
        'orders_board_visible_statuses': normalized.map((e) => e.name).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (removedStatuses.isNotEmpty) {
        final batch = _firestore.batch();
        var hasChanges = false;
        for (final order in _viewModel.allOrders) {
          if (order.orderStatus != null &&
              removedStatuses.contains(order.orderStatus)) {
            hasChanges = true;
            batch.update(_salesCollection.doc(order.uid), {
              'order_status': OrderStatus.awaiting_processing.name,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        }
        if (hasChanges) {
          await batch.commit();
        }

        final updatedOrders = _viewModel.allOrders.map((order) {
          if (order.orderStatus != null &&
              removedStatuses.contains(order.orderStatus)) {
            return order.copyWith(orderStatus: OrderStatus.awaiting_processing);
          }
          return order;
        }).toList();
        _viewModel = _viewModel.copyWith(allOrders: updatedOrders);
      }

      _viewModel = _viewModel.copyWith(visibleStatuses: normalized);
      onUpdate?.call();
      return true;
    } catch (_) {
      return false;
    }
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
    if (order.orderStatus == status) return true;

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
