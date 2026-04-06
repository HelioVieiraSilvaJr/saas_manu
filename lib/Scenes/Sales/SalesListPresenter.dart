import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Commons/Enums/SaleStatus.dart';
import '../../Commons/Enums/OrderStatus.dart';
import '../../Commons/Models/SaleModel.dart';
import 'SalesListViewModel.dart';
import 'SalesRepository.dart';

/// Presenter da listagem de vendas.
///
/// Gerencia carregamento, busca, filtros, ordenação e exclusão.
/// Usa stream real-time do Firestore para manter a lista sincronizada.
/// Mutações usam optimistic updates (atualiza localmente primeiro).
class SalesListPresenter {
  final SalesRepository _repository = SalesRepository();

  SalesListViewModel _viewModel = const SalesListViewModel();
  SalesListViewModel get viewModel => _viewModel;

  VoidCallback? onUpdate;

  Timer? _debounceTimer;
  StreamSubscription<List<SaleModel>>? _salesSubscription;

  // MARK: - Real-Time Streaming

  DateTime _normalizeDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final left = _normalizeDay(a);
    final right = _normalizeDay(b);
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  bool _isOpenSale(SaleModel sale) =>
      sale.status != SaleStatus.confirmed &&
      sale.status != SaleStatus.cancelled;

  bool _isClosedSale(SaleModel sale) => !_isOpenSale(sale);

  List<SaleModel> _salesForDay(List<SaleModel> sales, DateTime day) {
    final target = _normalizeDay(day);
    return sales.where((sale) => _isSameDay(sale.createdAt, target)).toList();
  }

  List<DateTime> _extractAvailableMonths(List<SaleModel> sales) {
    final seen = <String>{};
    final months = <DateTime>[];
    final today = DateTime.now();
    final currentMonth = DateTime(today.year, today.month);
    months.add(currentMonth);
    seen.add('${currentMonth.year}-${currentMonth.month}');

    for (final sale in sales) {
      final month = DateTime(sale.createdAt.year, sale.createdAt.month);
      final key = '${month.year}-${month.month}';
      if (seen.add(key)) {
        months.add(month);
      }
    }

    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  /// Inicia escuta em tempo real de todas as vendas.
  void startWatching() {
    _viewModel = _viewModel.copyWith(
      isLoading: true,
      selectedDay: _viewModel.selectedDay ?? _normalizeDay(DateTime.now()),
    );
    onUpdate?.call();

    _salesSubscription?.cancel();
    _salesSubscription = _repository.watchAllSales().listen(
      (sales) {
        // Atualiza cache global
        SalesRepository.salesCache.set(sales);
        _updateViewModelWithSales(sales);
      },
      onError: (e) {
        _viewModel = _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar vendas',
        );
        onUpdate?.call();
      },
    );
  }

  /// Calcula métricas e atualiza o ViewModel com a lista de vendas.
  void _updateViewModelWithSales(List<SaleModel> sales) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final selectedDay = _normalizeDay(_viewModel.selectedDay ?? now);
    final availableMonths = _extractAvailableMonths(sales);

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
      selectedDay: selectedDay,
      availableMonths: availableMonths,
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

  void goToToday() {
    _viewModel = _viewModel.copyWith(
      selectedDay: _normalizeDay(DateTime.now()),
    );
    _applyFiltersAndSort();
  }

  void goToPreviousDay() {
    final current = _viewModel.selectedDayOrToday;
    _viewModel = _viewModel.copyWith(
      selectedDay: current.subtract(const Duration(days: 1)),
    );
    _applyFiltersAndSort();
  }

  void goToNextDay() {
    final current = _viewModel.selectedDayOrToday;
    final today = _normalizeDay(DateTime.now());
    if (!current.isBefore(today)) return;

    final nextDay = current.add(const Duration(days: 1));
    _viewModel = _viewModel.copyWith(
      selectedDay: nextDay.isAfter(today) ? today : nextDay,
    );
    _applyFiltersAndSort();
  }

  void setSelectedMonth(DateTime month) {
    final today = DateTime.now();
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;
    final targetDay = isCurrentMonth
        ? today.day
        : DateTime(month.year, month.month + 1, 0).day;
    _viewModel = _viewModel.copyWith(
      selectedDay: DateTime(month.year, month.month, targetDay),
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

    final today = _normalizeDay(DateTime.now());
    final selectedDay = _normalizeDay(_viewModel.selectedDayOrToday);
    final todaySales = _salesForDay(result, today);
    final selectedSales = _salesForDay(result, selectedDay);

    _viewModel = _viewModel.copyWith(
      filteredSales: result,
      todayOpenSales: todaySales.where(_isOpenSale).toList(),
      todayClosedSales: todaySales.where(_isClosedSale).toList(),
      selectedDayOpenSales: selectedSales.where(_isOpenSale).toList(),
      selectedDayClosedSales: selectedSales.where(_isClosedSale).toList(),
      selectedDay: selectedDay,
    );
    onUpdate?.call();
  }

  // MARK: - Exclusão

  /// Deleta uma venda e atualiza a lista.
  Future<bool> deleteSale(String saleId) async {
    _viewModel = _viewModel.copyWith(isDeleting: true);
    onUpdate?.call();

    final success = await _repository.delete(saleId);

    if (success) {
      // Remove do cache global
      SalesRepository.salesCache.removeWhere((s) => s.uid == saleId);

      // Remove do ViewModel local
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

  // MARK: - Ações de Pagamento (Optimistic Updates)

  /// Envia solicitação de pagamento.
  Future<bool> sendPaymentRequest(String saleId) async {
    final success = await _repository.sendPaymentRequest(saleId);
    if (success) {
      _updateSaleLocally(
        saleId,
        (sale) => sale.copyWith(
          status: SaleStatus.payment_sent,
          paymentRequestedAt: DateTime.now(),
        ),
      );
    }
    return success;
  }

  /// Confirma pagamento (move para esteira de pedidos).
  Future<bool> confirmPayment(String saleId) async {
    final success = await _repository.confirmPayment(saleId);
    if (success) {
      _updateSaleLocally(
        saleId,
        (sale) => sale.copyWith(
          status: SaleStatus.confirmed,
          orderStatus: OrderStatus.awaiting_processing,
          paymentConfirmedAt: DateTime.now(),
        ),
      );
    }
    return success;
  }

  /// Cancela venda.
  Future<bool> cancelSale(String saleId) async {
    final success = await _repository.cancelSale(saleId);
    if (success) {
      _updateSaleLocally(
        saleId,
        (sale) => sale.copyWith(status: SaleStatus.cancelled),
      );
    }
    return success;
  }

  /// Atualiza uma venda localmente no cache e no ViewModel.
  void _updateSaleLocally(
    String saleId,
    SaleModel Function(SaleModel) transform,
  ) {
    // Atualiza no cache global
    final sale = _viewModel.allSales.where((s) => s.uid == saleId).firstOrNull;
    if (sale != null) {
      final updated = transform(sale);
      SalesRepository.salesCache.updateWhere((s) => s.uid == saleId, updated);
    }

    // Atualiza no ViewModel local
    final updatedSales = _viewModel.allSales.map((s) {
      if (s.uid == saleId) return transform(s);
      return s;
    }).toList();

    _updateViewModelWithSales(updatedSales);
  }

  // MARK: - Stream

  /// Stream para novas vendas automáticas.
  Stream<List<SaleModel>> watchNewAutomatedSales() {
    return _repository.watchNewAutomatedSales();
  }

  // MARK: - Dispose

  void dispose() {
    _debounceTimer?.cancel();
    _salesSubscription?.cancel();
  }
}
