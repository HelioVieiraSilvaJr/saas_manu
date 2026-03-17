/// Período/ciclo do plano do tenant.
enum PlanPeriod {
  trial,
  monthly,
  quarterly;

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case PlanPeriod.trial:
        return 'Trial';
      case PlanPeriod.monthly:
        return 'Mensal';
      case PlanPeriod.quarterly:
        return 'Trimestral';
    }
  }

  /// Descrição com detalhes do período.
  String get description {
    switch (this) {
      case PlanPeriod.trial:
        return '30 dias grátis para teste';
      case PlanPeriod.monthly:
        return 'Renovação a cada 30 dias';
      case PlanPeriod.quarterly:
        return 'Renovação a cada 90 dias';
    }
  }

  /// Duração em dias do ciclo.
  int get durationDays {
    switch (this) {
      case PlanPeriod.trial:
        return 30;
      case PlanPeriod.monthly:
        return 30;
      case PlanPeriod.quarterly:
        return 90;
    }
  }

  /// Se é um plano pago.
  bool get isPaid => this != PlanPeriod.trial;

  /// Converte string para PlanPeriod (padrão: trial).
  static PlanPeriod fromString(String value) {
    return PlanPeriod.values.firstWhere(
      (p) => p.name == value,
      orElse: () => PlanPeriod.trial,
    );
  }
}
