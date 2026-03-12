import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Commons/Models/UserModel.dart';
import '../Commons/Models/TenantModel.dart';
import '../Commons/Models/MembershipModel.dart';
import '../Commons/Enums/UserRole.dart';
import '../Commons/Utils/AppLogger.dart';
import 'PreferencesManager.dart';

/// Singleton para gerenciamento de sessão multi-tenant.
class SessionManager {
  SessionManager._();
  static SessionManager instance = SessionManager._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // MARK: - Properties

  UserModel? currentUser;
  TenantModel? currentTenant;
  MembershipModel? currentMembership;
  List<MembershipModel> allMemberships = [];

  // MARK: - Session State

  /// Verifica se há sessão ativa.
  bool hasSession() => currentUser != null && currentTenant != null;

  /// Verifica se o usuário é SuperAdmin.
  bool get isSuperAdmin => currentMembership?.role == UserRole.superAdmin;

  /// Verifica se o usuário é TenantAdmin.
  bool get isTenantAdmin => currentMembership?.role == UserRole.tenantAdmin;

  /// Verifica se o usuário é User comum.
  bool get isUser => currentMembership?.role == UserRole.user;

  /// Verifica se pode gerenciar o tenant (admin ou super).
  bool canManageTenant() => isSuperAdmin || isTenantAdmin;

  /// Verifica se pode gerenciar billing (apenas super).
  bool canManageBilling() => isSuperAdmin;

  /// Verifica se pode convidar usuários.
  bool canInviteUsers() => isSuperAdmin || isTenantAdmin;

  // MARK: - Load Session

  /// Carrega sessão completa após login.
  Future<void> loadSession(User firebaseUser) async {
    AppLogger.info('Carregando sessão para: ${firebaseUser.email}');

    // 1. Buscar UserModel
    final userDoc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('Usuário não encontrado no Firestore');
    }

    currentUser = UserModel.fromDocumentSnapshot(userDoc);

    // 2. Buscar todos os memberships ativos
    final membershipsSnapshot = await _firestore
        .collection('memberships')
        .where('user_id', isEqualTo: firebaseUser.uid)
        .where('is_active', isEqualTo: true)
        .get();

    allMemberships = membershipsSnapshot.docs
        .map((doc) => MembershipModel.fromDocumentSnapshot(doc))
        .toList();

    if (allMemberships.isEmpty) {
      throw Exception('Usuário sem acesso a nenhum tenant');
    }

    // 2b. Enriquecer memberships com nomes dos tenants (se não denormalizado)
    await _loadTenantNamesForMemberships();

    // 3. Determinar qual tenant usar
    String? targetTenantId;

    if (allMemberships.length > 1) {
      // Verificar último tenant usado
      final lastTenantId = await PreferencesManager.instance.getLastTenantId();
      final hasValidLast =
          lastTenantId != null &&
          allMemberships.any((m) => m.tenantId == lastTenantId);

      targetTenantId = hasValidLast
          ? lastTenantId
          : allMemberships.first.tenantId;
    } else {
      targetTenantId = allMemberships.first.tenantId;
    }

    // 4. Carregar tenant e membership
    await _loadTenantData(targetTenantId);

    AppLogger.info(
      'Sessão carregada: ${currentUser!.name} → ${currentTenant!.name} (${currentMembership!.role.label})',
    );
  }

  // MARK: - Switch Tenant

  /// Trocar de tenant (quando user pertence a múltiplos).
  Future<void> switchTenant(String tenantId) async {
    AppLogger.info('Trocando para tenant: $tenantId');
    clearAllCaches();
    await _loadTenantData(tenantId);
    await PreferencesManager.instance.setLastTenantId(tenantId);
    AppLogger.info('Tenant trocado: ${currentTenant!.name}');
  }

  // MARK: - Sign Out

  /// Encerrar sessão e limpar caches.
  Future<void> signOut() async {
    AppLogger.info('Encerrando sessão');
    await FirebaseAuth.instance.signOut();
    currentUser = null;
    currentTenant = null;
    currentMembership = null;
    allMemberships = [];
    clearAllCaches();
  }

  /// Limpa todos os caches de dados (usar ao trocar tenant ou logout).
  void clearAllCaches() {
    // Imports circulares evitados: repositories importam SessionManager,
    // então chamamos os clearCache estáticos diretamente nos repositórios
    // que são importados via barrel ou via chamada direta.
    for (final cb in _cacheClearCallbacks) {
      cb();
    }
  }

  /// Registra um callback para limpeza de cache.
  /// Cada Repository deve registrar seu clearCache aqui.
  static final List<void Function()> _cacheClearCallbacks = [];

  static void registerCacheClear(void Function() callback) {
    _cacheClearCallbacks.add(callback);
  }

  // MARK: - Check Membership Status

  /// Verifica se o membership atual ainda está ativo (logout forçado).
  Future<bool> checkMembershipActive() async {
    if (!hasSession()) return false;

    final snapshot = await _firestore
        .collection('memberships')
        .where('user_id', isEqualTo: currentUser!.uid)
        .where('tenant_id', isEqualTo: currentTenant!.uid)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // MARK: - Has Multiple Tenants

  /// Verifica se o usuário tem acesso a múltiplos tenants.
  bool get hasMultipleTenants => allMemberships.length > 1;

  // MARK: - Private

  /// Carrega nomes dos tenants para cada membership (enriquecimento).
  Future<void> _loadTenantNamesForMemberships() async {
    final missingNames = allMemberships
        .where((m) => m.tenantName == null || m.tenantName!.isEmpty)
        .toList();

    if (missingNames.isEmpty) return;

    // Buscar tenants em batch
    final tenantIds = missingNames.map((m) => m.tenantId).toSet();
    for (final tenantId in tenantIds) {
      try {
        final doc = await _firestore.collection('tenants').doc(tenantId).get();
        if (doc.exists) {
          final name = (doc.data() as Map<String, dynamic>)['name'] ?? '';
          for (final m in allMemberships.where((m) => m.tenantId == tenantId)) {
            m.tenantName = name;
          }
        }
      } catch (e) {
        AppLogger.warning(
          'Não foi possível carregar nome do tenant: $tenantId',
        );
      }
    }
  }

  Future<void> _loadTenantData(String tenantId) async {
    // Carregar tenant
    final tenantDoc = await _firestore
        .collection('tenants')
        .doc(tenantId)
        .get();

    if (!tenantDoc.exists) {
      throw Exception('Tenant não encontrado: $tenantId');
    }

    currentTenant = TenantModel.fromDocumentSnapshot(tenantDoc);

    // Encontrar membership correspondente
    currentMembership = allMemberships.firstWhere(
      (m) => m.tenantId == tenantId,
      orElse: () =>
          throw Exception('Membership não encontrado para tenant: $tenantId'),
    );

    // Salvar último tenant usado
    await PreferencesManager.instance.setLastTenantId(tenantId);
  }
}
