import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Commons/Models/StockAlertModel.dart';
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

  StreamSubscription<List<StockAlertModel>>? _pendingSubscription;
  Timer? _debounceTimer;

  // MARK: - Inicialização

  /// Inicia stream real-time de avisos pendentes.
  void startWatchingPending() {
    _viewModel = _viewModel.copyWith(isLoading: true);
    onUpdate?.call();

    _pendingSubscription = _repository.watchPendingAlerts().listen(
      (alerts) {
        final uniqueCustomers = alerts.map((a) => a.customerId).toSet().length;

        _viewModel = _viewModel.copyWith(
          isLoading: false,
          pendingAlerts: alerts,
          pendingCount: alerts.length,
          uniqueCustomersCount: uniqueCustomers,
          productRanking: _buildProductRanking(alerts),
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

    final resolved = await _repository.getResolved();

    _viewModel = _viewModel.copyWith(
      isLoadingResolved: false,
      resolvedAlerts: resolved,
      filteredResolved: resolved,
    );
    _applyFilters();
  }

  // MARK: - Tabs e Filtros

  void setTab(StockAlertTab tab) {
    _viewModel = _viewModel.copyWith(currentTab: tab);
    onUpdate?.call();

    if (tab == StockAlertTab.resolved &&
        _viewModel.resolvedAlerts.isEmpty &&
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

  // MARK: - Filtragem

  void _applyFilters() {
    var pending = List<StockAlertModel>.from(_viewModel.pendingAlerts);
    var resolved = List<StockAlertModel>.from(_viewModel.resolvedAlerts);

    if (_viewModel.searchQuery.isNotEmpty) {
      final q = _viewModel.searchQuery.toLowerCase();
      pending = pending.where((a) {
        return a.customerName.toLowerCase().contains(q) ||
            a.customerWhatsapp.contains(q) ||
            a.productName.toLowerCase().contains(q);
      }).toList();

      resolved = resolved.where((a) {
        return a.customerName.toLowerCase().contains(q) ||
            a.customerWhatsapp.contains(q) ||
            a.productName.toLowerCase().contains(q);
      }).toList();
    }

    _viewModel = _viewModel.copyWith(
      filteredPending: pending,
      filteredResolved: resolved,
    );
    onUpdate?.call();
  }

  // MARK: - Ranking de Produtos

  List<ProductRanking> _buildProductRanking(List<StockAlertModel> alerts) {
    final Map<String, _RankingAccumulator> map = {};
    for (final alert in alerts) {
      final acc = map.putIfAbsent(
        alert.productId,
        () => _RankingAccumulator(alert.productId, alert.productName),
      );
      acc.customerIds.add(alert.customerId);
      acc.totalQuantity += alert.desiredQuantity;
    }

    final ranking = map.values
        .map(
          (acc) => ProductRanking(
            productId: acc.productId,
            productName: acc.productName,
            customerCount: acc.customerIds.length,
            totalDesiredQuantity: acc.totalQuantity,
          ),
        )
        .toList();

    ranking.sort((a, b) => b.customerCount.compareTo(a.customerCount));
    return ranking;
  }

  // MARK: - Ações

  /// Encerra um aviso de estoque.
  Future<bool> dismissAlert(String alertId, {String? notes}) async {
    _viewModel = _viewModel.copyWith(actionInProgressId: alertId);
    onUpdate?.call();

    final success = await _repository.dismissAlert(alertId, notes: notes);

    _viewModel = _viewModel.copyWith(actionInProgressId: null);
    onUpdate?.call();

    return success;
  }

  /// Marca aviso como notificado.
  Future<bool> markNotified(String alertId, {String? notes}) async {
    _viewModel = _viewModel.copyWith(actionInProgressId: alertId);
    onUpdate?.call();

    final success = await _repository.markNotified(alertId, notes: notes);

    _viewModel = _viewModel.copyWith(actionInProgressId: null);
    onUpdate?.call();

    return success;
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

/// Acumulador interno para montar ranking.
class _RankingAccumulator {
  final String productId;
  final String productName;
  final Set<String> customerIds = {};
  int totalQuantity = 0;

  _RankingAccumulator(this.productId, this.productName);
}
