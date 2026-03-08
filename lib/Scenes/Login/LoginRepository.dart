import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Commons/Models/UserModel.dart';
import '../../Commons/Models/MembershipModel.dart';
import '../../Commons/Utils/AppLogger.dart';

/// Repository para operações de autenticação e gerenciamento de usuários.
class LoginRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // MARK: - Authentication

  /// Login com email e senha.
  Future<User> signIn({required String email, required String password}) async {
    AppLogger.info('Tentando login: $email');
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user == null) {
      throw Exception('Falha ao autenticar');
    }
    AppLogger.info('Login bem-sucedido: ${credential.user!.uid}');
    return credential.user!;
  }

  /// Enviar email de recuperação de senha.
  Future<void> resetPassword(String email) async {
    AppLogger.info('Enviando reset de senha para: $email');
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Alterar senha do usuário logado.
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    await user.updatePassword(newPassword);
    AppLogger.info('Senha alterada com sucesso');
  }

  /// Verifica se é o primeiro login do usuário.
  bool isFirstLogin(User user) {
    final creation = user.metadata.creationTime;
    final lastSignIn = user.metadata.lastSignInTime;
    if (creation == null || lastSignIn == null) return false;

    // Considerar primeiro login se a diferença for menor que 2 minutos
    final diff = lastSignIn.difference(creation).inMinutes.abs();
    return diff < 2;
  }

  // MARK: - User Operations

  /// Buscar usuário por email.
  Future<UserModel?> findUserByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromDocumentSnapshot(snapshot.docs.first);
  }

  /// Criar novo usuário no Firebase Auth + Firestore.
  Future<UserModel> createUser({
    required String email,
    required String name,
    String password = '1234567',
  }) async {
    AppLogger.info('Criando novo usuário: $email');

    // 1. Criar no Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final uid = credential.user!.uid;

    // 2. Criar documento no Firestore
    final userModel = UserModel(
      uid: uid,
      email: email.trim().toLowerCase(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(userModel.toMap());

    AppLogger.info('Usuário criado: $uid');
    return userModel;
  }

  // MARK: - Membership Operations

  /// Buscar memberships ativos de um usuário.
  Future<List<MembershipModel>> getMemberships(String userId) async {
    final snapshot = await _firestore
        .collection('memberships')
        .where('user_id', isEqualTo: userId)
        .where('is_active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => MembershipModel.fromDocumentSnapshot(doc))
        .toList();
  }

  /// Verificar se usuário já é membro de um tenant.
  Future<MembershipModel?> findMembership({
    required String userId,
    required String tenantId,
  }) async {
    final snapshot = await _firestore
        .collection('memberships')
        .where('user_id', isEqualTo: userId)
        .where('tenant_id', isEqualTo: tenantId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return MembershipModel.fromDocumentSnapshot(snapshot.docs.first);
  }

  /// Criar novo membership.
  Future<void> createMembership(MembershipModel membership) async {
    AppLogger.info(
      'Criando membership: ${membership.userId} → ${membership.tenantId}',
    );
    await _firestore.collection('memberships').add(membership.toMap());
  }

  // MARK: - Sign Out

  /// Encerrar sessão no Firebase Auth.
  Future<void> signOut() async {
    await _auth.signOut();
    AppLogger.info('Sessão encerrada');
  }

  // MARK: - Current User

  /// Retorna o usuário atual do Firebase Auth.
  User? get currentFirebaseUser => _auth.currentUser;
}
