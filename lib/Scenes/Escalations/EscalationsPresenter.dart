import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Commons/Enums/EscalationStatus.dart';
import '../../Commons/Models/EscalationModel.dart';
import '../../Sources/SessionManager.dart';
import 'EscalationsRepository.dart';
import 'EscalationsViewModel.dart';

/// Presenter da listagem de atendimentos escalados.
///
/// Gerencia stream real-time de escalações ativas, carregamento de
/// finalizadas, filtros, busca e transições de status.
class EscalationsPresenter {
  final EscalationsRepository _repository = EscalationsRepository();

  EscalationsViewModel _viewModel = const EscalationsViewModel();
  EscalationsViewModel get viewModel => _viewModel;

  VoidCallback? onUpdate;

  StreamSubscription<List<EscalationModel>>? _activeSubscription;
  Timer? _debounceTimer;

  // MARK: - Inicialização

  /// Inicia stream real-time de escalações ativas.
  void startWatchingActive() {
    _viewModel = _viewModel.copyWith(isLoading: true);
    onUpdate?.call();

    debugPrint('[Escalations] Presenter.startWatchingActive chamado');

    _activeSubscription = _repository.watchActiveEscalations().listen(
      (escalations) {
        debugPrint(
          '[Escalations] Presenter recebeu ${escalations.length} escalações do stream',
        );
        for (final e in escalations) {
          debugPrint(
            '[Escalations]   -> ${e.uid}: status=${e.status.name}, '
            'customer=${e.customerName}',
          );
        }

        final pending = escalations
            .where((e) => e.status == EscalationStatus.pending)
            .length;
        final inProgress = escalations
            .where((e) => e.status == EscalationStatus.in_progress)
            .length;

        debugPrint(
          '[Escalations] Presenter: pending=$pending, inProgress=$inProgress',
        );

        _viewModel = _viewModel.copyWith(
          isLoading: false,
          activeEscalations: escalations,
          pendingCount: pending,
          inProgressCount: inProgress,
        );
        _applyFilters();

        debugPrint(
          '[Escalations] Presenter filteredActive: '
          '${_viewModel.filteredActive.length} itens',
        );
      },
      onError: (e, stackTrace) {
        debugPrint('[Escalations] Presenter ERRO no stream: $e');
        debugPrint('[Escalations] StackTrace: $stackTrace');
        _viewModel = _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar atendimentos',
        );
        onUpdate?.call();
      },
    );
  }

  /// Carrega escalações finalizadas (sob demanda, quando tab muda).
  Future<void> loadCompleted() async {
    _viewModel = _viewModel.copyWith(isLoadingCompleted: true);
    onUpdate?.call();

    final completed = await _repository.getCompleted();

    _viewModel = _viewModel.copyWith(
      isLoadingCompleted: false,
      completedEscalations: completed,
      filteredCompleted: completed,
    );
    _applyFilters();
  }

  // MARK: - Tabs e Filtros

  void setTab(EscalationTab tab) {
    _viewModel = _viewModel.copyWith(currentTab: tab);
    onUpdate?.call();

    // Carrega finalizados na primeira vez que muda de tab
    if (tab == EscalationTab.completed &&
        _viewModel.completedEscalations.isEmpty &&
        !_viewModel.isLoadingCompleted) {
      loadCompleted();
    }
  }

  void setActiveFilter(EscalationActiveFilter filter) {
    _viewModel = _viewModel.copyWith(activeFilter: filter);
    _applyFilters();
  }

  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _viewModel = _viewModel.copyWith(searchQuery: query);
      _applyFilters();
    });
  }

  void clearFilters() {
    _viewModel = _viewModel.copyWith(
      activeFilter: EscalationActiveFilter.all,
      searchQuery: '',
    );
    _applyFilters();
  }

  // MARK: - Filtragem

  void _applyFilters() {
    // Filtrar ativos
    var active = List<EscalationModel>.from(_viewModel.activeEscalations);

    // Filtro de status
    if (_viewModel.activeFilter != EscalationActiveFilter.all) {
      final target = _viewModel.activeFilter.escalationStatus;
      active = active.where((e) => e.status == target).toList();
    }

    // Busca
    if (_viewModel.searchQuery.isNotEmpty) {
      final q = _viewModel.searchQuery.toLowerCase();
      active = active.where((e) {
        return e.customerName.toLowerCase().contains(q) ||
            e.customerWhatsapp.contains(q) ||
            (e.reason?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Filtrar finalizados (busca)
    var completed = List<EscalationModel>.from(_viewModel.completedEscalations);
    if (_viewModel.searchQuery.isNotEmpty) {
      final q = _viewModel.searchQuery.toLowerCase();
      completed = completed.where((e) {
        return e.customerName.toLowerCase().contains(q) ||
            e.customerWhatsapp.contains(q);
      }).toList();
    }

    _viewModel = _viewModel.copyWith(
      filteredActive: active,
      filteredCompleted: completed,
    );
    onUpdate?.call();
  }

  // MARK: - Ações (Optimistic Updates)

  /// Assume um atendimento pendente.
  Future<bool> assumeEscalation(String escalationId, String customerId) async {
    final session = SessionManager.instance;
    final userId = session.currentUser!.uid;
    final userName = session.currentUser!.name;

    _viewModel = _viewModel.copyWith(actionInProgressId: escalationId);
    onUpdate?.call();

    final success = await _repository.assumeEscalation(
      escalationId,
      userId,
      userName,
      customerId,
    );

    _viewModel = _viewModel.copyWith(actionInProgressId: null);
    onUpdate?.call();

    return success;
  }

  /// Finaliza um atendimento em andamento.
  Future<bool> completeEscalation(
    String escalationId,
    String customerId, {
    String? notes,
  }) async {
    _viewModel = _viewModel.copyWith(actionInProgressId: escalationId);
    onUpdate?.call();

    final success = await _repository.completeEscalation(
      escalationId,
      customerId,
      notes: notes,
    );

    _viewModel = _viewModel.copyWith(actionInProgressId: null);
    onUpdate?.call();

    return success;
  }

  /// Atualiza notas do atendimento.
  Future<bool> updateNotes(String escalationId, String notes) async {
    return _repository.updateNotes(escalationId, notes);
  }

  // MARK: - Stream para Badge

  /// Stream da contagem de pendentes (para badge no menu).
  Stream<int> watchPendingCount() {
    return _repository.watchPendingCount();
  }

  // MARK: - Dispose

  void dispose() {
    _activeSubscription?.cancel();
    _debounceTimer?.cancel();
  }
}
