import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../Commons/Models/ProductModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Utils/DataCache.dart';
import '../../Sources/SessionManager.dart';

/// Repositório de produtos.
///
/// Usa path NESTED: `tenants/{tenant_id}/products/`
/// Usa cache estático compartilhado entre Presenters.
class ProductsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Cache compartilhado entre todas as instâncias.
  static final DataCache<ProductModel> productsCache = DataCache<ProductModel>(
    ttl: const Duration(minutes: 5),
  );

  /// Registra limpeza de cache no SessionManager.
  // ignore: unused_field
  static final bool _registered = _register();
  static bool _register() {
    SessionManager.registerCacheClear(clearCache);
    return true;
  }

  /// Limpa cache (usar ao trocar tenant ou logout).
  static void clearCache() => productsCache.clear();

  String get _tenantId => SessionManager.instance.currentTenant!.uid;

  CollectionReference get _collection =>
      _firestore.collection('tenants').doc(_tenantId).collection('products');

  static String _normalizeSearchText(String value) {
    const accentsIn = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const accentsOut = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

    final buffer = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final accentIndex = accentsIn.indexOf(char);
      buffer.write(accentIndex >= 0 ? accentsOut[accentIndex] : char);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _buildSearchTokens(ProductModel product) {
    final sources = <String>[
      product.name,
      product.sku,
      product.category ?? '',
      product.color ?? '',
      product.size ?? '',
      product.description ?? '',
      ...product.tags,
    ];

    final tokens = <String>{};
    for (final source in sources) {
      final normalized = _normalizeSearchText(source);
      if (normalized.isEmpty) continue;

      for (final token in normalized.split(' ')) {
        if (token.length >= 2) {
          tokens.add(token);
        }
      }

      tokens.add(normalized);
    }

    return tokens.toList()..sort();
  }

  static Map<String, dynamic> _withSearchFields(
    ProductModel product,
    Map<String, dynamic> data,
  ) {
    final searchTokens = _buildSearchTokens(product);
    final searchText = _normalizeSearchText(
      [
        product.name,
        product.sku,
        product.category ?? '',
        product.color ?? '',
        product.size ?? '',
        product.description ?? '',
        ...product.tags,
      ].join(' '),
    );

    return {...data, 'search_tokens': searchTokens, 'search_text': searchText};
  }

  // MARK: - CRUD

  /// Busca todos os produtos. Usa cache se fresco.
  Future<List<ProductModel>> getAll({bool forceRefresh = false}) async {
    if (!forceRefresh && productsCache.isFresh) {
      return productsCache.data;
    }

    try {
      final snapshot = await _collection
          .orderBy('created_at', descending: true)
          .get();

      final products = snapshot.docs
          .map((doc) => ProductModel.fromDocumentSnapshot(doc))
          .toList();
      productsCache.set(products);
      return products;
    } catch (e) {
      AppLogger.error('Erro ao buscar produtos', error: e);
      if (productsCache.hasData) return productsCache.data;
      return [];
    }
  }

  /// Observa todos os produtos em tempo real.
  Stream<List<ProductModel>> watchAll() {
    return _collection.orderBy('created_at', descending: true).snapshots().map((
      snapshot,
    ) {
      final products = snapshot.docs
          .map((doc) => ProductModel.fromDocumentSnapshot(doc))
          .toList();
      productsCache.set(products);
      return products;
    });
  }

  /// Busca um produto pelo ID.
  Future<ProductModel?> getById(String productId) async {
    try {
      final doc = await _collection.doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromDocumentSnapshot(doc);
    } catch (e) {
      AppLogger.error('Erro ao buscar produto', error: e);
      return null;
    }
  }

  /// Cria um novo produto.
  Future<String?> create(ProductModel product) async {
    try {
      final docRef = await _collection.add(
        _withSearchFields(product, product.toMap()),
      );
      if (productsCache.hasData) {
        productsCache.add(product.copyWith(uid: docRef.id));
      }
      AppLogger.info('Produto criado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Erro ao criar produto', error: e);
      return null;
    }
  }

  /// Atualiza um produto existente.
  Future<bool> update(ProductModel product) async {
    try {
      final data = _withSearchFields(product, product.toMap());
      data['updated_at'] = Timestamp.fromDate(DateTime.now());
      await _collection.doc(product.uid).update(data);
      if (productsCache.hasData) {
        productsCache.updateWhere(
          (cached) => cached.uid == product.uid,
          product.copyWith(updatedAt: DateTime.now()),
        );
      }
      AppLogger.info('Produto atualizado: ${product.uid}');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar produto', error: e);
      return false;
    }
  }

  /// Deleta um produto permanentemente (hard delete).
  Future<bool> delete(String productId) async {
    try {
      await _collection.doc(productId).delete();
      if (productsCache.hasData) {
        productsCache.removeWhere((product) => product.uid == productId);
      }
      AppLogger.info('Produto deletado: $productId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao deletar produto', error: e);
      return false;
    }
  }

  // MARK: - Validações

  /// Verifica se um SKU já existe no tenant.
  Future<bool> skuExists(String sku, {String? excludeId}) async {
    try {
      final snapshot = await _collection
          .where('sku', isEqualTo: sku)
          .limit(2)
          .get();

      for (final doc in snapshot.docs) {
        if (doc.id != excludeId) return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Erro ao verificar SKU', error: e);
      return false;
    }
  }

  // MARK: - Estoque

  /// Decrementa o estoque de um produto.
  Future<bool> decrementStock(String productId, int quantity) async {
    try {
      final now = DateTime.now();
      await _collection.doc(productId).update({
        'stock': FieldValue.increment(-quantity),
        'updated_at': Timestamp.fromDate(now),
      });
      if (productsCache.hasData) {
        final current = productsCache.data
            .where((product) => product.uid == productId)
            .firstOrNull;
        if (current != null) {
          productsCache.updateWhere(
            (product) => product.uid == productId,
            current.copyWith(
              stock: (current.stock - quantity).clamp(0, current.stock),
              updatedAt: now,
            ),
          );
        }
      }
      return true;
    } catch (e) {
      AppLogger.error('Erro ao decrementar estoque', error: e);
      return false;
    }
  }

  /// Incrementa o estoque de um produto.
  Future<bool> incrementStock(String productId, int quantity) async {
    try {
      final now = DateTime.now();
      await _collection.doc(productId).update({
        'stock': FieldValue.increment(quantity),
        'updated_at': Timestamp.fromDate(now),
      });
      if (productsCache.hasData) {
        final current = productsCache.data
            .where((product) => product.uid == productId)
            .firstOrNull;
        if (current != null) {
          productsCache.updateWhere(
            (product) => product.uid == productId,
            current.copyWith(stock: current.stock + quantity, updatedAt: now),
          );
        }
      }
      return true;
    } catch (e) {
      AppLogger.error('Erro ao incrementar estoque', error: e);
      return false;
    }
  }

  // MARK: - Verificações

  /// Verifica se um produto tem vendas associadas.
  Future<bool> productHasSales(String productId) async {
    try {
      final salesCollection = _firestore
          .collection('tenants')
          .doc(_tenantId)
          .collection('sales');

      // Buscar vendas que contenham este produto nos items
      final snapshot = await salesCollection
          .where('item_product_ids', arrayContains: productId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Erro ao verificar vendas do produto', error: e);
      return false;
    }
  }

  // MARK: - Upload de Imagem

  /// Faz upload de uma imagem para o Firebase Storage.
  ///
  /// Path: `tenants/{tenant_id}/products/{product_id}/{timestamp}.jpg`
  Future<String?> uploadImage({
    required String productId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final extension = fileName.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path =
          'tenants/$_tenantId/products/$productId/$timestamp.$extension';

      final ref = _storage.ref().child(path);
      final mimeType = extension == 'jpg' ? 'image/jpeg' : 'image/$extension';
      final metadata = SettableMetadata(
        contentType: mimeType,
        cacheControl: 'public, max-age=31536000',
      );

      await ref.putData(imageBytes, metadata);
      final downloadUrl = await ref.getDownloadURL();

      AppLogger.info('Imagem uploaded: $path');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Erro ao fazer upload de imagem', error: e);
      return null;
    }
  }

  /// Remove a imagem antiga do Storage (se existir).
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      AppLogger.info('Imagem removida');
    } catch (e) {
      AppLogger.error('Erro ao remover imagem', error: e);
    }
  }

  /// Remove múltiplas imagens do Storage.
  Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }

  // MARK: - Contagem

  /// Retorna o total de produtos.
  Future<int> count() async {
    try {
      final snapshot = await _collection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar produtos', error: e);
      return 0;
    }
  }

  /// Retorna quantidade de produtos sem imagem.
  Future<int> countWithoutImage() async {
    try {
      final snapshotNull = await _collection
          .where('image_url', isNull: true)
          .count()
          .get();

      final snapshotEmpty = await _collection
          .where('image_url', isEqualTo: '')
          .count()
          .get();

      return (snapshotNull.count ?? 0) + (snapshotEmpty.count ?? 0);
    } catch (e) {
      AppLogger.error('Erro ao contar produtos sem imagem', error: e);
      return 0;
    }
  }
}
