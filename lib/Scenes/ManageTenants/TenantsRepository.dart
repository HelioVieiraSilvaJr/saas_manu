import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Models/MembershipModel.dart';
import '../../Commons/Models/PaymentModel.dart';
import '../../Commons/Enums/PlanPeriod.dart';
import '../../Commons/Enums/PlanTier.dart';
import '../../Commons/Utils/AppLogger.dart';

/// Repository CRUD de Tenants (SuperAdmin).
///
/// Acessa coleção global `tenants/`.
class TenantsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('tenants');

  // MARK: - CRUD

  /// Busca todos os tenants.
  Future<List<TenantModel>> getAll() async {
    try {
      final snapshot = await _collection
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TenantModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar tenants', error: e);
      return [];
    }
  }

  /// Busca um tenant por ID.
  Future<TenantModel?> getById(String tenantId) async {
    try {
      final doc = await _collection.doc(tenantId).get();
      if (doc.exists) {
        return TenantModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Erro ao buscar tenant', error: e);
      return null;
    }
  }

  /// Cria um novo tenant completo (tenant + user + membership).
  /// Retorna o ID do tenant criado.
  Future<String?> createTenantWithUser({
    required String name,
    required String email,
    required String phone,
    required String plan,
    required String planTier,
    required bool isActive,
  }) async {
    try {
      final now = DateTime.now();
      final period = PlanPeriod.fromString(plan);
      final expiration = now.add(Duration(days: period.durationDays));

      // 1. Criar tenant
      final tenantData = <String, dynamic>{
        'name': name,
        'contact_email': email,
        'contact_phone': phone,
        'plan': plan,
        'plan_tier': planTier,
        'is_active': isActive,
        'is_expired': false,
        'expiration_date': Timestamp.fromDate(expiration),
        'created_at': FieldValue.serverTimestamp(),
      };

      // Se Trial: definir trial_end_date também
      if (plan == 'trial') {
        tenantData['trial_end_date'] = Timestamp.fromDate(expiration);
      }

      final tenantRef = await _collection.add(tenantData);
      AppLogger.info('Tenant criado: ${tenantRef.id}');

      // 2. Criar usuário (TenantAdmin) — senha padrão: 1234567
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: '1234567',
        );

        final userId = userCredential.user!.uid;

        // 3. Criar documento em users/
        await _firestore.collection('users').doc(userId).set({
          'email': email,
          'name': name,
          'created_at': FieldValue.serverTimestamp(),
        });

        // 4. Criar membership (tenantAdmin)
        await _firestore.collection('memberships').add({
          'user_id': userId,
          'tenant_id': tenantRef.id,
          'role': 'tenantAdmin',
          'is_active': true,
          'user_name': name,
          'user_email': email,
          'created_at': FieldValue.serverTimestamp(),
        });

        AppLogger.info('User + Membership criados para tenant ${tenantRef.id}');
      } catch (authError) {
        AppLogger.error(
          'Erro ao criar usuário (tenant já criado)',
          error: authError,
        );
        // Tenant criado, mas user falhou — informar
      }

      return tenantRef.id;
    } catch (e) {
      AppLogger.error('Erro ao criar tenant', error: e);
      return null;
    }
  }

  /// Atualiza um tenant existente.
  Future<bool> update(TenantModel tenant) async {
    try {
      final data = tenant.toMap();
      data['updated_at'] = FieldValue.serverTimestamp();
      await _collection.doc(tenant.uid).update(data);
      AppLogger.info('Tenant atualizado: ${tenant.uid}');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar tenant', error: e);
      return false;
    }
  }

  /// Deleta um tenant e todas as suas subcoleções em cascata.
  Future<bool> deleteTenant(String tenantId) async {
    try {
      // 1. Deletar subcoleções
      await _deleteSubcollection('tenants/$tenantId/products');
      await _deleteSubcollection('tenants/$tenantId/customers');
      await _deleteSubcollection('tenants/$tenantId/sales');
      await _deleteSubcollection('tenants/$tenantId/billing');
      await _deleteSubcollection('tenants/$tenantId/payments');

      // 2. Deletar memberships
      final memberships = await _firestore
          .collection('memberships')
          .where('tenant_id', isEqualTo: tenantId)
          .get();

      for (var doc in memberships.docs) {
        await doc.reference.delete();
      }

      // 3. Deletar tenant
      await _collection.doc(tenantId).delete();

      AppLogger.info('Tenant deletado em cascata: $tenantId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao deletar tenant', error: e);
      return false;
    }
  }

  /// Deleta todos os documentos de uma subcoleção.
  Future<void> _deleteSubcollection(String path) async {
    try {
      final snapshot = await _firestore.collection(path).get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      AppLogger.debug(
        'Subcoleção deletada: $path (${snapshot.docs.length} docs)',
      );
    } catch (e) {
      AppLogger.error('Erro ao deletar subcoleção $path', error: e);
    }
  }

  // MARK: - Ações Especiais

  /// Altera o plano de um tenant.
  Future<bool> changePlan(
    String tenantId,
    String newPlan, {
    String newTier = 'standard',
  }) async {
    try {
      final now = DateTime.now();
      final period = PlanPeriod.fromString(newPlan);
      final expiration = now.add(Duration(days: period.durationDays));

      final data = <String, dynamic>{
        'plan': newPlan,
        'plan_tier': newTier,
        'expiration_date': Timestamp.fromDate(expiration),
        'is_expired': false,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Se mudou para trial, definir trial_end_date
      if (newPlan == 'trial') {
        data['trial_end_date'] = Timestamp.fromDate(expiration);
      } else {
        data['trial_end_date'] = null;
      }

      await _collection.doc(tenantId).update(data);
      AppLogger.info('Plano alterado: $tenantId → $newPlan ($newTier)');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao alterar plano', error: e);
      return false;
    }
  }

  /// Estende o trial de um tenant em X dias.
  Future<bool> extendTrial(String tenantId, int days) async {
    try {
      final doc = await _collection.doc(tenantId).get();
      if (!doc.exists) return false;

      final tenant = TenantModel.fromDocumentSnapshot(doc);
      final currentEnd =
          tenant.expirationDate ?? tenant.trialEndDate ?? DateTime.now();
      final newEnd = currentEnd.add(Duration(days: days));

      await _collection.doc(tenantId).update({
        'trial_end_date': Timestamp.fromDate(newEnd),
        'expiration_date': Timestamp.fromDate(newEnd),
        'is_expired': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Trial estendido: $tenantId +$days dias');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao estender trial', error: e);
      return false;
    }
  }

  /// Ativa ou inativa um tenant.
  Future<bool> toggleActive(String tenantId, bool isActive) async {
    try {
      await _collection.doc(tenantId).update({
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Tenant ${isActive ? "ativado" : "inativado"}: $tenantId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao alterar status do tenant', error: e);
      return false;
    }
  }

  // MARK: - Stats

  /// Conta subcoleções de um tenant.
  Future<Map<String, int>> getTenantStats(String tenantId) async {
    try {
      final results = await Future.wait([
        _firestore.collection('tenants/$tenantId/products').count().get(),
        _firestore.collection('tenants/$tenantId/customers').count().get(),
        _firestore.collection('tenants/$tenantId/sales').count().get(),
      ]);

      return {
        'products': results[0].count ?? 0,
        'customers': results[1].count ?? 0,
        'sales': results[2].count ?? 0,
      };
    } catch (e) {
      AppLogger.error('Erro ao buscar stats do tenant', error: e);
      return {'products': 0, 'customers': 0, 'sales': 0};
    }
  }

  /// Busca memberships de um tenant.
  Future<List<MembershipModel>> getTenantMembers(String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('memberships')
          .where('tenant_id', isEqualTo: tenantId)
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => MembershipModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar membros do tenant', error: e);
      return [];
    }
  }

  /// Calcula receita total de vendas de um tenant.
  Future<double> getTenantRevenue(String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('tenants/$tenantId/sales')
          .where('status', isNotEqualTo: 'cancelled')
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['total_value'] ?? 0).toDouble();
      }
      return total;
    } catch (e) {
      AppLogger.error('Erro ao calcular receita do tenant', error: e);
      return 0;
    }
  }

  // MARK: - Payments

  /// Busca histórico de pagamentos de um tenant.
  Future<List<PaymentModel>> getPayments(String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('tenants/$tenantId/payments')
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => PaymentModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar pagamentos', error: e);
      return [];
    }
  }

  /// Cria um registro de pagamento pendente (PIX gerado).
  Future<String?> createPayment(String tenantId, PaymentModel payment) async {
    try {
      final ref = await _firestore
          .collection('tenants/$tenantId/payments')
          .add(payment.toMap());
      AppLogger.info('Pagamento criado: ${ref.id}');
      return ref.id;
    } catch (e) {
      AppLogger.error('Erro ao criar pagamento', error: e);
      return null;
    }
  }

  /// Escuta mudanças no documento do tenant (para detectar pagamento via webhook).
  Stream<TenantModel?> listenTenant(String tenantId) {
    return _collection.doc(tenantId).snapshots().map((doc) {
      if (doc.exists) {
        return TenantModel.fromDocumentSnapshot(doc);
      }
      return null;
    });
  }
}
