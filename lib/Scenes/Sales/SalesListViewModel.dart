import '../../Commons/Enums/SaleStatus.dart';
import '../../Commons/Enums/SaleSource.dart';
import '../../Commons/Models/SaleModel.dart';

/// Filtro de status para listagem de vendas.
enum SaleStatusFilter {
  all,
  pending,
  paymentSent,
  confirmed,
  cancelled;

  String get label {
    switch (this) {
      case SaleStatusFilter.all:
        return 'Todos';
      case SaleStatusFilter.pending:
        return 'Pendente';
      case SaleStatusFilter.paymentSent:
        return 'Cobrança Enviada';
      case SaleStatusFilter.confirmed:
        return 'Pago';
      case SaleStatusFilter.cancelled:
        return 'Cancelada';
    }
  }

  SaleStatus? get saleStatus {
    switch (this) {
      case SaleStatusFilter.all:
        return null;
      case SaleStatusFilter.pending:
        return SaleStatus.pending;
      case SaleStatusFilter.paymentSent:
        return SaleStatus.payment_sent;
      case SaleStatusFilter.confirmed:
        return SaleStatus.confirmed;
      case SaleStatusFilter.cancelled:
        return SaleStatus.cancelled;
    }
  }
}

/// Filtro de origem da venda.
enum SaleSourceFilter {
  all,
  manual,
  whatsappAutomation;

  String get label {
    switch (this) {
      case SaleSourceFilter.all:
        return 'Todas';
      case SaleSourceFilter.manual:
        return 'Manual';
      case SaleSourceFilter.whatsappAutomation:
        return 'WhatsApp Bot';
    }
  }

  SaleSource? get saleSource {
    switch (this) {
      case SaleSourceFilter.all:
        return null;
      case SaleSourceFilter.manual:
        return SaleSource.manual;
      case SaleSourceFilter.whatsappAutomation:
        return SaleSource.whatsapp_automation;
    }
  }
}

/// Filtro de período das vendas.
enum SalePeriodFilter {
  all,
  today,
  last7Days,
  last30Days,
  thisMonth;

  String get label {
    switch (this) {
      case SalePeriodFilter.all:
        return 'Todos';
      case SalePeriodFilter.today:
        return 'Hoje';
      case SalePeriodFilter.last7Days:
        return 'Últimos 7 dias';
      case SalePeriodFilter.last30Days:
        return 'Últimos 30 dias';
      case SalePeriodFilter.thisMonth:
        return 'Este mês';
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case SalePeriodFilter.all:
        return null;
      case SalePeriodFilter.today:
        return DateTime(now.year, now.month, now.day);
      case SalePeriodFilter.last7Days:
        return now.subtract(const Duration(days: 7));
      case SalePeriodFilter.last30Days:
        return now.subtract(const Duration(days: 30));
      case SalePeriodFilter.thisMonth:
        return DateTime(now.year, now.month, 1);
    }
  }
}

/// Opções de ordenação das vendas.
enum SaleSortOption {
  newestFirst,
  oldestFirst,
  totalHighest,
  totalLowest,
  customerAZ,
  customerZA;

  String get label {
    switch (this) {
      case SaleSortOption.newestFirst:
        return 'Mais recentes';
      case SaleSortOption.oldestFirst:
        return 'Mais antigas';
      case SaleSortOption.totalHighest:
        return 'Valor (maior)';
      case SaleSortOption.totalLowest:
        return 'Valor (menor)';
      case SaleSortOption.customerAZ:
        return 'Cliente (A-Z)';
      case SaleSortOption.customerZA:
        return 'Cliente (Z-A)';
    }
  }
}

/// ViewModel da listagem de vendas.
class SalesListViewModel {
  final bool isLoading;
  final List<SaleModel> allSales;
  final List<SaleModel> filteredSales;
  final String searchQuery;
  final SaleStatusFilter statusFilter;
  final SaleSourceFilter sourceFilter;
  final SalePeriodFilter periodFilter;
  final SaleSortOption sortOption;
  final bool isDeleting;
  final String? errorMessage;

  // Métricas
  final double todayTotal;
  final int todayCount;
  final double monthTotal;
  final int monthCount;
  final double averageTicket;

  const SalesListViewModel({
    this.isLoading = true,
    this.allSales = const [],
    this.filteredSales = const [],
    this.searchQuery = '',
    this.statusFilter = SaleStatusFilter.all,
    this.sourceFilter = SaleSourceFilter.all,
    this.periodFilter = SalePeriodFilter.all,
    this.sortOption = SaleSortOption.newestFirst,
    this.isDeleting = false,
    this.errorMessage,
    this.todayTotal = 0,
    this.todayCount = 0,
    this.monthTotal = 0,
    this.monthCount = 0,
    this.averageTicket = 0,
  });

  SalesListViewModel copyWith({
    bool? isLoading,
    List<SaleModel>? allSales,
    List<SaleModel>? filteredSales,
    String? searchQuery,
    SaleStatusFilter? statusFilter,
    SaleSourceFilter? sourceFilter,
    SalePeriodFilter? periodFilter,
    SaleSortOption? sortOption,
    bool? isDeleting,
    String? errorMessage,
    double? todayTotal,
    int? todayCount,
    double? monthTotal,
    int? monthCount,
    double? averageTicket,
  }) {
    return SalesListViewModel(
      isLoading: isLoading ?? this.isLoading,
      allSales: allSales ?? this.allSales,
      filteredSales: filteredSales ?? this.filteredSales,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      sourceFilter: sourceFilter ?? this.sourceFilter,
      periodFilter: periodFilter ?? this.periodFilter,
      sortOption: sortOption ?? this.sortOption,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage ?? this.errorMessage,
      todayTotal: todayTotal ?? this.todayTotal,
      todayCount: todayCount ?? this.todayCount,
      monthTotal: monthTotal ?? this.monthTotal,
      monthCount: monthCount ?? this.monthCount,
      averageTicket: averageTicket ?? this.averageTicket,
    );
  }

  /// Total de vendas carregadas.
  int get totalCount => allSales.length;

  /// Total filtrado.
  int get filteredCount => filteredSales.length;

  /// Verifica se há filtros ativos.
  bool get hasActiveFilters =>
      statusFilter != SaleStatusFilter.all ||
      sourceFilter != SaleSourceFilter.all ||
      periodFilter != SalePeriodFilter.all;

  /// Verifica se há busca ativa.
  bool get hasSearch => searchQuery.isNotEmpty;
}
