import 'package:cloud_firestore/cloud_firestore.dart';
import '../Commons/Utils/AppLogger.dart';

/// Script de seed para popular dados iniciais no Firestore.
///
/// Cria o SuperAdmin, tenant master e membership.
/// Deve ser chamado apenas uma vez na primeira execução.
class SeedRunner {
  final _firestore = FirebaseFirestore.instance;

  String _membershipDocId(String tenantId, String userId) =>
      '${tenantId}_$userId';

  /// Verifica se o seed já foi executado (existe pelo menos 1 tenant).
  Future<bool> isSeeded() async {
    final snapshot = await _firestore.collection('tenants').limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Executa o seed completo: cria user, tenant e membership.
  ///
  /// [firebaseUid] é o UID do Firebase Auth do usuário logado.
  Future<void> run({
    required String firebaseUid,
    required String name,
    required String email,
  }) async {
    AppLogger.info('=== INICIANDO SEED ===');

    try {
      // 1. Criar documento do usuário em /users
      AppLogger.info('Criando usuário: $email ($firebaseUid)');
      await _firestore.collection('users').doc(firebaseUid).set({
        'email': email,
        'name': name,
        'platform_role': 'superAdmin',
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Criar tenant master (Plataforma SaaS)
      final tenantRef = _firestore.collection('tenants').doc();
      final tenantId = tenantRef.id;
      AppLogger.info('Criando tenant master: $tenantId');

      final trialEnd = DateTime.now().add(const Duration(days: 365));

      await tenantRef.set({
        'name': 'Plataforma Admin',
        'contact_email': email,
        'contact_phone': '',
        'plan': 'monthly',
        'plan_tier': 'pro',
        'is_active': true,
        'is_expired': false,
        'created_at': FieldValue.serverTimestamp(),
        'trial_end_date': Timestamp.fromDate(trialEnd),
        'expiration_date': Timestamp.fromDate(trialEnd),
      });

      // 3. Criar membership como SuperAdmin
      AppLogger.info('Criando membership SuperAdmin');
      await _firestore
          .collection('memberships')
          .doc(_membershipDocId(tenantId, firebaseUid))
          .set({
            'user_id': firebaseUid,
            'tenant_id': tenantId,
            'role': 'superAdmin',
            'is_active': true,
            'user_name': name,
            'user_email': email,
            'added_by': firebaseUid,
            'created_at': FieldValue.serverTimestamp(),
          });

      // 4. Criar um tenant de exemplo para testes
      final sampleTenantRef = _firestore.collection('tenants').doc();
      final sampleTenantId = sampleTenantRef.id;
      AppLogger.info('Criando tenant de exemplo: $sampleTenantId');

      final sampleTrialEnd = DateTime.now().add(const Duration(days: 15));

      await sampleTenantRef.set({
        'name': 'Loja Exemplo',
        'contact_email': 'loja@exemplo.com',
        'contact_phone': '11999999999',
        'plan': 'trial',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'trial_end_date': Timestamp.fromDate(sampleTrialEnd),
      });

      // 5. Criar membership do SuperAdmin para o tenant de exemplo também
      await _firestore
          .collection('memberships')
          .doc(_membershipDocId(sampleTenantId, firebaseUid))
          .set({
            'user_id': firebaseUid,
            'tenant_id': sampleTenantId,
            'role': 'tenantAdmin',
            'is_active': true,
            'user_name': name,
            'user_email': email,
            'added_by': firebaseUid,
            'created_at': FieldValue.serverTimestamp(),
          });

      // 6. Criar alguns produtos de exemplo no tenant de exemplo
      final productsRef = _firestore
          .collection('tenants')
          .doc(sampleTenantId)
          .collection('products');

      await productsRef.add({
        'name': 'Camiseta Básica',
        'description': 'Camiseta 100% algodão',
        'price': 49.90,
        'stock': 100,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      await productsRef.add({
        'name': 'Calça Jeans',
        'description': 'Calça jeans slim fit',
        'price': 129.90,
        'stock': 50,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      await productsRef.add({
        'name': 'Tênis Esportivo',
        'description': 'Tênis para corrida leve',
        'price': 199.90,
        'stock': 30,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      AppLogger.info('=== SEED CONCLUÍDO COM SUCESSO! ===');
      AppLogger.info('SuperAdmin: $name ($email)');
      AppLogger.info('Tenant Master: Plataforma Admin ($tenantId)');
      AppLogger.info('Tenant Exemplo: Loja Exemplo ($sampleTenantId)');
    } catch (e) {
      AppLogger.error('Erro no seed', error: e);
      rethrow;
    }
  }
}
