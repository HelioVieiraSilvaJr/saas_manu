import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Enums/StockAlertStatus.dart';
import '../../Commons/Models/StockAlertModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Utils/DataCache.dart';
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

  // MARK: - Streams (Real-Time)

  /// Stream de avisos pendentes — real-time.
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

  /// Stream da contagem de avisos pendentes — para badge no menu.
  Stream<int> watchPendingCount() {
    return _collection
        .where('status', isEqualTo: StockAlertStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // MARK: - Consultas

  /// Busca avisos resolvidos (notificados + encerrados).
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
}
