import '../../Commons/Models/StockAlertGroupModel.dart';

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

/// ViewModel da listagem de avisos de estoque.
class StockAlertsViewModel {
  final bool isLoading;
  final StockAlertTab currentTab;
  final String searchQuery;
  final String? productFilterId;
  final String? productFilterName;

  // Dados vindos do stream real-time (pendentes)
  final List<StockAlertGroupModel> pendingGroups;
  // Dados carregados sob demanda (resolvidos)
  final List<StockAlertGroupModel> resolvedGroups;
  final bool isLoadingResolved;

  // Listas filtradas para exibição
  final List<StockAlertGroupModel> filteredPendingGroups;
  final List<StockAlertGroupModel> filteredResolvedGroups;

  // Indicadores rápidos
  final int pendingGroupsCount;
  final int pendingRequestsCount;
  final int uniqueCustomersCount;
  final List<StockAlertGroupModel> productRanking;

  // Estado de ação
  final String? actionInProgressProductId;
  final String? errorMessage;

  const StockAlertsViewModel({
    this.isLoading = true,
    this.currentTab = StockAlertTab.pending,
    this.searchQuery = '',
    this.productFilterId,
    this.productFilterName,
    this.pendingGroups = const [],
    this.resolvedGroups = const [],
    this.isLoadingResolved = false,
    this.filteredPendingGroups = const [],
    this.filteredResolvedGroups = const [],
    this.pendingGroupsCount = 0,
    this.pendingRequestsCount = 0,
    this.uniqueCustomersCount = 0,
    this.productRanking = const [],
    this.actionInProgressProductId,
    this.errorMessage,
  });

  StockAlertsViewModel copyWith({
    bool? isLoading,
    StockAlertTab? currentTab,
    String? searchQuery,
    Object? productFilterId = _sentinel,
    Object? productFilterName = _sentinel,
    List<StockAlertGroupModel>? pendingGroups,
    List<StockAlertGroupModel>? resolvedGroups,
    bool? isLoadingResolved,
    List<StockAlertGroupModel>? filteredPendingGroups,
    List<StockAlertGroupModel>? filteredResolvedGroups,
    int? pendingGroupsCount,
    int? pendingRequestsCount,
    int? uniqueCustomersCount,
    List<StockAlertGroupModel>? productRanking,
    Object? actionInProgressProductId = _sentinel,
    String? errorMessage,
  }) {
    return StockAlertsViewModel(
      isLoading: isLoading ?? this.isLoading,
      currentTab: currentTab ?? this.currentTab,
      searchQuery: searchQuery ?? this.searchQuery,
      productFilterId: productFilterId == _sentinel
          ? this.productFilterId
          : productFilterId as String?,
      productFilterName: productFilterName == _sentinel
          ? this.productFilterName
          : productFilterName as String?,
      pendingGroups: pendingGroups ?? this.pendingGroups,
      resolvedGroups: resolvedGroups ?? this.resolvedGroups,
      isLoadingResolved: isLoadingResolved ?? this.isLoadingResolved,
      filteredPendingGroups:
          filteredPendingGroups ?? this.filteredPendingGroups,
      filteredResolvedGroups:
          filteredResolvedGroups ?? this.filteredResolvedGroups,
      pendingGroupsCount: pendingGroupsCount ?? this.pendingGroupsCount,
      pendingRequestsCount: pendingRequestsCount ?? this.pendingRequestsCount,
      uniqueCustomersCount: uniqueCustomersCount ?? this.uniqueCustomersCount,
      productRanking: productRanking ?? this.productRanking,
      actionInProgressProductId: actionInProgressProductId == _sentinel
          ? this.actionInProgressProductId
          : actionInProgressProductId as String?,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Verifica se há busca ativa.
  bool get hasSearch => searchQuery.isNotEmpty;

  bool get hasScopedProductFilter => productFilterId != null;

  int get pendingCount => pendingGroupsCount;

  List<StockAlertGroupModel> get filteredPending => filteredPendingGroups;

  List<StockAlertGroupModel> get filteredResolved => filteredResolvedGroups;
}

/// Sentinel para nullable copyWith.
const _sentinel = Object();
