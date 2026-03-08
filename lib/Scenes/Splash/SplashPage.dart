import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/SessionManager.dart';
import '../../Sources/SeedRunner.dart';

/// Tela de Splash / Verificação de Sessão.
///
/// Verifica se o usuário já está autenticado e redireciona:
/// - Se autenticado → Dashboard
/// - Se não autenticado → Login
///
/// Na primeira execução, detecta Firestore vazio e executa o seed
/// para criar o SuperAdmin.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _statusMessage = 'Carregando...';

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
        // Verificar se precisa executar seed (primeira execução)
        final seedRunner = SeedRunner();
        final alreadySeeded = await seedRunner.isSeeded();

        if (!alreadySeeded) {
          AppLogger.info('Firestore vazio — executando seed inicial...');
          if (mounted) {
            setState(() => _statusMessage = 'Configurando dados iniciais...');
          }
          await seedRunner.run(
            firebaseUid: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Admin',
            email: firebaseUser.email ?? '',
          );
          AppLogger.info('Seed concluído!');
        }

        AppLogger.info('Usuário autenticado, carregando sessão...');
        if (mounted) {
          setState(() => _statusMessage = 'Carregando sessão...');
        }
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
            LoadingIndicator(message: _statusMessage),
          ],
        ),
      ),
    );
  }
}
