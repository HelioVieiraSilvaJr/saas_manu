import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Enums/StockAlertStatus.dart';
import '../../Commons/Models/StockAlertGroupModel.dart';
import '../../Commons/Models/StockAlertModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Utils/DataCache.dart';
import '../../Sources/BackendApi.dart';
import '../../Sources/SessionManager.dart';

/// Repository do módulo Avisos de Estoque.
///
/// Acessa `tenants/{tenant_id}/stockAlerts/`.
/// Usa cache estático compartilhado entre Presenters.
class StockAlertsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache compartilhado entre todas as instâncias.
  static final DataCache<StockAlertModel> stockAlertsCache =
      DataCache<StockAlertModel>(ttl: const Duration(minutes: 5));

  /// Registra limpeza de cache no SessionManager.
  // ignore: unused_field
  static final bool _registered = _register();
  static bool _register() {
    SessionManager.registerCacheClear(clearCache);
    return true;
  }

  /// Limpa cache (usar ao trocar tenant ou logout).
  static void clearCache() => stockAlertsCache.clear();

  /// Referência da subcoleção stockAlerts do tenant ativo.
  CollectionReference<Map<String, dynamic>> get _collection {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants/$tenantId/stockAlerts');
  }

  String get _tenantId => SessionManager.instance.currentTenant!.uid;

  static List<StockAlertGroupModel> groupAlertsByProduct(
    List<StockAlertModel> alerts,
  ) {
    final grouped = <String, List<StockAlertModel>>{};
    for (final alert in alerts) {
      grouped.putIfAbsent(alert.productId, () => []).add(alert);
    }

    final result = grouped.entries.map((entry) {
      final first = entry.value.first;
      final alertsForProduct = List<StockAlertModel>.from(entry.value)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return StockAlertGroupModel(
        productId: entry.key,
        productName: first.productName,
        alerts: alertsForProduct,
      );
    }).toList();

    result.sort((a, b) {
      final customerDiff = b.customerCount.compareTo(a.customerCount);
      if (customerDiff != 0) return customerDiff;
      return a.oldestCreatedAt.compareTo(b.oldestCreatedAt);
    });

    return result;
  }

  // MARK: - Streams (Real-Time)

  /// Stream de avisos pendentes individuais.
  Stream<List<StockAlertModel>> watchPendingAlerts() {
    return _collection
        .where('status', isEqualTo: StockAlertStatus.pending.name)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockAlertModel.fromDocumentSnapshot(doc))
              .toList(),
        );
  }

  /// Stream de avisos pendentes agrupados por produto.
  Stream<List<StockAlertGroupModel>> watchPendingAlertGroups() {
    return watchPendingAlerts().map(groupAlertsByProduct);
  }

  /// Stream da contagem de produtos com avisos pendentes — para badge no menu.
  Stream<int> watchPendingCount() {
    return watchPendingAlerts().map(
      (alerts) => alerts.map((alert) => alert.productId).toSet().length,
    );
  }

  // MARK: - Consultas

  /// Busca avisos resolvidos individuais (notificados + encerrados).
  Future<List<StockAlertModel>> getResolved({int limit = 50}) async {
    try {
      final snapshot = await _collection
          .where(
            'status',
            whereIn: [
              StockAlertStatus.notified.name,
              StockAlertStatus.dismissed.name,
            ],
          )
          .orderBy('resolved_at', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => StockAlertModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar avisos resolvidos', error: e);
      return [];
    }
  }

  /// Busca avisos resolvidos agrupados por produto.
  Future<List<StockAlertGroupModel>> getResolvedGroups({
    int limit = 100,
  }) async {
    final resolved = await getResolved(limit: limit);
    return groupAlertsByProduct(resolved);
  }

  Future<StockAlertGroupModel?> getPendingGroupForProduct(
    String productId,
  ) async {
    try {
      final snapshot = await _collection
          .where('product_id', isEqualTo: productId)
          .where('status', isEqualTo: StockAlertStatus.pending.name)
          .orderBy('created_at')
          .get();

      if (snapshot.docs.isEmpty) return null;
      final alerts = snapshot.docs
          .map((doc) => StockAlertModel.fromDocumentSnapshot(doc))
          .toList();
      return groupAlertsByProduct(alerts).firstOrNull;
    } catch (e) {
      AppLogger.error('Erro ao buscar resumo do produto em avisos', error: e);
      return null;
    }
  }

  Stream<StockAlertGroupModel?> watchPendingGroupForProduct(String productId) {
    return _collection
        .where('product_id', isEqualTo: productId)
        .where('status', isEqualTo: StockAlertStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final alerts = snapshot.docs
              .map((doc) => StockAlertModel.fromDocumentSnapshot(doc))
              .toList();
          return groupAlertsByProduct(alerts).firstOrNull;
        });
  }

  // MARK: - Ações

  /// Encerra um aviso (pending → dismissed).
  Future<bool> dismissAlert(String alertId, {String? notes}) async {
    try {
      await _collection.doc(alertId).update({
        'status': StockAlertStatus.dismissed.name,
        'resolved_at': Timestamp.fromDate(DateTime.now()),
        'updated_at': Timestamp.fromDate(DateTime.now()),
        if (notes != null) 'notes': notes,
      });
      AppLogger.info('Aviso de estoque $alertId encerrado');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao encerrar aviso', error: e);
      return false;
    }
  }

  /// Marca aviso como notificado (pending → notified).
  Future<bool> markNotified(String alertId, {String? notes}) async {
    try {
      await _collection.doc(alertId).update({
        'status': StockAlertStatus.notified.name,
        'resolved_at': Timestamp.fromDate(DateTime.now()),
        'updated_at': Timestamp.fromDate(DateTime.now()),
        if (notes != null) 'notes': notes,
      });
      AppLogger.info('Aviso de estoque $alertId marcado como notificado');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao marcar aviso como notificado', error: e);
      return false;
    }
  }

  /// Encerra todos os avisos pendentes de um produto.
  Future<bool> dismissGroup(String productId, {String? notes}) async {
    try {
      final snapshot = await _collection
          .where('product_id', isEqualTo: productId)
          .where('status', isEqualTo: StockAlertStatus.pending.name)
          .get();

      if (snapshot.docs.isEmpty) return true;

      final batch = _firestore.batch();
      final now = Timestamp.fromDate(DateTime.now());
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': StockAlertStatus.dismissed.name,
          'resolved_at': now,
          'updated_at': now,
          if (notes != null) 'notes': notes,
        });
      }
      await batch.commit();
      AppLogger.info(
        'Avisos do produto $productId encerrados: ${snapshot.docs.length}',
      );
      return true;
    } catch (e) {
      AppLogger.error('Erro ao encerrar avisos do produto', error: e);
      return false;
    }
  }

  /// Dispara a notificação de reposição para todos os clientes do produto.
  Future<Map<String, dynamic>> notifyCustomersForProduct(
    String productId,
  ) async {
    try {
      return await BackendApi.instance.notifyRestockCustomers(
        tenantId: _tenantId,
        productId: productId,
      );
    } catch (e) {
      AppLogger.error('Erro ao notificar clientes da reposição', error: e);
      return {'ok': false, 'error': e.toString()};
    }
  }
}
