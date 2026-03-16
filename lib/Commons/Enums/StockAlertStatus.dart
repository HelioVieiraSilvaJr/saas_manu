/// Status de um aviso de estoque.
///
/// Fluxo: pending → notified (ou pending → dismissed)
enum StockAlertStatus {
  pending, // Aguardando reposição de estoque
  notified, // Cliente foi notificado da reposição
  dismissed; // Aviso encerrado manualmente

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case StockAlertStatus.pending:
        return 'Aguardando';
      case StockAlertStatus.notified:
        return 'Notificado';
      case StockAlertStatus.dismissed:
        return 'Encerrado';
    }
  }

  /// Label curta para badges.
  String get shortLabel {
    switch (this) {
      case StockAlertStatus.pending:
        return 'Aguardando';
      case StockAlertStatus.notified:
        return 'Notificado';
      case StockAlertStatus.dismissed:
        return 'Encerrado';
    }
  }

  /// Ícone representativo.
  String get emoji {
    switch (this) {
      case StockAlertStatus.pending:
        return '🔔';
      case StockAlertStatus.notified:
        return '✅';
      case StockAlertStatus.dismissed:
        return '🚫';
    }
  }

  /// Converte string para StockAlertStatus (padrão: pending).
  static StockAlertStatus fromString(String value) {
    return StockAlertStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => StockAlertStatus.pending,
    );
  }
}
