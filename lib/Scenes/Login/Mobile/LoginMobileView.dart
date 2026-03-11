import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../LoginPresenter.dart';
import '../LoginViewModel.dart';

/// View Mobile da tela de Login.
///
/// Layout: Tela inteira com campos e botão na parte inferior.
class LoginMobileView extends StatefulWidget {
  final LoginPresenter presenter;
  final LoginViewModel viewModel;
  final VoidCallback onLoginSuccess;

  const LoginMobileView({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.onLoginSuccess,
  });

  @override
  State<LoginMobileView> createState() => _LoginMobileViewState();
}

class _LoginMobileViewState extends State<LoginMobileView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final vm = widget.viewModel;

    return Scaffold(
      backgroundColor: colors.white,
      body: SafeArea(
        child: vm.showForgotPasswordForm
            ? _buildForgotPasswordForm(colors)
            : _buildLoginForm(colors),
      ),
    );
  }

  // MARK: - Login Form

  Widget _buildLoginForm(DSColors colors) {
    final textStyles = DSTextStyle();
    final vm = widget.viewModel;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.xl,
        vertical: DSSpacing.xxl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: DSSpacing.huge),

            // Logo
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: DSColors().primaryGradient,
                  borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: DSSpacing.xl),

            // Título
            Text(
              'Bem-vindo\nde volta',
              style: textStyles.headline1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.sm),
            Text(
              'Faça login para continuar',
              style: textStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.xxxl),

            // Email
            FormTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              hintText: 'seu@email.com',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email é obrigatório';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Formato de email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: DSSpacing.base),

            // Senha
            FormTextField(
              label: 'Senha',
              controller: _passwordController,
              obscureText: !vm.isPasswordVisible,
              prefixIcon: Icons.lock_outline,
              hintText: '••••••••',
              textInputAction: TextInputAction.done,
              suffix: GestureDetector(
                onTap: widget.presenter.togglePasswordVisibility,
                child: Icon(
                  vm.isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.greyLight,
                  size: DSSpacing.iconMd,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Senha é obrigatória';
                }
                if (value.length < 7) {
                  return 'Mínimo 7 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: DSSpacing.sm),

            // Esqueci minha senha
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.presenter.toggleForgotPassword,
                child: Text(
                  'Esqueci minha senha',
                  style: textStyles.labelMedium.copyWith(
                    color: colors.textLink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DSSpacing.lg),

            // Erro
            if (vm.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(DSSpacing.md),
                decoration: BoxDecoration(
                  color: colors.redLight,
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colors.red,
                      size: DSSpacing.iconMd,
                    ),
                    const SizedBox(width: DSSpacing.sm),
                    Expanded(
                      child: Text(
                        vm.errorMessage!,
                        style: textStyles.bodySmall.copyWith(color: colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.base),
            ],

            // Botão Login
            DSButton.primary(
              label: 'Entrar',
              icon: Icons.login,
              isLoading: vm.isLoading,
              isExpanded: true,
              onTap: vm.isLoading ? null : _handleLogin,
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Forgot Password Form

  Widget _buildForgotPasswordForm(DSColors colors) {
    final textStyles = DSTextStyle();
    final vm = widget.viewModel;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.xl,
        vertical: DSSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: DSSpacing.huge),

          Icon(
            Icons.lock_reset_rounded,
            size: 64,
            color: colors.secundaryColor,
          ),
          const SizedBox(height: DSSpacing.xl),

          Text(
            'Recuperar\nSenha',
            style: textStyles.headline1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DSSpacing.sm),
          Text(
            'Digite seu email para receber o link de recuperação',
            style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DSSpacing.xxxl),

          if (vm.forgotPasswordSent) ...[
            Container(
              padding: const EdgeInsets.all(DSSpacing.base),
              decoration: BoxDecoration(
                color: colors.greenLight,
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: colors.green,
                    size: 48,
                  ),
                  const SizedBox(height: DSSpacing.md),
                  Text(
                    'Email enviado!',
                    style: textStyles.headline3.copyWith(color: colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DSSpacing.sm),
                  Text(
                    'Verifique sua caixa de entrada e siga as instruções.',
                    style: textStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DSSpacing.xl),
          ] else ...[
            FormTextField(
              label: 'Email',
              controller: _forgotEmailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              hintText: 'seu@email.com',
            ),
            const SizedBox(height: DSSpacing.base),

            if (vm.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(DSSpacing.md),
                decoration: BoxDecoration(
                  color: colors.redLight,
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                child: Text(
                  vm.errorMessage!,
                  style: textStyles.bodySmall.copyWith(color: colors.red),
                ),
              ),
              const SizedBox(height: DSSpacing.base),
            ],

            DSButton.primary(
              label: 'Enviar Link',
              icon: Icons.send,
              isLoading: vm.isLoading,
              isExpanded: true,
              onTap: vm.isLoading ? null : _handleForgotPassword,
            ),
            const SizedBox(height: DSSpacing.base),
          ],

          DSButton.text(
            label: 'Voltar ao Login',
            icon: Icons.arrow_back,
            onTap: widget.presenter.toggleForgotPassword,
          ),
        ],
      ),
    );
  }

  // MARK: - Handlers

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.presenter.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success) {
      widget.onLoginSuccess();
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty) {
      widget.presenter.viewModel = widget.presenter.viewModel.copyWith(
        errorMessage: 'Digite seu email',
      );
      widget.presenter.onViewModelUpdated?.call();
      return;
    }
    await widget.presenter.sendPasswordReset(email);
  }
}
