import 'package:firebase_auth/firebase_auth.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/SessionManager.dart';
import 'LoginRepository.dart';
import 'LoginViewModel.dart';

/// Presenter para a tela de Login.
///
/// Contém a lógica de negócio e atualiza o ViewModel.
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
    viewModel = viewModel.copyWith(isLoading: true, errorMessage: null);
    _notifyView();

    try {
      // 1. Autenticar no Firebase Auth
      final firebaseUser = await _repository.signIn(
        email: email,
        password: password,
      );

      // 2. Verificar se é o primeiro login
      if (_repository.isFirstLogin(firebaseUser)) {
        viewModel = viewModel.copyWith(isLoading: false, isFirstLogin: true);
        _notifyView();
        return false;
      }

      // 3. Carregar sessão completa (user, memberships, tenant)
      await SessionManager.instance.loadSession(firebaseUser);

      viewModel = viewModel.copyWith(isLoading: false);
      _notifyView();

      AppLogger.info('Login completo - redirecionando para dashboard');
      return true;
    } on FirebaseAuthException catch (e) {
      final message = _mapAuthError(e.code);
      viewModel = viewModel.copyWith(isLoading: false, errorMessage: message);
      _notifyView();
      AppLogger.error('Erro FirebaseAuth: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      _notifyView();
      AppLogger.error('Erro login: $e');
      return false;
    }
  }

  // MARK: - Forgot Password

  /// Envia email de recuperação de senha.
  Future<bool> sendPasswordReset(String email) async {
    viewModel = viewModel.copyWith(isLoading: true, errorMessage: null);
    _notifyView();

    try {
      await _repository.resetPassword(email);
      viewModel = viewModel.copyWith(
        isLoading: false,
        forgotPasswordSent: true,
      );
      _notifyView();
      return true;
    } on FirebaseAuthException catch (e) {
      final message = _mapAuthError(e.code);
      viewModel = viewModel.copyWith(isLoading: false, errorMessage: message);
      _notifyView();
      return false;
    } catch (e) {
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao enviar email de recuperação.',
      );
      _notifyView();
      return false;
    }
  }

  // MARK: - Change Password (First Login)

  /// Altera a senha no primeiro login.
  Future<bool> changePassword(String newPassword) async {
    viewModel = viewModel.copyWith(isLoading: true, errorMessage: null);
    _notifyView();

    try {
      await _repository.changePassword(newPassword);

      // Carregar sessão após troca de senha
      final firebaseUser = _repository.currentFirebaseUser;
      if (firebaseUser != null) {
        await SessionManager.instance.loadSession(firebaseUser);
      }

      viewModel = viewModel.copyWith(isLoading: false, isFirstLogin: false);
      _notifyView();
      return true;
    } catch (e) {
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao alterar senha. Tente novamente.',
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

  /// Alterna exibição do formulário de recuperação de senha.
  void toggleForgotPassword() {
    viewModel = viewModel.copyWith(
      showForgotPasswordForm: !viewModel.showForgotPasswordForm,
      errorMessage: null,
      forgotPasswordSent: false,
    );
    _notifyView();
  }

  /// Limpa mensagem de erro.
  void clearError() {
    viewModel = viewModel.copyWith(errorMessage: null);
    _notifyView();
  }

  // MARK: - Private

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
      case 'invalid-credential':
        return 'Credenciais inválidas. Verifique email e senha.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      default:
        return 'Erro ao realizar login. Tente novamente.';
    }
  }
}
