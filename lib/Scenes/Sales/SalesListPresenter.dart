import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Commons/Enums/SaleStatus.dart';
import '../../Commons/Models/SaleModel.dart';
import 'SalesListViewModel.dart';
import 'SalesRepository.dart';

/// Presenter da listagem de vendas.
///
/// Gerencia carregamento, busca, filtros, ordenação e exclusão.
class SalesListPresenter {
  final SalesRepository _repository = SalesRepository();

  SalesListViewModel _viewModel = const SalesListViewModel();
  SalesListViewModel get viewModel => _viewModel;

  VoidCallback? onUpdate;

  Timer? _debounceTimer;

  // MARK: - Carregamento

  /// Carrega todas as vendas e calcula métricas.
  Future<void> loadSales() async {
    _viewModel = _viewModel.copyWith(isLoading: true);
    onUpdate?.call();

    final sales = await _repository.getAll();

    // Métricas
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final todaySales = sales
        .where(
          (s) =>
              s.createdAt.isAfter(startOfDay) &&
              s.status != SaleStatus.cancelled,
        )
        .toList();
    final monthSales = sales
        .where(
          (s) =>
              s.createdAt.isAfter(startOfMonth) &&
              s.status != SaleStatus.cancelled,
        )
        .toList();

    final todayTotal = todaySales.fold(0.0, (sum, s) => sum + s.total);
    final monthTotal = monthSales.fold(0.0, (sum, s) => sum + s.total);
    final avgTicket = monthSales.isNotEmpty
        ? monthTotal / monthSales.length
        : 0.0;

    _viewModel = _viewModel.copyWith(
      isLoading: false,
      allSales: sales,
      todayTotal: todayTotal,
      todayCount: todaySales.length,
      monthTotal: monthTotal,
      monthCount: monthSales.length,
      averageTicket: avgTicket,
    );

    _applyFiltersAndSort();
  }

  // MARK: - Busca

  /// Atualiza a query de busca com debounce.
  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _viewModel = _viewModel.copyWith(searchQuery: query);
      _applyFiltersAndSort();
    });
  }

  // MARK: - Filtros

  void setStatusFilter(SaleStatusFilter filter) {
    _viewModel = _viewModel.copyWith(statusFilter: filter);
    _applyFiltersAndSort();
  }

  void setSourceFilter(SaleSourceFilter filter) {
    _viewModel = _viewModel.copyWith(sourceFilter: filter);
    _applyFiltersAndSort();
  }

  void setPeriodFilter(SalePeriodFilter filter) {
    _viewModel = _viewModel.copyWith(periodFilter: filter);
    _applyFiltersAndSort();
  }

  void setSortOption(SaleSortOption option) {
    _viewModel = _viewModel.copyWith(sortOption: option);
    _applyFiltersAndSort();
  }

  void clearFilters() {
    _viewModel = _viewModel.copyWith(
      statusFilter: SaleStatusFilter.all,
      sourceFilter: SaleSourceFilter.all,
      periodFilter: SalePeriodFilter.all,
      sortOption: SaleSortOption.newestFirst,
      searchQuery: '',
    );
    _applyFiltersAndSort();
  }

  // MARK: - Filtragem e Ordenação

  void _applyFiltersAndSort() {
    var result = List<SaleModel>.from(_viewModel.allSales);

    // Busca
    if (_viewModel.searchQuery.isNotEmpty) {
      final q = _viewModel.searchQuery.toLowerCase();
      result = result.where((sale) {
        return sale.customerName.toLowerCase().contains(q) ||
            sale.number.contains(q) ||
            sale.items.any(
              (item) => item.productName.toLowerCase().contains(q),
            );
      }).toList();
    }

    // Filtro de status
    if (_viewModel.statusFilter != SaleStatusFilter.all) {
      final target = _viewModel.statusFilter.saleStatus;
      result = result.where((s) => s.status == target).toList();
    }

    // Filtro de origem
    if (_viewModel.sourceFilter != SaleSourceFilter.all) {
      final target = _viewModel.sourceFilter.saleSource;
      result = result.where((s) => s.source == target).toList();
    }

    // Filtro de período
    if (_viewModel.periodFilter != SalePeriodFilter.all) {
      final startDate = _viewModel.periodFilter.startDate;
      if (startDate != null) {
        result = result.where((s) => s.createdAt.isAfter(startDate)).toList();
      }
    }

    // Ordenação
    switch (_viewModel.sortOption) {
      case SaleSortOption.newestFirst:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SaleSortOption.oldestFirst:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SaleSortOption.totalHighest:
        result.sort((a, b) => b.total.compareTo(a.total));
        break;
      case SaleSortOption.totalLowest:
        result.sort((a, b) => a.total.compareTo(b.total));
        break;
      case SaleSortOption.customerAZ:
        result.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      case SaleSortOption.customerZA:
        result.sort((a, b) => b.customerName.compareTo(a.customerName));
        break;
    }

    _viewModel = _viewModel.copyWith(filteredSales: result);
    onUpdate?.call();
  }

  // MARK: - Exclusão

  /// Deleta uma venda e atualiza a lista.
  Future<bool> deleteSale(String saleId) async {
    _viewModel = _viewModel.copyWith(isDeleting: true);
    onUpdate?.call();

    final success = await _repository.delete(saleId);

    if (success) {
      final updatedSales = _viewModel.allSales
          .where((s) => s.uid != saleId)
          .toList();
      _viewModel = _viewModel.copyWith(
        allSales: updatedSales,
        isDeleting: false,
      );
      _applyFiltersAndSort();
    } else {
      _viewModel = _viewModel.copyWith(
        isDeleting: false,
        errorMessage: 'Erro ao deletar venda',
      );
      onUpdate?.call();
    }

    return success;
  }

  // MARK: - Ações de Pagamento

  /// Envia solicitação de pagamento.
  Future<bool> sendPaymentRequest(String saleId) async {
    final success = await _repository.sendPaymentRequest(saleId);
    if (success) await loadSales();
    return success;
  }

  /// Confirma pagamento (move para esteira de pedidos).
  Future<bool> confirmPayment(String saleId) async {
    final success = await _repository.confirmPayment(saleId);
    if (success) await loadSales();
    return success;
  }

  /// Cancela venda.
  Future<bool> cancelSale(String saleId) async {
    final success = await _repository.cancelSale(saleId);
    if (success) await loadSales();
    return success;
  }

  // MARK: - Stream

  /// Stream para novas vendas automáticas.
  Stream<List<SaleModel>> watchNewAutomatedSales() {
    return _repository.watchNewAutomatedSales();
  }

  // MARK: - Dispose

  void dispose() {
    _debounceTimer?.cancel();
  }
}
