import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../Commons/Models/ProductModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/SessionManager.dart';

/// Repositório de produtos.
///
/// Usa path NESTED: `tenants/{tenant_id}/products/`
class ProductsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _tenantId => SessionManager.instance.currentTenant!.uid;

  CollectionReference get _collection =>
      _firestore.collection('tenants').doc(_tenantId).collection('products');

  // MARK: - CRUD

  /// Busca todos os produtos do tenant.
  Future<List<ProductModel>> getAll() async {
    try {
      final snapshot = await _collection
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar produtos', error: e);
      return [];
    }
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
      final docRef = await _collection.add(product.toMap());
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
      final data = product.toMap();
      data['updated_at'] = Timestamp.fromDate(DateTime.now());
      await _collection.doc(product.uid).update(data);
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
      await _collection.doc(productId).update({
        'stock': FieldValue.increment(-quantity),
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      AppLogger.error('Erro ao decrementar estoque', error: e);
      return false;
    }
  }

  /// Incrementa o estoque de um produto.
  Future<bool> incrementStock(String productId, int quantity) async {
    try {
      await _collection.doc(productId).update({
        'stock': FieldValue.increment(quantity),
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
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
