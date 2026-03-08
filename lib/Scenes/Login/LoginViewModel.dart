/// ViewModel para a tela de Login.
///
/// Mantém o estado da view de forma reativa.
class LoginViewModel {
  bool isLoading;
  String? errorMessage;
  bool isPasswordVisible;
  bool showForgotPasswordForm;
  bool forgotPasswordSent;
  bool isFirstLogin;

  LoginViewModel({
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordVisible = false,
    this.showForgotPasswordForm = false,
    this.forgotPasswordSent = false,
    this.isFirstLogin = false,
  });

  LoginViewModel copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordVisible,
    bool? showForgotPasswordForm,
    bool? forgotPasswordSent,
    bool? isFirstLogin,
  }) {
    return LoginViewModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      showForgotPasswordForm:
          showForgotPasswordForm ?? this.showForgotPasswordForm,
      forgotPasswordSent: forgotPasswordSent ?? this.forgotPasswordSent,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
    );
  }
}
