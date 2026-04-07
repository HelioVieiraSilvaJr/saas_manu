import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Enums/BusinessSegment.dart';
import '../../Commons/Models/AiBusinessProfileModel.dart';

class AiBusinessProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('platform_ai_business_profiles');

  Stream<List<AiBusinessProfileModel>> watchAll() {
    return _collection.orderBy('sort_order').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return AiBusinessProfileModel.defaults;
      }

      final profiles = snapshot.docs
          .map((doc) => AiBusinessProfileModel.fromDocumentSnapshot(doc))
          .toList();
      profiles.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return profiles;
    });
  }

  Future<void> ensureDefaults() async {
    final batch = _firestore.batch();
    for (final profile in AiBusinessProfileModel.defaults) {
      final doc = await _collection.doc(profile.id).get();
      if (!doc.exists) {
        batch.set(_collection.doc(profile.id), {
          ...profile.toMap(),
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> save(AiBusinessProfileModel profile) async {
    await _collection.doc(profile.id).set({
      ...profile.toMap(),
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> restoreDefault(BusinessSegment segment) async {
    final profile = AiBusinessProfileModel.defaultForSegment(segment);
    await _collection.doc(profile.id).set({
      ...profile.toMap(),
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
