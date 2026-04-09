import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Enums/EscalationStatus.dart';
import '../../Commons/Models/EscalationModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Utils/DataCache.dart';
import '../../Sources/SessionManager.dart';

/// Repository do módulo Atendimentos Escalados.
///
/// Acessa `tenants/{tenant_id}/escalations/`.
/// Usa cache estático compartilhado entre Presenters.
class EscalationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache compartilhado entre todas as instâncias.
  static final DataCache<EscalationModel> escalationsCache =
      DataCache<EscalationModel>(ttl: const Duration(minutes: 5));

  /// Registra limpeza de cache no SessionManager.
  // ignore: unused_field
  static final bool _registered = _register();
  static bool _register() {
    SessionManager.registerCacheClear(clearCache);
    return true;
  }

  /// Limpa cache (usar ao trocar tenant ou logout).
  static void clearCache() => escalationsCache.clear();

  /// Referência da subcoleção escalations do tenant ativo.
  CollectionReference<Map<String, dynamic>> get _collection {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants/$tenantId/escalations');
  }

  /// Referência da subcoleção customers do tenant ativo.
  CollectionReference<Map<String, dynamic>> get _customersCollection {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants/$tenantId/customers');
  }

  // MARK: - CRUD

  /// Busca todas as escalações. Usa cache se fresco.
  Future<List<EscalationModel>> getAll({bool forceRefresh = false}) async {
    if (!forceRefresh && escalationsCache.isFresh) {
      return escalationsCache.data;
    }

    try {
      final snapshot = await _collection
          .orderBy('created_at', descending: true)
          .get();
      final escalations = snapshot.docs
          .map((doc) => EscalationModel.fromDocumentSnapshot(doc))
          .toList();
      escalationsCache.set(escalations);
      return escalations;
    } catch (e) {
      AppLogger.error('Erro ao buscar escalações', error: e);
      if (escalationsCache.hasData) return escalationsCache.data;
      return [];
    }
  }

  /// Busca uma escalação por ID.
  Future<EscalationModel?> getById(String escalationId) async {
    try {
      final doc = await _collection.doc(escalationId).get();
      if (doc.exists) {
        return EscalationModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Erro ao buscar escalação', error: e);
      return null;
    }
  }

  // MARK: - Status Transitions

  /// Assume um atendimento (pending → in_progress).
  Future<bool> assumeEscalation(
    String escalationId,
    String userId,
    String userName,
    String customerId,
  ) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      final batch = _firestore.batch();

      batch.update(_collection.doc(escalationId), {
        'status': EscalationStatus.in_progress.name,
        'assigned_to': userId,
        'assigned_to_name': userName,
        'updated_at': now,
      });

      batch.update(_customersCollection.doc(customerId), {
        'agent_off': true,
        'time_agent_off': now,
        'human_handoff_pending': false,
        'updated_at': now,
      });

      await batch.commit();
      AppLogger.info('Escalação $escalationId assumida por $userName');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao assumir escalação', error: e);
      return false;
    }
  }

  /// Finaliza um atendimento (in_progress → completed).
  /// Também atualiza customer.agent_off = false.
  Future<bool> completeEscalation(
    String escalationId,
    String customerId, {
    String? notes,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Atualiza escalação
      batch.update(_collection.doc(escalationId), {
        'status': EscalationStatus.completed.name,
        'completed_at': Timestamp.fromDate(DateTime.now()),
        'updated_at': Timestamp.fromDate(DateTime.now()),
        if (notes != null) 'notes': notes,
      });

      // 2. Libera cliente para o agente IA
      batch.update(_customersCollection.doc(customerId), {
        'agent_off': false,
        'time_agent_off': '',
        'human_handoff_pending': false,
        'active_escalation_id': '',
        'last_human_handoff_summary': '',
        'last_human_handoff_reason': '',
        'last_human_handoff_requested_at': '',
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();
      AppLogger.info(
        'Escalação $escalationId finalizada, agent_off=false para $customerId',
      );
      return true;
    } catch (e) {
      AppLogger.error('Erro ao finalizar escalação', error: e);
      return false;
    }
  }

  /// Atualiza anotações do atendente.
  Future<bool> updateNotes(String escalationId, String notes) async {
    try {
      await _collection.doc(escalationId).update({
        'notes': notes,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar notas', error: e);
      return false;
    }
  }

  // MARK: - Streams (Real-Time)

  /// Stream de escalações ativas (pending + in_progress) — real-time.
  Stream<List<EscalationModel>> watchActiveEscalations() {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    final path = 'tenants/$tenantId/escalations';
    AppLogger.info(
      '[Escalations] watchActiveEscalations -> path: $path, '
      'whereIn: [${EscalationStatus.pending.name}, ${EscalationStatus.in_progress.name}]',
    );
    return _collection
        .where(
          'status',
          whereIn: [
            EscalationStatus.pending.name,
            EscalationStatus.in_progress.name,
          ],
        )
        .snapshots()
        .map(
          (snapshot) {
          AppLogger.info(
            '[Escalations] watchActiveEscalations snapshot -> '
            '${snapshot.docs.length} docs encontrados',
          );
          for (final doc in snapshot.docs) {
            final data = doc.data();
            AppLogger.info(
              '[Escalations]   doc ${doc.id}: status=${data['status']}, '
              'created_at=${data['created_at']}, '
              'customer_name=${data['customer_name']}',
            );
          }
          final list = snapshot.docs
              .map((doc) => EscalationModel.fromDocumentSnapshot(doc))
              .toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          AppLogger.info(
            '[Escalations] watchActiveEscalations -> retornando ${list.length} itens',
          );
          return list;
        })
        .handleError((error, stackTrace) {
          AppLogger.error(
            '[Escalations] watchActiveEscalations ERRO',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  /// Stream da contagem de escalações pendentes — para badge no menu.
  Stream<int> watchPendingCount() {
    return _collection
        .where('status', isEqualTo: EscalationStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          AppLogger.info(
            '[Escalations] watchPendingCount -> ${snapshot.docs.length} pendentes',
          );
          for (final doc in snapshot.docs) {
            final data = doc.data();
            AppLogger.info(
              '[Escalations]   pending doc ${doc.id}: status=${data['status']}',
            );
          }
          return snapshot.docs.length;
        });
  }

  // MARK: - Consultas

  /// Busca escalações finalizadas (para histórico).
  Future<List<EscalationModel>> getCompleted({int limit = 50}) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: EscalationStatus.completed.name)
          .limit(limit)
          .get();
      final list = snapshot.docs
          .map((doc) => EscalationModel.fromDocumentSnapshot(doc))
          .toList();
      list.sort(
        (a, b) => (b.completedAt ?? b.createdAt).compareTo(
          a.completedAt ?? a.createdAt,
        ),
      );
      return list;
    } catch (e) {
      AppLogger.error('Erro ao buscar escalações finalizadas', error: e);
      return [];
    }
  }

  /// Contagem total de escalações.
  Future<int> count() async {
    try {
      final snapshot = await _collection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Erro ao contar escalações', error: e);
      return 0;
    }
  }
}
