import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import 'LoginPresenter.dart';
import 'LoginCoordinator.dart';
import 'Web/LoginWebView.dart';
import 'Mobile/LoginMobileView.dart';

/// Página principal de Login.
///
/// Usa ScreenResponsive para alternar entre Web e Mobile views.
/// Gerencia o Presenter e trata o primeiro login (troca de senha obrigatória).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginPresenter _presenter = LoginPresenter();
  final LoginCoordinator _coordinator = LoginCoordinator();

  @override
  void initState() {
    super.initState();
    _presenter.onViewModelUpdated = () {
      if (mounted) setState(() {});

      // Verificar se é primeiro login para mostrar modal de troca de senha
      if (_presenter.viewModel.isFirstLogin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showForceChangePasswordDialog();
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return ScreenResponsive(
      web: LoginWebView(
        presenter: _presenter,
        viewModel: _presenter.viewModel,
        onLoginSuccess: () => _coordinator.navigateToDashboard(context),
      ),
      mobile: LoginMobileView(
        presenter: _presenter,
        viewModel: _presenter.viewModel,
        onLoginSuccess: () => _coordinator.navigateToDashboard(context),
      ),
    );
  }

  // MARK: - Force Change Password Dialog

  Future<void> _showForceChangePasswordDialog() async {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool isPasswordVisible = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false, // Não pode fechar
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
                      // Ícone
                      Icon(
                        Icons.security_rounded,
                        size: 48,
                        color: colors.primaryColor,
                      ),
                      const SizedBox(height: DSSpacing.base),

                      // Título
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

                      // Nova Senha
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

                      // Confirmar Senha
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

                      // Erro
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

                      // Botão Alterar
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

                                final success = await _presenter.changePassword(
                                  passwordController.text,
                                );

                                if (success) {
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }

                                  if (!mounted) return;

                                  await DSAlertDialog.showSuccess(
                                    context: this.context,
                                    title: 'Senha Alterada',
                                    message:
                                        'Sua senha foi alterada com sucesso!',
                                  );

                                  if (!mounted) return;
                                  _coordinator.navigateToDashboard(
                                    this.context,
                                  );
                                } else {
                                  setDialogState(() {
                                    isLoading = false;
                                    errorMessage =
                                        _presenter.viewModel.errorMessage ??
                                        'Erro ao alterar senha.';
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
  }
}
