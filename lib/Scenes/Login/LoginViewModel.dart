/// ViewModel para a tela de Login.
///
/// Mantém o estado da view de forma reativa.
class LoginViewModel {
  bool isLoading;
  String? errorMessage;
  String? successMessage;
  bool isPasswordVisible;
  bool showForgotPasswordForm;
  bool showRegisterForm;
  bool forgotPasswordSent;
  bool isFirstLogin;

  LoginViewModel({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.isPasswordVisible = false,
    this.showForgotPasswordForm = false,
    this.showRegisterForm = false,
    this.forgotPasswordSent = false,
    this.isFirstLogin = false,
  });

  LoginViewModel copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? isPasswordVisible,
    bool? showForgotPasswordForm,
    bool? showRegisterForm,
    bool? forgotPasswordSent,
    bool? isFirstLogin,
  }) {
    return LoginViewModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      showForgotPasswordForm:
          showForgotPasswordForm ?? this.showForgotPasswordForm,
      showRegisterForm: showRegisterForm ?? this.showRegisterForm,
      forgotPasswordSent: forgotPasswordSent ?? this.forgotPasswordSent,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
    );
  }
}
