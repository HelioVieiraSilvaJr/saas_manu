import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/SessionManager.dart';

/// Tela de Splash / Verificação de Sessão.
///
/// Verifica se o usuário já está autenticado e redireciona:
/// - Se autenticado → Dashboard
/// - Se não autenticado → Login
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      try {
        AppLogger.info('Usuário autenticado, carregando sessão...');
        await SessionManager.instance.loadSession(firebaseUser);

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      } catch (e) {
        AppLogger.error('Erro ao carregar sessão: $e');
        // Sessão inválida, enviar para login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } else {
      AppLogger.info('Nenhum usuário autenticado');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();

    return Scaffold(
      backgroundColor: colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 80,
              color: colors.primaryColor,
            ),
            const SizedBox(height: DSSpacing.xxl),
            const LoadingIndicator(message: 'Carregando...'),
          ],
        ),
      ),
    );
  }
}
