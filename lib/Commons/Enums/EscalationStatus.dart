/// Status de um atendimento escalado.
///
/// Fluxo: pending → in_progress → completed
enum EscalationStatus {
  pending, // Aguardando atendente assumir
  in_progress, // Em atendimento por um humano
  completed; // Atendimento finalizado

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case EscalationStatus.pending:
        return 'Pendente';
      case EscalationStatus.in_progress:
        return 'Em Atendimento';
      case EscalationStatus.completed:
        return 'Finalizado';
    }
  }

  /// Label curta para badges.
  String get shortLabel {
    switch (this) {
      case EscalationStatus.pending:
        return 'Pendente';
      case EscalationStatus.in_progress:
        return 'Atendendo';
      case EscalationStatus.completed:
        return 'Finalizado';
    }
  }

  /// Ícone representativo.
  String get emoji {
    switch (this) {
      case EscalationStatus.pending:
        return '🔔';
      case EscalationStatus.in_progress:
        return '💬';
      case EscalationStatus.completed:
        return '✅';
    }
  }

  /// Próximo status (null se for o último).
  EscalationStatus? get next {
    switch (this) {
      case EscalationStatus.pending:
        return EscalationStatus.in_progress;
      case EscalationStatus.in_progress:
        return EscalationStatus.completed;
      case EscalationStatus.completed:
        return null;
    }
  }

  /// Converte string para EscalationStatus (padrão: pending).
  static EscalationStatus fromString(String value) {
    return EscalationStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => EscalationStatus.pending,
    );
  }
}
