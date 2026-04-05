import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/BackendApi.dart';
import '../../Sources/SessionManager.dart';
import '../../Sources/SeedRunner.dart';
import 'LoginRepository.dart';
import 'LoginViewModel.dart';

/// Presenter para a tela de Login.
///
/// Contém a lógica de autenticação, recuperação de senha e auto cadastro.
class LoginPresenter {
  final LoginRepository _repository = LoginRepository();
  LoginViewModel viewModel = LoginViewModel();

  /// Callback para notificar a view sobre mudanças no ViewModel.
  void Function()? onViewModelUpdated;

  // MARK: - Login

  /// Realiza login com email e senha.
  ///
  /// Retorna `true` se login foi bem-sucedido e sessão carregada.
  /// Retorna `false` se é o primeiro login (forçar troca de senha).
  Future<bool> login({required String email, required String password}) async {
    viewModel = viewModel.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
      forgotPasswordSent: false,
      isFirstLogin: false,
    );
    _notifyView();

    try {
      final firebaseUser = await _repository.signIn(
        email: email,
        password: password,
      );

      await _runSeedIfNeeded(firebaseUser);
      await SessionManager.instance.loadSession(firebaseUser);

      final shouldForcePasswordReset =
          SessionManager.instance.currentUser?.requiresPasswordReset == true;
      if (shouldForcePasswordReset) {
        viewModel = viewModel.copyWith(isLoading: false, isFirstLogin: true);
        _notifyView();
        return false;
      }

      viewModel = viewModel.copyWith(isLoading: false);
      _notifyView();

      AppLogger.info('Login completo - redirecionando para dashboard');
      return true;
    } on FirebaseAuthException catch (e) {
      final message = _mapAuthError(e.code);
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: message,
        successMessage: null,
      );
      _notifyView();
      AppLogger.error('Erro FirebaseAuth: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        successMessage: null,
      );
      _notifyView();
      AppLogger.error('Erro login: $e');
      return false;
    }
  }

  // MARK: - Register

  Future<bool> register({
    required String tenantName,
    required String adminName,
    required String email,
    required String phone,
    required String password,
  }) async {
    viewModel = viewModel.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
      forgotPasswordSent: false,
    );
    _notifyView();

    try {
      final response = await BackendApi.instance.registerTenantSelfService(
        tenantName: tenantName.trim(),
        adminName: adminName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );

      final isNewUser = response['isNewUser'] == true;
      if (isNewUser) {
        return login(email: email, password: password);
      }

      try {
        final firebaseUser = await _repository.signIn(
          email: email,
          password: password,
        );
        await _runSeedIfNeeded(firebaseUser);
        await SessionManager.instance.loadSession(firebaseUser);

        viewModel = viewModel.copyWith(
          isLoading: false,
          showRegisterForm: false,
          showForgotPasswordForm: false,
          successMessage: 'Conta vinculada ao novo tenant com sucesso.',
          errorMessage: null,
        );
        _notifyView();
        return true;
      } on FirebaseAuthException {
        viewModel = viewModel.copyWith(
          isLoading: false,
          showRegisterForm: false,
          showForgotPasswordForm: false,
          successMessage:
              'Tenant criado e associado ao seu usuário existente. Entre com a senha atual dessa conta para acessar.',
          errorMessage: null,
        );
        _notifyView();
        return false;
      }
    } catch (e) {
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: _mapBackendError(e),
        successMessage: null,
      );
      _notifyView();
      AppLogger.error('Erro no auto cadastro: $e');
      return false;
    }
  }

  // MARK: - Forgot Password

  /// Envia email de recuperação de senha.
  Future<bool> sendPasswordReset(String email) async {
    viewModel = viewModel.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    _notifyView();

    try {
      await _repository.resetPassword(email);
      viewModel = viewModel.copyWith(
        isLoading: false,
        forgotPasswordSent: true,
        successMessage: 'Enviamos o link de recuperação para o seu e-mail.',
      );
      _notifyView();
      return true;
    } on FirebaseAuthException catch (e) {
      final message = _mapAuthError(e.code);
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: message,
        successMessage: null,
      );
      _notifyView();
      return false;
    } catch (e) {
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao enviar email de recuperação.',
        successMessage: null,
      );
      _notifyView();
      return false;
    }
  }

  // MARK: - Change Password (First Login)

  /// Altera a senha no primeiro login.
  Future<bool> changePassword(String newPassword) async {
    viewModel = viewModel.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    _notifyView();

    try {
      await _repository.changePassword(newPassword);
      await BackendApi.instance.completePasswordReset();

      final firebaseUser = _repository.currentFirebaseUser;
      if (firebaseUser != null) {
        await _runSeedIfNeeded(firebaseUser);
        await SessionManager.instance.loadSession(firebaseUser);
      }

      viewModel = viewModel.copyWith(isLoading: false, isFirstLogin: false);
      _notifyView();
      return true;
    } catch (e) {
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao alterar senha. Tente novamente.',
        successMessage: null,
      );
      _notifyView();
      AppLogger.error('Erro ao trocar senha: $e');
      return false;
    }
  }

  // MARK: - Toggle States

  /// Alterna visibilidade da senha.
  void togglePasswordVisibility() {
    viewModel = viewModel.copyWith(
      isPasswordVisible: !viewModel.isPasswordVisible,
    );
    _notifyView();
  }

  void openRegister() {
    viewModel = viewModel.copyWith(
      showRegisterForm: true,
      showForgotPasswordForm: false,
      forgotPasswordSent: false,
      errorMessage: null,
      successMessage: null,
    );
    _notifyView();
  }

  void openLogin() {
    viewModel = viewModel.copyWith(
      showRegisterForm: false,
      showForgotPasswordForm: false,
      forgotPasswordSent: false,
      errorMessage: null,
      successMessage: null,
      isFirstLogin: false,
    );
    _notifyView();
  }

  /// Alterna exibição do formulário de recuperação de senha.
  void toggleForgotPassword() {
    viewModel = viewModel.copyWith(
      showForgotPasswordForm: !viewModel.showForgotPasswordForm,
      showRegisterForm: false,
      errorMessage: null,
      successMessage: null,
      forgotPasswordSent: false,
    );
    _notifyView();
  }

  /// Limpa mensagem de erro.
  void clearError() {
    viewModel = viewModel.copyWith(errorMessage: null, successMessage: null);
    _notifyView();
  }

  // MARK: - Private

  /// Executa seed se Firestore estiver vazio (primeira execução).
  Future<void> _runSeedIfNeeded(User firebaseUser) async {
    if (!kDebugMode) {
      return;
    }

    final seedRunner = SeedRunner();
    final alreadySeeded = await seedRunner.isSeeded();
    if (!alreadySeeded) {
      AppLogger.info('Firestore vazio — executando seed inicial...');
      await seedRunner.run(
        firebaseUid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Admin',
        email: firebaseUser.email ?? '',
      );
      AppLogger.info('Seed concluído!');
    }
  }

  void _notifyView() {
    onViewModelUpdated?.call();
  }

  /// Mapeia erros do Firebase Auth para mensagens amigáveis.
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email não cadastrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'Formato de email inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente em alguns minutos.';
      case 'email-already-in-use':
        return 'Já existe uma conta com esse e-mail.';
      case 'invalid-credential':
        return 'Credenciais inválidas. Verifique email e senha.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      default:
        return 'Erro ao realizar login. Tente novamente.';
    }
  }

  String _mapBackendError(Object error) {
    final message = error.toString().replaceAll('Exception: ', '').trim();
    switch (message) {
      case 'invalid-signup-payload':
        return 'Preencha corretamente os dados para criar sua conta.';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 7 caracteres.';
      case 'tenant-already-exists':
        return 'Já existe um tenant com esses dados.';
      default:
        return message.isEmpty
            ? 'Não foi possível concluir o cadastro.'
            : message;
    }
  }
}
