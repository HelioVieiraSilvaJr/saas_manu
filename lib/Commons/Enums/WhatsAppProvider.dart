/// Provider de WhatsApp conectado ao tenant.
enum WhatsAppProvider {
  evolution,
  baileys,
  custom,
  unknown;

  String get label {
    switch (this) {
      case WhatsAppProvider.evolution:
        return 'Evolution API';
      case WhatsAppProvider.baileys:
        return 'Baileys';
      case WhatsAppProvider.custom:
        return 'Custom';
      case WhatsAppProvider.unknown:
        return 'Nao definido';
    }
  }

  static WhatsAppProvider fromString(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'evolution':
      case 'evolution_api':
      case 'evolution-api':
        return WhatsAppProvider.evolution;
      case 'baileys':
        return WhatsAppProvider.baileys;
      case 'custom':
        return WhatsAppProvider.custom;
      default:
        return WhatsAppProvider.unknown;
    }
  }
}
