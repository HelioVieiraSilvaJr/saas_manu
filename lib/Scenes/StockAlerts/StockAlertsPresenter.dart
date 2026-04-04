import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Commons/Models/StockAlertGroupModel.dart';
import 'StockAlertsRepository.dart';
import 'StockAlertsViewModel.dart';

/// Presenter da listagem de avisos de estoque.
///
/// Gerencia stream real-time de avisos pendentes, carregamento de
/// resolvidos, busca e indicadores de ranking.
class StockAlertsPresenter {
  final StockAlertsRepository _repository = StockAlertsRepository();

  StockAlertsViewModel _viewModel = const StockAlertsViewModel();
  StockAlertsViewModel get viewModel => _viewModel;

  VoidCallback? onUpdate;

  StreamSubscription<List<StockAlertGroupModel>>? _pendingSubscription;
  Timer? _debounceTimer;

  // MARK: - Inicialização

  /// Inicia stream real-time de avisos pendentes.
  void startWatchingPending() {
    _viewModel = _viewModel.copyWith(isLoading: true);
    onUpdate?.call();

    _pendingSubscription?.cancel();
    _pendingSubscription = _repository.watchPendingAlertGroups().listen(
      (groups) {
        final uniqueCustomers = groups
            .expand((group) => group.alerts.map((alert) => alert.customerId))
            .toSet()
            .length;
        final pendingRequests = groups.fold<int>(
          0,
          (sum, group) => sum + group.requestsCount,
        );

        _viewModel = _viewModel.copyWith(
          isLoading: false,
          pendingGroups: groups,
          pendingGroupsCount: groups.length,
          pendingRequestsCount: pendingRequests,
          uniqueCustomersCount: uniqueCustomers,
          productRanking: groups,
        );
        _applyFilters();
      },
      onError: (e) {
        _viewModel = _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar avisos de estoque',
        );
        onUpdate?.call();
      },
    );
  }

  /// Carrega avisos resolvidos (sob demanda, quando tab muda).
  Future<void> loadResolved() async {
    _viewModel = _viewModel.copyWith(isLoadingResolved: true);
    onUpdate?.call();

    final resolved = await _repository.getResolvedGroups();

    _viewModel = _viewModel.copyWith(
      isLoadingResolved: false,
      resolvedGroups: resolved,
      filteredResolvedGroups: resolved,
    );
    _applyFilters();
  }

  // MARK: - Tabs e Filtros

  void setTab(StockAlertTab tab) {
    _viewModel = _viewModel.copyWith(currentTab: tab);
    onUpdate?.call();

    if (tab == StockAlertTab.resolved &&
        _viewModel.resolvedGroups.isEmpty &&
        !_viewModel.isLoadingResolved) {
      loadResolved();
    }
  }

  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _viewModel = _viewModel.copyWith(searchQuery: query);
      _applyFilters();
    });
  }

  void clearSearch() {
    _viewModel = _viewModel.copyWith(searchQuery: '');
    _applyFilters();
  }

  void setProductFilter(String? productId, {String? productName}) {
    _viewModel = _viewModel.copyWith(
      productFilterId: productId,
      productFilterName: productName,
    );
    _applyFilters();
  }

  // MARK: - Filtragem

  void _applyFilters() {
    var pending = List<StockAlertGroupModel>.from(_viewModel.pendingGroups);
    var resolved = List<StockAlertGroupModel>.from(_viewModel.resolvedGroups);

    if (_viewModel.productFilterId != null) {
      pending = pending
          .where((group) => group.productId == _viewModel.productFilterId)
          .toList();
      resolved = resolved
          .where((group) => group.productId == _viewModel.productFilterId)
          .toList();
    }

    if (_viewModel.searchQuery.isNotEmpty) {
      final q = _viewModel.searchQuery.toLowerCase();
      pending = pending.where((group) => group.matchesQuery(q)).toList();
      resolved = resolved.where((group) => group.matchesQuery(q)).toList();
    }

    _viewModel = _viewModel.copyWith(
      filteredPendingGroups: pending,
      filteredResolvedGroups: resolved,
    );
    onUpdate?.call();
  }

  // MARK: - Ações

  /// Encerra todos os avisos de estoque de um produto.
  Future<bool> dismissGroup(String productId, {String? notes}) async {
    _viewModel = _viewModel.copyWith(actionInProgressProductId: productId);
    onUpdate?.call();

    final success = await _repository.dismissGroup(productId, notes: notes);

    _viewModel = _viewModel.copyWith(actionInProgressProductId: null);
    onUpdate?.call();

    return success;
  }

  /// Dispara notificações de reposição para todos os clientes do produto.
  Future<Map<String, dynamic>> notifyGroup(String productId) async {
    _viewModel = _viewModel.copyWith(actionInProgressProductId: productId);
    onUpdate?.call();

    final result = await _repository.notifyCustomersForProduct(productId);

    _viewModel = _viewModel.copyWith(actionInProgressProductId: null);
    onUpdate?.call();

    return result;
  }

  // MARK: - Stream para Badge

  /// Stream da contagem de pendentes (para badge no menu).
  Stream<int> watchPendingCount() {
    return _repository.watchPendingCount();
  }

  // MARK: - Dispose

  void dispose() {
    _pendingSubscription?.cancel();
    _debounceTimer?.cancel();
  }
}
