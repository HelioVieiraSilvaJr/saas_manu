import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Models/CustomerModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/SessionManager.dart';

/// Repository do módulo Clientes.
///
/// Acessa `tenants/{tenant_id}/customers/`.
class CustomersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referência da subcoleção customers do tenant ativo.
  CollectionReference<Map<String, dynamic>> get _collection {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants/$tenantId/customers');
  }

  // MARK: - CRUD

  /// Busca todos os clientes.
  Future<List<CustomerModel>> getAll() async {
    try {
      final snapshot = await _collection
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => CustomerModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar clientes', error: e);
      return [];
    }
  }

  /// Busca um cliente por ID.
  Future<CustomerModel?> getById(String customerId) async {
    try {
      final doc = await _collection.doc(customerId).get();
      if (doc.exists) {
        return CustomerModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Erro ao buscar cliente', error: e);
      return null;
    }
  }

  /// Cria um novo cliente. Retorna o ID gerado.
  Future<String?> create(CustomerModel customer) async {
    try {
      final docRef = await _collection.add(customer.toMap());
      AppLogger.info('Cliente criado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Erro ao criar cliente', error: e);
      return null;
    }
  }

  /// Atualiza um cliente existente.
  Future<bool> update(CustomerModel customer) async {
    try {
      await _collection.doc(customer.uid).update(customer.toMap());
      AppLogger.info('Cliente atualizado: ${customer.uid}');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar cliente', error: e);
      return false;
    }
  }

  /// Deleta um cliente permanentemente.
  Future<bool> delete(String customerId) async {
    try {
      await _collection.doc(customerId).delete();
      AppLogger.info('Cliente deletado: $customerId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao deletar cliente', error: e);
      return false;
    }
  }

  // MARK: - Validação

  /// Verifica se um WhatsApp já existe no tenant.
  Future<bool> whatsappExists(String whatsapp, {String? excludeId}) async {
    try {
      final snapshot = await _collection
          .where('whatsapp', isEqualTo: whatsapp)
          .get();

      if (excludeId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Erro ao verificar WhatsApp', error: e);
      return false;
    }
  }

  // MARK: - Contagens

  /// Total de clientes ativos.
  Future<int> count() async {
    try {
      final snapshot = await _collection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar clientes', error: e);
      return 0;
    }
  }

  // MARK: - Vendas do Cliente

  /// Verifica se o cliente tem vendas registradas usando campo denormalizado.
  bool customerHasSales(CustomerModel customer) {
    return customer.hasPurchases;
  }

  /// Atualiza estatísticas de compra do cliente (após nova venda).
  Future<void> updatePurchaseStats(String customerId, double saleTotal) async {
    try {
      await _collection.doc(customerId).update({
        'purchase_count': FieldValue.increment(1),
        'total_spent': FieldValue.increment(saleTotal),
        'last_purchase_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Purchase stats atualizadas: $customerId');
    } catch (e) {
      AppLogger.error('Erro ao atualizar purchase stats', error: e);
    }
  }

  /// Decrementa estatísticas de compra do cliente (após exclusão de venda).
  Future<void> decrementPurchaseStats(
    String customerId,
    double saleTotal,
  ) async {
    try {
      await _collection.doc(customerId).update({
        'purchase_count': FieldValue.increment(-1),
        'total_spent': FieldValue.increment(-saleTotal),
        'updated_at': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Purchase stats decrementadas: $customerId');
    } catch (e) {
      AppLogger.error('Erro ao decrementar purchase stats', error: e);
    }
  }

  /// Busca as últimas vendas de um cliente (para detalhes).
  Future<List<Map<String, dynamic>>> getRecentSales(
    String customerId, {
    int limit = 5,
  }) async {
    try {
      final tenantId = SessionManager.instance.currentTenant!.uid;
      final snapshot = await _firestore
          .collection('tenants/$tenantId/sales')
          .where('customer_id', isEqualTo: customerId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas do cliente', error: e);
      return [];
    }
  }
}
