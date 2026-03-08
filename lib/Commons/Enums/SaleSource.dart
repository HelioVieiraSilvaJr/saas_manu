/// Origem de uma venda.
enum SaleSource {
  manual, // Venda criada manualmente
  whatsapp_automation; // Venda via automação WhatsApp/n8n

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case SaleSource.manual:
        return 'Manual';
      case SaleSource.whatsapp_automation:
        return 'WhatsApp Bot';
    }
  }

  /// Converte string para SaleSource (padrão: manual).
  static SaleSource fromString(String value) {
    return SaleSource.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SaleSource.manual,
    );
  }
}
