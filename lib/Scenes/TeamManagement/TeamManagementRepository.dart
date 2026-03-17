import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Commons/Enums/UserRole.dart';
import '../../Commons/Models/MembershipModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/BackendApi.dart';

/// Repository para Gerenciar Equipe — Módulo 9.
class TeamManagementRepository {
  final _firestore = FirebaseFirestore.instance;

  // MARK: - Listar membros do tenant

  Future<List<MembershipModel>> fetchMembers(String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('memberships')
          .where('tenant_id', isEqualTo: tenantId)
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => MembershipModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar membros', error: e);
      return [];
    }
  }

  // MARK: - Contar admins ativos

  Future<int> countActiveAdmins(String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('memberships')
          .where('tenant_id', isEqualTo: tenantId)
          .where('role', isEqualTo: 'tenantAdmin')
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      AppLogger.error('Erro ao contar admins', error: e);
      return 0;
    }
  }

  // MARK: - Buscar usuário por email

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return {'uid': doc.id, ...doc.data()};
    } catch (e) {
      AppLogger.error('Erro ao buscar usuário por email', error: e);
      return null;
    }
  }

  // MARK: - Verificar membership existente

  Future<MembershipModel?> findMembership(
    String userId,
    String tenantId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('memberships')
          .where('user_id', isEqualTo: userId)
          .where('tenant_id', isEqualTo: tenantId)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return MembershipModel.fromDocumentSnapshot(snapshot.docs.first);
    } catch (e) {
      AppLogger.error('Erro ao verificar membership', error: e);
      return null;
    }
  }

  // MARK: - Criar novo usuário via Firebase Auth

  Future<Map<String, dynamic>?> provisionMember({
    required String email,
    required String name,
    required String tenantId,
    required UserRole role,
  }) async {
    try {
      final response = await BackendApi.instance.postAuthenticated(
        functionName: 'provisionTenantMember',
        body: {
          'email': email,
          'name': name,
          'tenantId': tenantId,
          'role': role.name,
        },
      );

      return response;
    } catch (e) {
      AppLogger.error('Erro ao provisionar membro', error: e);
      return null;
    }
  }

  Future<String?> createUser({
    required String email,
    required String name,
    String? password,
  }) async {
    try {
      if (password == null || password.isEmpty) {
        AppLogger.warning(
          'createUser sem senha explicita foi bloqueado; use provisionMember no backend.',
        );
        return null;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'created_at': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Novo usuário criado: $email');
      return uid;
    } catch (e) {
      AppLogger.error('Erro ao criar usuário', error: e);
      return null;
    }
  }

  // MARK: - Criar membership

  Future<bool> createMembership({
    required String userId,
    required String tenantId,
    required UserRole role,
    required String userName,
    required String userEmail,
    required String addedBy,
  }) async {
    try {
      await _firestore.collection('memberships').doc('${tenantId}_$userId').set({
        'user_id': userId,
        'tenant_id': tenantId,
        'role': role.name,
        'is_active': true,
        'user_name': userName,
        'user_email': userEmail,
        'added_by': addedBy,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      AppLogger.error('Erro ao criar membership', error: e);
      return false;
    }
  }

  // MARK: - Atualizar membership (role, is_active)

  Future<bool> updateMembership({
    required String membershipId,
    required UserRole role,
    required bool isActive,
    String? removedBy,
  }) async {
    try {
      final data = <String, dynamic>{
        'role': role.name,
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (!isActive && removedBy != null) {
        data['removed_at'] = FieldValue.serverTimestamp();
        data['removed_by'] = removedBy;
      }

      await _firestore.collection('memberships').doc(membershipId).update(data);
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar membership', error: e);
      return false;
    }
  }

  // MARK: - Remover membro (soft delete)

  Future<bool> removeMember({
    required String membershipId,
    required String removedBy,
  }) async {
    try {
      await _firestore.collection('memberships').doc(membershipId).update({
        'is_active': false,
        'removed_at': FieldValue.serverTimestamp(),
        'removed_by': removedBy,
      });
      return true;
    } catch (e) {
      AppLogger.error('Erro ao remover membro', error: e);
      return false;
    }
  }
}
