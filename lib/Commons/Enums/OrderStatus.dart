/// Status de processamento do pedido (esteira Kanban).
///
/// Só entra nessa esteira após pagamento confirmado (SaleStatus.confirmed).
enum OrderStatus {
  separating, // Separando produtos
  packing, // Embalando
  ready, // Pronto para envio/retirada
  completed; // Concluído/Entregue

  /// Label para exibição na UI.
  String get label {
    switch (this) {
      case OrderStatus.separating:
        return 'Separando';
      case OrderStatus.packing:
        return 'Embalando';
      case OrderStatus.ready:
        return 'Pronto';
      case OrderStatus.completed:
        return 'Concluído';
    }
  }

  /// Label curta para card.
  String get shortLabel {
    switch (this) {
      case OrderStatus.separating:
        return 'Separação';
      case OrderStatus.packing:
        return 'Embalagem';
      case OrderStatus.ready:
        return 'Envio/Retirada';
      case OrderStatus.completed:
        return 'Concluídos';
    }
  }

  /// Ícone representativo.
  String get emoji {
    switch (this) {
      case OrderStatus.separating:
        return '📦';
      case OrderStatus.packing:
        return '🎁';
      case OrderStatus.ready:
        return '🚚';
      case OrderStatus.completed:
        return '✅';
    }
  }

  /// Próximo status na esteira (null se for o último).
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.separating:
        return OrderStatus.packing;
      case OrderStatus.packing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.completed;
      case OrderStatus.completed:
        return null;
    }
  }

  /// Status anterior (null se for o primeiro).
  OrderStatus? get previous {
    switch (this) {
      case OrderStatus.separating:
        return null;
      case OrderStatus.packing:
        return OrderStatus.separating;
      case OrderStatus.ready:
        return OrderStatus.packing;
      case OrderStatus.completed:
        return OrderStatus.ready;
    }
  }

  /// Converte string para OrderStatus (padrão: separating).
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.separating,
    );
  }
}
