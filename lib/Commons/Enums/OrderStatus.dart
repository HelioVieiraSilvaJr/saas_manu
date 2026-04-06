/// Status de processamento do pedido (esteira Kanban).
///
/// Só entra nessa esteira após pagamento confirmado (SaleStatus.confirmed).
enum OrderStatus {
  awaiting_processing, // Aguardando processamento
  preparing, // Preparando
  packing, // Embalando
  awaiting_pickup, // Aguardando retirada
  ready_for_shipping, // Pronto para envio/retirada
  shipped, // Enviado
  completed; // Concluído/Finalizado

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case OrderStatus.awaiting_processing:
        return 'Aguardando';
      case OrderStatus.preparing:
        return 'Preparando';
      case OrderStatus.packing:
        return 'Embalando';
      case OrderStatus.awaiting_pickup:
        return 'Aguardando Retirada';
      case OrderStatus.ready_for_shipping:
        return 'Pronto para Envio';
      case OrderStatus.shipped:
        return 'Enviado';
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
      case OrderStatus.packing:
        return 'Embalando';
      case OrderStatus.awaiting_pickup:
        return 'Retirada';
      case OrderStatus.ready_for_shipping:
        return 'Pronto';
      case OrderStatus.shipped:
        return 'Enviado';
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
        return '🧰';
      case OrderStatus.packing:
        return '📦';
      case OrderStatus.awaiting_pickup:
        return '🏬';
      case OrderStatus.ready_for_shipping:
        return '🚚';
      case OrderStatus.shipped:
        return '🛵';
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
        return OrderStatus.packing;
      case OrderStatus.packing:
        return OrderStatus.awaiting_pickup;
      case OrderStatus.awaiting_pickup:
        return OrderStatus.ready_for_shipping;
      case OrderStatus.ready_for_shipping:
        return OrderStatus.shipped;
      case OrderStatus.shipped:
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
      case OrderStatus.packing:
        return OrderStatus.preparing;
      case OrderStatus.awaiting_pickup:
        return OrderStatus.packing;
      case OrderStatus.ready_for_shipping:
        return OrderStatus.awaiting_pickup;
      case OrderStatus.shipped:
        return OrderStatus.ready_for_shipping;
      case OrderStatus.completed:
        return OrderStatus.shipped;
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
        return OrderStatus.packing;
      case 'awaiting_pickup':
        return OrderStatus.awaiting_pickup;
      case 'ready':
      case 'ready_for_pickup':
        return OrderStatus.ready_for_shipping;
    }
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.awaiting_processing,
    );
  }

  static const List<OrderStatus> configurableStatuses = [
    OrderStatus.awaiting_processing,
    OrderStatus.preparing,
    OrderStatus.packing,
    OrderStatus.awaiting_pickup,
    OrderStatus.ready_for_shipping,
    OrderStatus.shipped,
    OrderStatus.completed,
  ];

  static const List<OrderStatus> defaultVisibleStatuses = [
    OrderStatus.awaiting_processing,
    OrderStatus.preparing,
    OrderStatus.ready_for_shipping,
    OrderStatus.shipped,
    OrderStatus.completed,
  ];
}
