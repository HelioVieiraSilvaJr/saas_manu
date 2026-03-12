/// Status de uma venda (ciclo de pagamento).
enum SaleStatus {
  pending, // Aguardando ação
  payment_sent, // Cobrança enviada ao cliente
  confirmed, // Pagamento confirmado → entra no Kanban
  cancelled; // Cancelada

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case SaleStatus.pending:
        return 'Pendente';
      case SaleStatus.payment_sent:
        return 'Cobrança Enviada';
      case SaleStatus.confirmed:
        return 'Pago';
      case SaleStatus.cancelled:
        return 'Cancelada';
    }
  }

  /// Ícone representativo do status.
  String get icon {
    switch (this) {
      case SaleStatus.pending:
        return '⏳';
      case SaleStatus.payment_sent:
        return '📤';
      case SaleStatus.confirmed:
        return '✅';
      case SaleStatus.cancelled:
        return '❌';
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
