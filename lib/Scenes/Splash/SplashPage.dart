import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Commons/Widgets/DesignSystem/FormTextField.dart';
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

        if (kDebugMode && !alreadySeeded) {
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

        if (!mounted) return;

        // Verificar trial expirado (exceto superAdmin)
        final session = SessionManager.instance;
        if (!session.isSuperAdmin &&
            session.currentTenant != null &&
            session.currentTenant!.isTrialExpired) {
          AppLogger.warning(
            'Trial expirado para tenant: ${session.currentTenant!.name}',
          );
          await _showTrialExpiredDialog();
          return; // Não navega — dialog controla o fluxo
        }

        // Verificar primeiro login com senha temporária.
        if (session.currentUser?.requiresPasswordReset == true) {
          AppLogger.info('Primeiro login detectado — forçando troca de senha');
          final changed = await _showForceChangePasswordDialog();
          if (!changed || !mounted) return;
        }

        if (mounted) {
          final route = session.isSuperAdmin
              ? '/admin/dashboard'
              : '/dashboard';
          Navigator.of(context).pushReplacementNamed(route);
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

  // MARK: - Helpers

  // MARK: - Trial Expired Dialog

  Future<void> _showTrialExpiredDialog() async {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(DSSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.timer_off_rounded, size: 48, color: colors.yellow),
                const SizedBox(height: DSSpacing.base),
                Text(
                  'Período Trial Expirado',
                  style: textStyles.headline3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DSSpacing.sm),
                Text(
                  'Seu período de avaliação gratuita chegou ao fim. '
                  'Entre em contato com o suporte para contratar um plano e continuar usando o sistema.',
                  style: textStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DSSpacing.xl),
                DSButton.primary(
                  label: 'Sair',
                  icon: Icons.logout,
                  isExpanded: true,
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    await SessionManager.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // MARK: - Force Change Password Dialog

  /// Retorna true se a senha foi alterada com sucesso.
  Future<bool> _showForceChangePasswordDialog() async {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool isPasswordVisible = false;
    String? errorMessage;
    bool success = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(DSSpacing.xxl),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.security_rounded,
                        size: 48,
                        color: colors.primaryColor,
                      ),
                      const SizedBox(height: DSSpacing.base),
                      Text(
                        'Troca de Senha Obrigatória',
                        style: textStyles.headline3,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DSSpacing.sm),
                      Text(
                        'Por segurança, defina uma nova senha para continuar.',
                        style: textStyles.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DSSpacing.xl),
                      FormTextField(
                        label: 'Nova Senha',
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        prefixIcon: Icons.lock_outline,
                        hintText: 'Mínimo 7 caracteres',
                        suffix: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                          child: Icon(
                            isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: colors.greyLight,
                            size: DSSpacing.iconMd,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nova senha é obrigatória';
                          }
                          if (value.length < 7) {
                            return 'Mínimo 7 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: DSSpacing.base),
                      FormTextField(
                        label: 'Confirmar Senha',
                        controller: confirmController,
                        obscureText: !isPasswordVisible,
                        prefixIcon: Icons.lock_outline,
                        hintText: 'Repita a nova senha',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirmação é obrigatória';
                          }
                          if (value != passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: DSSpacing.base),
                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(DSSpacing.md),
                          decoration: BoxDecoration(
                            color: colors.redLight,
                            borderRadius: BorderRadius.circular(
                              DSSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            errorMessage!,
                            style: textStyles.bodySmall.copyWith(
                              color: colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: DSSpacing.base),
                      ],
                      DSButton.primary(
                        label: 'Alterar Senha',
                        icon: Icons.check,
                        isLoading: isLoading,
                        isExpanded: true,
                        onTap: isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                setDialogState(() {
                                  isLoading = true;
                                  errorMessage = null;
                                });

                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user == null) throw Exception('Erro');
                                  await user.updatePassword(
                                    passwordController.text,
                                  );
                                  AppLogger.info(
                                    'Senha alterada com sucesso (splash)',
                                  );
                                  success = true;
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                } catch (e) {
                                  AppLogger.error('Erro ao alterar senha: $e');
                                  setDialogState(() {
                                    isLoading = false;
                                    errorMessage =
                                        'Erro ao alterar senha. Tente novamente.';
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();

    if (success && mounted) {
      await DSAlertDialog.showSuccess(
        context: context,
        title: 'Senha Alterada',
        message: 'Sua senha foi alterada com sucesso!',
      );
    }

    return success;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: colors.primaryGradient,
                borderRadius: BorderRadius.circular(DSSpacing.radiusXl),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: DSSpacing.xxl),
            LoadingIndicator(message: _statusMessage),
          ],
        ),
      ),
    );
  }
}
