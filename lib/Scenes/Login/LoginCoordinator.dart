import 'package:flutter/material.dart';
import '../../Commons/Utils/AppLogger.dart';

/// Coordinator para navegação da tela de Login.
///
/// Gerencia redirecionamentos após login/logout.
class LoginCoordinator {
  /// Navega para o Dashboard após login bem-sucedido.
  void navigateToDashboard(BuildContext context) {
    AppLogger.info('Navegando para Dashboard');
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  /// Navega para a tela de Login.
  static void navigateToLogin(BuildContext context) {
    AppLogger.info('Navegando para Login');
    Navigator.of(context).pushReplacementNamed('/login');
  }

  /// Navega para a tela de Login e limpa toda a stack.
  static void navigateToLoginAndClearStack(BuildContext context) {
    AppLogger.info('Navegando para Login (clear stack)');
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
