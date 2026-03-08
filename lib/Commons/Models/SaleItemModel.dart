/// Modelo de item de venda.
///
/// Cada item representa um produto vendido com sua quantidade e preço.
/// Armazenado inline dentro do SaleModel (array no Firestore).
class SaleItemModel {
  String productId;
  String productName;
  int quantity;
  double unitPrice;
  double subtotal;

  SaleItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  // MARK: - Factory

  static SaleItemModel fromMap(Map<String, dynamic> data) {
    return SaleItemModel(
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      quantity: (data['quantity'] ?? 0) as int,
      unitPrice: (data['unit_price'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  // MARK: - Helpers

  SaleItemModel copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? subtotal,
  }) {
    return SaleItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
