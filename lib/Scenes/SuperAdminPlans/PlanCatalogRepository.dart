import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Models/PlanCatalogModel.dart';

class PlanCatalogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('platform_billing_plans');

  Stream<List<PlanCatalogModel>> watchAll() {
    return _collection.orderBy('sort_order').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return PlanCatalogModel.defaults;
      }

      final plans = snapshot.docs
          .map((doc) => PlanCatalogModel.fromDocumentSnapshot(doc))
          .toList();
      plans.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return plans;
    });
  }

  Future<List<PlanCatalogModel>> getAll() async {
    final snapshot = await _collection.orderBy('sort_order').get();
    if (snapshot.docs.isEmpty) {
      return PlanCatalogModel.defaults;
    }

    final plans = snapshot.docs
        .map((doc) => PlanCatalogModel.fromDocumentSnapshot(doc))
        .toList();
    plans.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return plans;
  }

  Future<PlanCatalogModel> getByPeriodAndTier(
    String period,
    String tier,
  ) async {
    final id = PlanCatalogModel.buildId(period, tier);
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return PlanCatalogModel.fromDocumentSnapshot(doc);
    }
    return PlanCatalogModel.defaultFor(period, tier);
  }

  Future<void> ensureDefaults() async {
    final batch = _firestore.batch();
    for (final plan in PlanCatalogModel.defaults) {
      final doc = await _collection.doc(plan.id).get();
      if (!doc.exists) {
        batch.set(_collection.doc(plan.id), {
          ...plan.toMap(),
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> save(PlanCatalogModel plan) async {
    await _collection.doc(plan.id).set({
      ...plan.toMap(),
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
