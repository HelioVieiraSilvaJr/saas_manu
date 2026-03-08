import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Enums/SaleStatus.dart';
import '../../Commons/Models/SaleModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/SessionManager.dart';

/// Repository do módulo Vendas.
///
/// Acessa `tenants/{tenant_id}/sales/`.
class SalesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referência da subcoleção sales do tenant ativo.
  CollectionReference<Map<String, dynamic>> get _collection {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    return _firestore.collection('tenants/$tenantId/sales');
  }

  // MARK: - CRUD

  /// Busca todas as vendas.
  Future<List<SaleModel>> getAll() async {
    try {
      final snapshot = await _collection
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => SaleModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas', error: e);
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
      AppLogger.info('Venda criada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Erro ao criar venda', error: e);
      return null;
    }
  }

  /// Atualiza uma venda existente.
  Future<bool> update(SaleModel sale) async {
    try {
      await _collection.doc(sale.uid).update(sale.toMap());
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
      await _collection.doc(saleId).update({
        'status': newStatus.name,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
      AppLogger.info('Status venda $saleId alterado para ${newStatus.name}');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar status da venda', error: e);
      return false;
    }
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
