import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de usuário do sistema.
///
/// Coleção global: `users/{user_id}`
class UserModel {
  String uid;
  String email;
  String name;
  String? photoUrl;
  bool requiresPasswordReset;
  DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.requiresPasswordReset = false,
    required this.createdAt,
  });

  // MARK: - Factory

  static UserModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photo_url'],
      requiresPasswordReset: data['requires_password_reset'] == true,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'requires_password_reset': requiresPasswordReset,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  // MARK: - Helpers

  static UserModel newModel() {
    return UserModel(uid: '', email: '', name: '', createdAt: DateTime.now());
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    bool? requiresPasswordReset,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      requiresPasswordReset:
          requiresPasswordReset ?? this.requiresPasswordReset,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
