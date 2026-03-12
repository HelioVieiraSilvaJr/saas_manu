import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de produto.
///
/// Subcoleção: `tenants/{tenant_id}/products/{product_id}`
/// NÃO contém campo tenant_id (path NESTED).
class ProductModel {
  String uid;
  String name;
  String sku;
  double price;
  int stock;
  String? description;
  String? imageUrl;
  List<String> imageUrls;
  int mainImageIndex;
  bool isActive;
  DateTime createdAt;
  DateTime? updatedAt;

  ProductModel({
    required this.uid,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    this.description,
    this.imageUrl,
    this.imageUrls = const [],
    this.mainImageIndex = 0,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  /// URL da imagem principal (compatível com código legado).
  String? get mainImageUrl {
    if (imageUrls.isNotEmpty) {
      final idx = mainImageIndex.clamp(0, imageUrls.length - 1);
      return imageUrls[idx];
    }
    return imageUrl;
  }

  // MARK: - Factory

  static ProductModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Backward compat: migrate old image_url to imageUrls
    final List<String> urls = [];
    if (data['image_urls'] is List) {
      urls.addAll(
        (data['image_urls'] as List).whereType<String>().where(
          (u) => u.isNotEmpty,
        ),
      );
    } else if (data['image_url'] is String &&
        (data['image_url'] as String).isNotEmpty) {
      urls.add(data['image_url'] as String);
    }

    return ProductModel(
      uid: doc.id,
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      stock: (data['stock'] ?? 0) as int,
      description: data['description'],
      imageUrl: urls.isNotEmpty ? urls.first : null,
      imageUrls: urls,
      mainImageIndex: (data['main_image_index'] ?? 0) as int,
      isActive: data['is_active'] ?? true,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sku': sku,
      'price': price,
      'stock': stock,
      'description': description,
      'image_url': mainImageUrl,
      'image_urls': imageUrls,
      'main_image_index': mainImageIndex,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // MARK: - Helpers

  static ProductModel newModel() {
    return ProductModel(
      uid: '',
      name: '',
      sku: '',
      price: 0,
      stock: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  ProductModel copyWith({
    String? uid,
    String? name,
    String? sku,
    double? price,
    int? stock,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    int? mainImageIndex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      mainImageIndex: mainImageIndex ?? this.mainImageIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica se o estoque está baixo (< 10).
  bool get isLowStock => stock > 0 && stock < 10;

  /// Verifica se sem estoque.
  bool get isOutOfStock => stock == 0;

  /// Quantidade de itens no item_count (para vendas).
  int get itemCount => 1;
}
