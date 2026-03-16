import '../../Commons/Models/StockAlertModel.dart';

/// Tab ativa na tela de avisos de estoque.
enum StockAlertTab {
  pending, // Aguardando reposição
  resolved; // Notificados + Encerrados

  String get label {
    switch (this) {
      case StockAlertTab.pending:
        return 'Pendentes';
      case StockAlertTab.resolved:
        return 'Resolvidos';
    }
  }
}

/// Ranking de produto mais desejado.
class ProductRanking {
  final String productId;
  final String productName;
  final int customerCount;
  final int totalDesiredQuantity;

  const ProductRanking({
    required this.productId,
    required this.productName,
    required this.customerCount,
    required this.totalDesiredQuantity,
  });
}

/// ViewModel da listagem de avisos de estoque.
class StockAlertsViewModel {
  final bool isLoading;
  final StockAlertTab currentTab;
  final String searchQuery;

  // Dados vindos do stream real-time (pendentes)
  final List<StockAlertModel> pendingAlerts;
  // Dados carregados sob demanda (resolvidos)
  final List<StockAlertModel> resolvedAlerts;
  final bool isLoadingResolved;

  // Listas filtradas para exibição
  final List<StockAlertModel> filteredPending;
  final List<StockAlertModel> filteredResolved;

  // Indicadores rápidos
  final int pendingCount;
  final int uniqueCustomersCount;
  final List<ProductRanking> productRanking;

  // Estado de ação
  final String? actionInProgressId;
  final String? errorMessage;

  const StockAlertsViewModel({
    this.isLoading = true,
    this.currentTab = StockAlertTab.pending,
    this.searchQuery = '',
    this.pendingAlerts = const [],
    this.resolvedAlerts = const [],
    this.isLoadingResolved = false,
    this.filteredPending = const [],
    this.filteredResolved = const [],
    this.pendingCount = 0,
    this.uniqueCustomersCount = 0,
    this.productRanking = const [],
    this.actionInProgressId,
    this.errorMessage,
  });

  StockAlertsViewModel copyWith({
    bool? isLoading,
    StockAlertTab? currentTab,
    String? searchQuery,
    List<StockAlertModel>? pendingAlerts,
    List<StockAlertModel>? resolvedAlerts,
    bool? isLoadingResolved,
    List<StockAlertModel>? filteredPending,
    List<StockAlertModel>? filteredResolved,
    int? pendingCount,
    int? uniqueCustomersCount,
    List<ProductRanking>? productRanking,
    Object? actionInProgressId = _sentinel,
    String? errorMessage,
  }) {
    return StockAlertsViewModel(
      isLoading: isLoading ?? this.isLoading,
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
      pendingAlerts: pendingAlerts ?? this.pendingAlerts,
      resolvedAlerts: resolvedAlerts ?? this.resolvedAlerts,
      isLoadingResolved: isLoadingResolved ?? this.isLoadingResolved,
      filteredPending: filteredPending ?? this.filteredPending,
      filteredResolved: filteredResolved ?? this.filteredResolved,
      pendingCount: pendingCount ?? this.pendingCount,
      uniqueCustomersCount: uniqueCustomersCount ?? this.uniqueCustomersCount,
      productRanking: productRanking ?? this.productRanking,
      actionInProgressId: actionInProgressId == _sentinel
          ? this.actionInProgressId
          : actionInProgressId as String?,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Verifica se há busca ativa.
  bool get hasSearch => searchQuery.isNotEmpty;
}

/// Sentinel para nullable copyWith.
const _sentinel = Object();
