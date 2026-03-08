/// Status de uma venda.
enum SaleStatus {
  pending, // Pendente
  confirmed, // Confirmada
  cancelled; // Cancelada

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case SaleStatus.pending:
        return 'Pendente';
      case SaleStatus.confirmed:
        return 'Confirmada';
      case SaleStatus.cancelled:
        return 'Cancelada';
    }
  }

  /// Converte string para SaleStatus (padrão: pending).
  static SaleStatus fromString(String value) {
    return SaleStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SaleStatus.pending,
    );
  }
}
