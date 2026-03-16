/// Status de processamento do pedido (esteira Kanban).
///
/// Só entra nessa esteira após pagamento confirmado (SaleStatus.confirmed).
enum OrderStatus {
  awaiting_processing, // Aguardando processamento
  preparing, // Preparação/Embalagem
  ready_for_pickup, // Disponível para retirada/envio
  completed; // Concluído/Finalizado

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case OrderStatus.awaiting_processing:
        return 'Aguardando Processamento';
      case OrderStatus.preparing:
        return 'Preparação/Embalagem';
      case OrderStatus.ready_for_pickup:
        return 'Disponível para Retirada/Envio';
      case OrderStatus.completed:
        return 'Concluído';
    }
  }

  /// Label curta para card.
  String get shortLabel {
    switch (this) {
      case OrderStatus.awaiting_processing:
        return 'Aguardando';
      case OrderStatus.preparing:
        return 'Preparação';
      case OrderStatus.ready_for_pickup:
        return 'Retirada/Envio';
      case OrderStatus.completed:
        return 'Concluídos';
    }
  }

  /// Ícone representativo.
  String get emoji {
    switch (this) {
      case OrderStatus.awaiting_processing:
        return '⏳';
      case OrderStatus.preparing:
        return '📦';
      case OrderStatus.ready_for_pickup:
        return '🚚';
      case OrderStatus.completed:
        return '✅';
    }
  }

  /// Próximo status na esteira (null se for o último).
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.awaiting_processing:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready_for_pickup;
      case OrderStatus.ready_for_pickup:
        return OrderStatus.completed;
      case OrderStatus.completed:
        return null;
    }
  }

  /// Status anterior (null se for o primeiro).
  OrderStatus? get previous {
    switch (this) {
      case OrderStatus.awaiting_processing:
        return null;
      case OrderStatus.preparing:
        return OrderStatus.awaiting_processing;
      case OrderStatus.ready_for_pickup:
        return OrderStatus.preparing;
      case OrderStatus.completed:
        return OrderStatus.ready_for_pickup;
    }
  }

  /// Converte string para OrderStatus.
  /// Suporta valores legados (separating, packing, ready) para compatibilidade.
  static OrderStatus fromString(String value) {
    // Mapeamento de valores legados
    switch (value) {
      case 'separating':
        return OrderStatus.awaiting_processing;
      case 'packing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready_for_pickup;
    }
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.awaiting_processing,
    );
  }
}
