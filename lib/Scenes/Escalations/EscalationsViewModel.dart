import '../../Commons/Enums/EscalationStatus.dart';
import '../../Commons/Models/EscalationModel.dart';

/// Tab ativa na tela de escalações.
enum EscalationTab {
  active, // Pendentes + Em atendimento
  completed; // Finalizados

  String get label {
    switch (this) {
      case EscalationTab.active:
        return 'Ativos';
      case EscalationTab.completed:
        return 'Finalizados';
    }
  }
}

/// Filtro de status para escalações ativas.
enum EscalationActiveFilter {
  all,
  pending,
  inProgress;

  String get label {
    switch (this) {
      case EscalationActiveFilter.all:
        return 'Todos';
      case EscalationActiveFilter.pending:
        return 'Pendentes';
      case EscalationActiveFilter.inProgress:
        return 'Em Atendimento';
    }
  }

  EscalationStatus? get escalationStatus {
    switch (this) {
      case EscalationActiveFilter.all:
        return null;
      case EscalationActiveFilter.pending:
        return EscalationStatus.pending;
      case EscalationActiveFilter.inProgress:
        return EscalationStatus.in_progress;
    }
  }
}

/// ViewModel da listagem de atendimentos escalados.
class EscalationsViewModel {
  final bool isLoading;
  final EscalationTab currentTab;
  final EscalationActiveFilter activeFilter;
  final String searchQuery;

  // Dados vindos do stream real-time (ativos)
  final List<EscalationModel> activeEscalations;
  // Dados carregados sob demanda (finalizados)
  final List<EscalationModel> completedEscalations;
  final bool isLoadingCompleted;

  // Listas filtradas para exibição
  final List<EscalationModel> filteredActive;
  final List<EscalationModel> filteredCompleted;

  // Contagens
  final int pendingCount;
  final int inProgressCount;

  // Estado de ação
  final String? actionInProgressId;
  final String? errorMessage;

  const EscalationsViewModel({
    this.isLoading = true,
    this.currentTab = EscalationTab.active,
    this.activeFilter = EscalationActiveFilter.all,
    this.searchQuery = '',
    this.activeEscalations = const [],
    this.completedEscalations = const [],
    this.isLoadingCompleted = false,
    this.filteredActive = const [],
    this.filteredCompleted = const [],
    this.pendingCount = 0,
    this.inProgressCount = 0,
    this.actionInProgressId,
    this.errorMessage,
  });

  EscalationsViewModel copyWith({
    bool? isLoading,
    EscalationTab? currentTab,
    EscalationActiveFilter? activeFilter,
    String? searchQuery,
    List<EscalationModel>? activeEscalations,
    List<EscalationModel>? completedEscalations,
    bool? isLoadingCompleted,
    List<EscalationModel>? filteredActive,
    List<EscalationModel>? filteredCompleted,
    int? pendingCount,
    int? inProgressCount,
    Object? actionInProgressId = _sentinel,
    String? errorMessage,
  }) {
    return EscalationsViewModel(
      isLoading: isLoading ?? this.isLoading,
      currentTab: currentTab ?? this.currentTab,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      activeEscalations: activeEscalations ?? this.activeEscalations,
      completedEscalations: completedEscalations ?? this.completedEscalations,
      isLoadingCompleted: isLoadingCompleted ?? this.isLoadingCompleted,
      filteredActive: filteredActive ?? this.filteredActive,
      filteredCompleted: filteredCompleted ?? this.filteredCompleted,
      pendingCount: pendingCount ?? this.pendingCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      actionInProgressId: actionInProgressId == _sentinel
          ? this.actionInProgressId
          : actionInProgressId as String?,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Contagem total de ativos.
  int get activeCount => activeEscalations.length;

  /// Verifica se há filtros ativos.
  bool get hasActiveFilters => activeFilter != EscalationActiveFilter.all;

  /// Verifica se há busca ativa.
  bool get hasSearch => searchQuery.isNotEmpty;
}

/// Sentinel para nullable copyWith.
const _sentinel = Object();
