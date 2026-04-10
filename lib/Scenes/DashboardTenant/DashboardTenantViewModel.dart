import 'DashboardTenantRepository.dart';

/// Tipo de alerta do Dashboard.
enum DashboardAlertType {
  planExpiring,
  planExpired,
  serviceInterrupted,
  trialActive,
  productsWithoutImage,
  emptyCatalog,
  noCustomers,
  noSalesThisMonth,
  pendingEscalations,
  pendingStockAlerts,
  pendingSalesAction,
  paymentFollowUp,
  abandonedCarts,
}

/// Modelo de alerta para o Dashboard.
class DashboardAlert {
  final DashboardAlertType type;
  final String title;
  final String actionLabel;
  final String route;
  final bool isWarning; // true = laranja, false = azul/info
  final bool isCritical; // true = vermelho (expirado/interrompido)

  DashboardAlert({
    required this.type,
    required this.title,
    required this.actionLabel,
    required this.route,
    this.isWarning = false,
    this.isCritical = false,
  });

  /// Chave para PreferencesManager (dismiss).
  String get dismissKey => 'dashboard_alert_${type.name}';

  /// Prioridade do alerta (menor = mais importante).
  int get priority {
    switch (type) {
      case DashboardAlertType.serviceInterrupted:
        return -2;
      case DashboardAlertType.planExpired:
        return -1;
      case DashboardAlertType.planExpiring:
        return 0;
      case DashboardAlertType.trialActive:
        return 0;
      case DashboardAlertType.emptyCatalog:
        return 1;
      case DashboardAlertType.noCustomers:
        return 2;
      case DashboardAlertType.productsWithoutImage:
        return 3;
      case DashboardAlertType.noSalesThisMonth:
        return 4;
      case DashboardAlertType.pendingEscalations:
        return 1;
      case DashboardAlertType.pendingStockAlerts:
        return 2;
      case DashboardAlertType.pendingSalesAction:
        return 1;
      case DashboardAlertType.paymentFollowUp:
        return 1;
      case DashboardAlertType.abandonedCarts:
        return 2;
    }
  }
}

/// Estado do Dashboard Tenant.
class DashboardTenantViewModel {
  // MARK: - Loading State
  final bool isLoading;
  final String? errorMessage;

  // MARK: - Métricas
  final double salesToday;
  final double salesYesterday;
  final double salesThisMonth;
  final double salesLastMonthSamePeriod;
  final int salesCountThisMonth;
  final int salesCountLastMonth;
  final int totalCustomers;
  final int newCustomersThisMonth;

  // MARK: - Gráfico
  final List<DailySalesDTO> salesLast7Days;

  // MARK: - Vendas Recentes
  final List<RecentSaleDTO> recentSales;

  // MARK: - Alertas
  final int totalProducts;
  final int productsWithoutImage;
  final List<DashboardAlert> alerts;

  // MARK: - Operacional
  final int pendingEscalationsCount;
  final int pendingStockAlertsCount;
  final int pendingSalesCount;
  final int paymentSentSalesCount;
  final int abandonedCartsCount;

  const DashboardTenantViewModel({
    this.isLoading = true,
    this.errorMessage,
    this.salesToday = 0,
    this.salesYesterday = 0,
    this.salesThisMonth = 0,
    this.salesLastMonthSamePeriod = 0,
    this.salesCountThisMonth = 0,
    this.salesCountLastMonth = 0,
    this.totalCustomers = 0,
    this.newCustomersThisMonth = 0,
    this.salesLast7Days = const [],
    this.recentSales = const [],
    this.totalProducts = 0,
    this.productsWithoutImage = 0,
    this.alerts = const [],
    this.pendingEscalationsCount = 0,
    this.pendingStockAlertsCount = 0,
    this.pendingSalesCount = 0,
    this.paymentSentSalesCount = 0,
    this.abandonedCartsCount = 0,
  });

  // MARK: - Computed

  /// Ticket médio do mês atual.
  double get ticketMedioThisMonth {
    if (salesCountThisMonth == 0) return 0;
    return salesThisMonth / salesCountThisMonth;
  }

  /// Ticket médio do mês anterior (mesmo período).
  double get ticketMedioLastMonth {
    if (salesCountLastMonth == 0) return 0;
    return salesLastMonthSamePeriod / salesCountLastMonth;
  }

  /// Percentual de variação vendas hoje vs ontem.
  double? get salesTodayChangePercent {
    if (salesYesterday == 0 && salesToday == 0) return null;
    if (salesYesterday == 0) return 100;
    return ((salesToday - salesYesterday) / salesYesterday) * 100;
  }

  /// Percentual de variação vendas mês vs mês anterior.
  double? get salesMonthChangePercent {
    if (salesLastMonthSamePeriod == 0 && salesThisMonth == 0) return null;
    if (salesLastMonthSamePeriod == 0) return 100;
    return ((salesThisMonth - salesLastMonthSamePeriod) /
            salesLastMonthSamePeriod) *
        100;
  }

  /// Percentual de variação ticket médio.
  double? get ticketMedioChangePercent {
    if (ticketMedioLastMonth == 0 && ticketMedioThisMonth == 0) return null;
    if (ticketMedioLastMonth == 0) return 100;
    return ((ticketMedioThisMonth - ticketMedioLastMonth) /
            ticketMedioLastMonth) *
        100;
  }

  // MARK: - CopyWith

  DashboardTenantViewModel copyWith({
    bool? isLoading,
    String? errorMessage,
    double? salesToday,
    double? salesYesterday,
    double? salesThisMonth,
    double? salesLastMonthSamePeriod,
    int? salesCountThisMonth,
    int? salesCountLastMonth,
    int? totalCustomers,
    int? newCustomersThisMonth,
    List<DailySalesDTO>? salesLast7Days,
    List<RecentSaleDTO>? recentSales,
    int? totalProducts,
    int? productsWithoutImage,
    List<DashboardAlert>? alerts,
    int? pendingEscalationsCount,
    int? pendingStockAlertsCount,
    int? pendingSalesCount,
    int? paymentSentSalesCount,
    int? abandonedCartsCount,
    bool clearError = true,
  }) {
    return DashboardTenantViewModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError
          ? errorMessage
          : (errorMessage ?? this.errorMessage),
      salesToday: salesToday ?? this.salesToday,
      salesYesterday: salesYesterday ?? this.salesYesterday,
      salesThisMonth: salesThisMonth ?? this.salesThisMonth,
      salesLastMonthSamePeriod:
          salesLastMonthSamePeriod ?? this.salesLastMonthSamePeriod,
      salesCountThisMonth: salesCountThisMonth ?? this.salesCountThisMonth,
      salesCountLastMonth: salesCountLastMonth ?? this.salesCountLastMonth,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      newCustomersThisMonth:
          newCustomersThisMonth ?? this.newCustomersThisMonth,
      salesLast7Days: salesLast7Days ?? this.salesLast7Days,
      recentSales: recentSales ?? this.recentSales,
      totalProducts: totalProducts ?? this.totalProducts,
      productsWithoutImage: productsWithoutImage ?? this.productsWithoutImage,
      alerts: alerts ?? this.alerts,
      pendingEscalationsCount:
          pendingEscalationsCount ?? this.pendingEscalationsCount,
      pendingStockAlertsCount:
          pendingStockAlertsCount ?? this.pendingStockAlertsCount,
      pendingSalesCount: pendingSalesCount ?? this.pendingSalesCount,
      paymentSentSalesCount:
          paymentSentSalesCount ?? this.paymentSentSalesCount,
      abandonedCartsCount: abandonedCartsCount ?? this.abandonedCartsCount,
    );
  }
}
