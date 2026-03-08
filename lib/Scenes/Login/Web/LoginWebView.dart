import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../LoginPresenter.dart';
import '../LoginViewModel.dart';

/// View Web da tela de Login.
///
/// Layout: Card centralizado com ilustração de fundo.
class LoginWebView extends StatefulWidget {
  final LoginPresenter presenter;
  final LoginViewModel viewModel;
  final VoidCallback onLoginSuccess;

  const LoginWebView({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.onLoginSuccess,
  });

  @override
  State<LoginWebView> createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {
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
    final textStyles = DSTextStyle();
    final vm = widget.viewModel;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Background decorativo
          _buildBackground(colors),

          // Conteúdo centralizado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DSSpacing.xl),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: colors.white,
                  borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowColor,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(DSSpacing.xxl),
                child: vm.showForgotPasswordForm
                    ? _buildForgotPasswordForm(colors, textStyles, vm)
                    : _buildLoginForm(colors, textStyles, vm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Login Form

  Widget _buildLoginForm(
    DSColors colors,
    DSTextStyle textStyles,
    LoginViewModel vm,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo / Title
          Icon(Icons.storefront_rounded, size: 56, color: colors.primaryColor),
          const SizedBox(height: DSSpacing.base),
          Text(
            'Bem-vindo de volta',
            style: textStyles.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DSSpacing.sm),
          Text(
            'Faça login para acessar sua conta',
            style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DSSpacing.xxl),

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
                return 'Senha deve ter no mínimo 7 caracteres';
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
                style: textStyles.labelMedium.copyWith(color: colors.textLink),
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.base),

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
    );
  }

  // MARK: - Forgot Password Form

  Widget _buildForgotPasswordForm(
    DSColors colors,
    DSTextStyle textStyles,
    LoginViewModel vm,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_reset_rounded, size: 56, color: colors.primaryColor),
        const SizedBox(height: DSSpacing.base),
        Text(
          'Recuperar Senha',
          style: textStyles.headline2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.sm),
        Text(
          'Digite seu email para receber o link de recuperação',
          style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.xxl),

        if (vm.forgotPasswordSent) ...[
          // Sucesso
          Container(
            padding: const EdgeInsets.all(DSSpacing.base),
            decoration: BoxDecoration(
              color: colors.greenLight,
              borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, color: colors.green, size: 40),
                const SizedBox(height: DSSpacing.sm),
                Text(
                  'Email enviado com sucesso!',
                  style: textStyles.bodyLarge.copyWith(
                    color: colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DSSpacing.xs),
                Text(
                  'Verifique sua caixa de entrada e siga as instruções.',
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.xl),
        ] else ...[
          // Form
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

        // Voltar ao login
        DSButton.text(
          label: 'Voltar ao Login',
          icon: Icons.arrow_back,
          onTap: widget.presenter.toggleForgotPassword,
        ),
      ],
    );
  }

  // MARK: - Background

  Widget _buildBackground(DSColors colors) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryColor.withValues(alpha: 0.05),
              colors.secundaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: CustomPaint(painter: _BackgroundPatternPainter(colors: colors)),
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
    // Se isFirstLogin é true, LoginPage cuida de mostrar o modal
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

// MARK: - Background Painter

class _BackgroundPatternPainter extends CustomPainter {
  final DSColors colors;

  _BackgroundPatternPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.primaryColor.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Círculos decorativos
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 120, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 180, paint);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.1),
      80,
      paint..color = colors.secundaryColor.withValues(alpha: 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
