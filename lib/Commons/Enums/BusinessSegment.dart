/// Segmentos principais de negocio para especializacao comercial da IA.
enum BusinessSegment {
  unassigned,
  fashion,
  food,
  electronics,
  beauty,
  homeDecor,
  services,
  other;

  /// Label para exibicao na UI.
  String get label {
    switch (this) {
      case BusinessSegment.unassigned:
        return 'Nao definido';
      case BusinessSegment.fashion:
        return 'Moda';
      case BusinessSegment.food:
        return 'Alimentacao';
      case BusinessSegment.electronics:
        return 'Eletronicos';
      case BusinessSegment.beauty:
        return 'Beleza';
      case BusinessSegment.homeDecor:
        return 'Casa e Decoracao';
      case BusinessSegment.services:
        return 'Servicos';
      case BusinessSegment.other:
        return 'Outro';
    }
  }

  /// Conversao tolerante para dados legados.
  static BusinessSegment fromString(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'fashion':
      case 'moda':
      case 'roupas':
        return BusinessSegment.fashion;
      case 'food':
      case 'alimentacao':
      case 'comida':
        return BusinessSegment.food;
      case 'electronics':
      case 'eletronicos':
      case 'eletronico':
        return BusinessSegment.electronics;
      case 'beauty':
      case 'beleza':
      case 'cosmeticos':
        return BusinessSegment.beauty;
      case 'home_decor':
      case 'home decor':
      case 'casa':
      case 'decoracao':
        return BusinessSegment.homeDecor;
      case 'services':
      case 'servicos':
      case 'servico':
        return BusinessSegment.services;
      case 'other':
      case 'outro':
        return BusinessSegment.other;
      default:
        return BusinessSegment.unassigned;
    }
  }
}
