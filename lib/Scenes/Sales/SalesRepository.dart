import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Enums/SaleStatus.dart';
import '../../Commons/Enums/OrderStatus.dart';
import '../../Commons/Models/CustomerModel.dart';
import '../../Commons/Models/ProductModel.dart';
import '../../Commons/Models/SaleModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Utils/DataCache.dart';
import '../../Sources/SessionManager.dart';
import '../Customers/CustomersRepository.dart';
import '../Products/ProductsRepository.dart';

/// Repository do módulo Vendas.
///
/// Acessa `tenants/{tenant_id}/sales/`.
/// Usa cache estático compartilhado entre Presenters.
class SalesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache compartilhado entre todas as instâncias (singleton por app).
  static final DataCache<SaleModel> salesCache = DataCache<SaleModel>(
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
  static void clearCache() => salesCache.clear();

  /// Referência da subcoleção sales do tenant ativo.
  CollectionReference<Map<String, dynamic>> get _collection {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants/$tenantId/sales');
  }

  CollectionReference<Map<String, dynamic>> get _customersCollection {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants/$tenantId/customers');
  }

  CollectionReference<Map<String, dynamic>> get _productsCollection {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants/$tenantId/products');
  }

  // MARK: - CRUD

  /// Busca todas as vendas. Usa cache se fresco.
  Future<List<SaleModel>> getAll({bool forceRefresh = false}) async {
    if (!forceRefresh && salesCache.isFresh) {
      return salesCache.data;
    }

    try {
      final snapshot = await _collection
          .orderBy('created_at', descending: true)
          .get();
      final sales = snapshot.docs
          .map((doc) => SaleModel.fromDocumentSnapshot(doc))
          .toList();
      salesCache.set(sales);
      return sales;
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas', error: e);
      // Retorna dados stale se disponíveis
      if (salesCache.hasData) return salesCache.data;
      return [];
    }
  }

  /// Busca uma venda por ID.
  Future<SaleModel?> getById(String saleId) async {
    try {
      final doc = await _collection.doc(saleId).get();
      if (doc.exists) {
        return SaleModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Erro ao buscar venda', error: e);
      return null;
    }
  }

  /// Cria uma nova venda. Retorna o ID gerado.
  Future<String?> create(SaleModel sale) async {
    try {
      final docRef = await _collection.add(sale.toMap());
      if (salesCache.hasData) {
        salesCache.add(sale.copyWith(uid: docRef.id));
      }
      AppLogger.info('Venda criada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Erro ao criar venda', error: e);
      return null;
    }
  }

  /// Cria uma venda manual e aplica todos os efeitos colaterais em transação.
  Future<String> createConfirmedManualSaleTransaction(SaleModel sale) async {
    final saleRef = _collection.doc();
    final now = DateTime.now();
    final createdSale = sale.copyWith(uid: saleRef.id);

    final quantitiesByProduct = <String, int>{};
    final namesByProduct = <String, String>{};
    for (final item in sale.items) {
      quantitiesByProduct.update(
        item.productId,
        (current) => current + item.quantity,
        ifAbsent: () => item.quantity,
      );
      namesByProduct[item.productId] = item.productName;
    }

    final updatedProducts = <String, ProductModel>{};
    CustomerModel? updatedCustomer;

    try {
      await _firestore.runTransaction((transaction) async {
        final customerRef = _customersCollection.doc(sale.customerId);
        final customerSnapshot = await transaction.get(customerRef);

        if (!customerSnapshot.exists) {
          throw Exception('Cliente não encontrado.');
        }

        final currentCustomer = CustomerModel.fromDocumentSnapshot(
          customerSnapshot,
        );
        updatedCustomer = currentCustomer.copyWith(
          purchaseCount: (currentCustomer.purchaseCount ?? 0) + 1,
          totalSpent: (currentCustomer.totalSpent ?? 0) + sale.total,
          lastPurchaseAt: now,
          updatedAt: now,
        );

        for (final entry in quantitiesByProduct.entries) {
          final productId = entry.key;
          final quantity = entry.value;
          final productRef = _productsCollection.doc(productId);
          final productSnapshot = await transaction.get(productRef);

          if (!productSnapshot.exists) {
            throw Exception(
              'Produto não encontrado: ${namesByProduct[productId] ?? productId}.',
            );
          }

          final currentProduct = ProductModel.fromDocumentSnapshot(
            productSnapshot,
          );

          if (!currentProduct.isActive) {
            throw Exception('Produto inativo: ${currentProduct.name}.');
          }

          if (currentProduct.stock < quantity) {
            throw Exception(
              'Estoque insuficiente para ${currentProduct.name}. Disponível: ${currentProduct.stock} un.',
            );
          }

          final updatedProduct = currentProduct.copyWith(
            stock: currentProduct.stock - quantity,
            updatedAt: now,
          );
          updatedProducts[productId] = updatedProduct;

          transaction.update(productRef, {
            'stock': updatedProduct.stock,
            'updated_at': Timestamp.fromDate(now),
          });
        }

        transaction.set(saleRef, createdSale.toMap());
        transaction.update(customerRef, {
          'purchase_count': updatedCustomer!.purchaseCount,
          'total_spent': updatedCustomer!.totalSpent,
          'last_purchase_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        });
      });

      if (salesCache.hasData) {
        salesCache.add(createdSale);
      }

      if (CustomersRepository.customersCache.hasData &&
          updatedCustomer != null) {
        CustomersRepository.customersCache.updateWhere(
          (customer) => customer.uid == updatedCustomer!.uid,
          updatedCustomer!,
        );
      }

      if (ProductsRepository.productsCache.hasData) {
        for (final updatedProduct in updatedProducts.values) {
          ProductsRepository.productsCache.updateWhere(
            (product) => product.uid == updatedProduct.uid,
            updatedProduct,
          );
        }
      }

      AppLogger.info('Venda manual transacional criada: ${saleRef.id}');
      return saleRef.id;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erro ao criar venda manual transacional',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Atualiza uma venda existente.
  Future<bool> update(SaleModel sale) async {
    try {
      await _collection.doc(sale.uid).update(sale.toMap());
      if (salesCache.hasData) {
        salesCache.updateWhere((cached) => cached.uid == sale.uid, sale);
      }
      AppLogger.info('Venda atualizada: ${sale.uid}');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar venda', error: e);
      return false;
    }
  }

  /// Deleta uma venda permanentemente.
  Future<bool> delete(String saleId) async {
    try {
      await _collection.doc(saleId).delete();
      if (salesCache.hasData) {
        salesCache.removeWhere((sale) => sale.uid == saleId);
      }
      AppLogger.info('Venda deletada: $saleId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao deletar venda', error: e);
      return false;
    }
  }

  // MARK: - Status

  /// Atualiza o status de uma venda.
  Future<bool> updateStatus(String saleId, SaleStatus newStatus) async {
    try {
      final now = DateTime.now();
      await _collection.doc(saleId).update({
        'status': newStatus.name,
        'updated_at': Timestamp.fromDate(now),
      });
      if (salesCache.hasData) {
        final current = salesCache.data
            .where((sale) => sale.uid == saleId)
            .firstOrNull;
        if (current != null) {
          salesCache.updateWhere(
            (sale) => sale.uid == saleId,
            current.copyWith(status: newStatus, updatedAt: now),
          );
        }
      }
      AppLogger.info('Status venda $saleId alterado para ${newStatus.name}');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar status da venda', error: e);
      return false;
    }
  }

  // MARK: - Fluxo de Pagamento

  /// Marca cobrança como enviada.
  Future<bool> sendPaymentRequest(String saleId) async {
    try {
      final now = DateTime.now();
      await _collection.doc(saleId).update({
        'status': SaleStatus.payment_sent.name,
        'payment_requested_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      });
      if (salesCache.hasData) {
        final current = salesCache.data
            .where((sale) => sale.uid == saleId)
            .firstOrNull;
        if (current != null) {
          salesCache.updateWhere(
            (sale) => sale.uid == saleId,
            current.copyWith(
              status: SaleStatus.payment_sent,
              paymentRequestedAt: now,
              updatedAt: now,
            ),
          );
        }
      }
      AppLogger.info('Cobrança enviada para venda $saleId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao enviar cobrança', error: e);
      return false;
    }
  }

  /// Confirma pagamento e inicia esteira de pedidos.
  Future<bool> confirmPayment(String saleId) async {
    try {
      final now = DateTime.now();
      await _collection.doc(saleId).update({
        'status': SaleStatus.confirmed.name,
        'order_status': OrderStatus.awaiting_processing.name,
        'payment_confirmed_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      });
      if (salesCache.hasData) {
        final current = salesCache.data
            .where((sale) => sale.uid == saleId)
            .firstOrNull;
        if (current != null) {
          salesCache.updateWhere(
            (sale) => sale.uid == saleId,
            current.copyWith(
              status: SaleStatus.confirmed,
              orderStatus: OrderStatus.awaiting_processing,
              paymentConfirmedAt: now,
              updatedAt: now,
            ),
          );
        }
      }
      AppLogger.info('Pagamento confirmado para venda $saleId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao confirmar pagamento', error: e);
      return false;
    }
  }

  /// Cancela venda.
  Future<bool> cancelSale(String saleId) async {
    try {
      final now = DateTime.now();
      await _collection.doc(saleId).update({
        'status': SaleStatus.cancelled.name,
        'updated_at': Timestamp.fromDate(now),
      });
      if (salesCache.hasData) {
        final current = salesCache.data
            .where((sale) => sale.uid == saleId)
            .firstOrNull;
        if (current != null) {
          salesCache.updateWhere(
            (sale) => sale.uid == saleId,
            current.copyWith(status: SaleStatus.cancelled, updatedAt: now),
          );
        }
      }
      AppLogger.info('Venda $saleId cancelada');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao cancelar venda', error: e);
      return false;
    }
  }

  // MARK: - Esteira de Pedidos (Kanban)

  /// Atualiza o status do pedido na esteira.
  Future<bool> updateOrderStatus(String saleId, OrderStatus newStatus) async {
    try {
      final now = DateTime.now();
      await _collection.doc(saleId).update({
        'order_status': newStatus.name,
        'updated_at': Timestamp.fromDate(now),
      });
      if (salesCache.hasData) {
        final current = salesCache.data
            .where((sale) => sale.uid == saleId)
            .firstOrNull;
        if (current != null) {
          salesCache.updateWhere(
            (sale) => sale.uid == saleId,
            current.copyWith(orderStatus: newStatus, updatedAt: now),
          );
        }
      }
      AppLogger.info('Pedido $saleId movido para ${newStatus.name}');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar status do pedido', error: e);
      return false;
    }
  }

  /// Busca pedidos confirmados (para o Kanban). Usa cache se disponível.
  Future<List<SaleModel>> getConfirmedOrders({
    bool forceRefresh = false,
  }) async {
    // Se cache de vendas está fresco, filtra localmente
    if (!forceRefresh && salesCache.isFresh) {
      return salesCache.data
          .where((s) => s.status == SaleStatus.confirmed)
          .toList();
    }

    try {
      final snapshot = await _collection
          .where('status', isEqualTo: SaleStatus.confirmed.name)
          .orderBy('payment_confirmed_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => SaleModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar pedidos confirmados', error: e);
      return [];
    }
  }

  /// Stream de pedidos confirmados (tempo real para o Kanban).
  Stream<List<SaleModel>> watchConfirmedOrders() {
    return _collection
        .where('status', isEqualTo: SaleStatus.confirmed.name)
        .orderBy('payment_confirmed_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SaleModel.fromDocumentSnapshot(doc))
              .toList(),
        );
  }

  // MARK: - Consultas

  /// Busca vendas por período.
  Future<List<SaleModel>> getByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _collection
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => SaleModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas por período', error: e);
      return [];
    }
  }

  /// Busca vendas de hoje.
  Future<List<SaleModel>> getTodaySales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getByDateRange(start: startOfDay, end: now);
  }

  /// Busca vendas do mês atual.
  Future<List<SaleModel>> getCurrentMonthSales() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getByDateRange(start: startOfMonth, end: now);
  }

  /// Total de vendas.
  Future<int> count() async {
    try {
      final snapshot = await _collection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar vendas', error: e);
      return 0;
    }
  }

  // MARK: - Stream (Vendas Automáticas)

  /// Stream para detectar novas vendas automáticas em tempo real.
  Stream<List<SaleModel>> watchNewAutomatedSales() {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    return _collection
        .where('created_at', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
        .where('source', isEqualTo: 'whatsapp_automation')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SaleModel.fromDocumentSnapshot(doc))
              .toList(),
        );
  }

  // MARK: - Streams para Badges e Real-Time

  /// Stream de contagem de vendas pendentes (para badge no menu "Vendas").
  Stream<int> watchPendingSalesCount() {
    return _collection
        .where('status', isEqualTo: SaleStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream de contagem de pedidos ativos não concluídos (para badge no menu "Pedidos").
  Stream<int> watchActiveOrdersCount() {
    return _collection
        .where('status', isEqualTo: SaleStatus.confirmed.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.where((doc) {
            final orderStatus = doc.data()['order_status'];
            return orderStatus != null &&
                orderStatus != OrderStatus.completed.name;
          }).length,
        );
  }

  /// Stream de todas as vendas em tempo real (para SalesListPage).
  Stream<List<SaleModel>> watchAllSales() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SaleModel.fromDocumentSnapshot(doc))
              .toList(),
        );
  }

  // MARK: - Estatísticas

  /// Calcula total de vendas em uma lista (soma de totais).
  double calculateTotalRevenue(List<SaleModel> sales) {
    return sales
        .where((s) => s.status != SaleStatus.cancelled)
        .fold(0.0, (sum, sale) => sum + sale.total);
  }

  /// Conta vendas não canceladas.
  int countActiveSales(List<SaleModel> sales) {
    return sales.where((s) => s.status != SaleStatus.cancelled).length;
  }

  /// Calcula ticket médio.
  double calculateAverageTicket(List<SaleModel> sales) {
    final activeSales = sales
        .where((s) => s.status != SaleStatus.cancelled)
        .toList();
    if (activeSales.isEmpty) return 0;
    final total = activeSales.fold(0.0, (sum, sale) => sum + sale.total);
    return total / activeSales.length;
  }
}
