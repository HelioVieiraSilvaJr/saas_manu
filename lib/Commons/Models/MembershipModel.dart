import 'package:cloud_firestore/cloud_firestore.dart';
import '../Enums/UserRole.dart';

/// Modelo de membership (relação user ↔ tenant com role).
///
/// Coleção global: `memberships/{membership_id}`
class MembershipModel {
  String uid;
  String userId;
  String tenantId;
  UserRole role;
  bool isActive;
  DateTime createdAt;

  // Campos denormalizados
  String? userName;
  String? userEmail;
  String? tenantName;
  String? addedBy;
  DateTime? removedAt;
  String? removedBy;

  MembershipModel({
    required this.uid,
    required this.userId,
    required this.tenantId,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.tenantName,
    this.addedBy,
    this.removedAt,
    this.removedBy,
  });

  // MARK: - Factory

  static MembershipModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipModel(
      uid: doc.id,
      userId: data['user_id'] ?? '',
      tenantId: data['tenant_id'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'user'),
      isActive: data['is_active'] ?? true,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      userName: data['user_name'],
      userEmail: data['user_email'],
      tenantName: data['tenant_name'],
      addedBy: data['added_by'],
      removedAt: data['removed_at'] != null
          ? (data['removed_at'] as Timestamp).toDate()
          : null,
      removedBy: data['removed_by'],
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'tenant_id': tenantId,
      'role': role.name,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'user_name': userName,
      'user_email': userEmail,
      'tenant_name': tenantName,
      'added_by': addedBy,
      'removed_at': removedAt != null ? Timestamp.fromDate(removedAt!) : null,
      'removed_by': removedBy,
    };
  }

  // MARK: - Helpers

  MembershipModel copyWith({
    String? uid,
    String? userId,
    String? tenantId,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    String? userName,
    String? userEmail,
    String? tenantName,
    String? addedBy,
    DateTime? removedAt,
    String? removedBy,
  }) {
    return MembershipModel(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      tenantName: tenantName ?? this.tenantName,
      addedBy: addedBy ?? this.addedBy,
      removedAt: removedAt ?? this.removedAt,
      removedBy: removedBy ?? this.removedBy,
    );
  }
}
