import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../LoginPresenter.dart';
import '../LoginViewModel.dart';

/// View Web da tela de Login.
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
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _tenantNameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    _tenantNameController.dispose();
    _adminNameController.dispose();
    _registerPhoneController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
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
          _buildBackground(colors),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DSSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _buildAside(colors, textStyles),
                  ),
                  const SizedBox(width: DSSpacing.xl),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: BoxDecoration(
                      color: colors.white,
                      borderRadius: BorderRadius.circular(DSSpacing.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadowMedium,
                          blurRadius: DSSpacing.elevationLgBlur,
                          offset: const Offset(0, DSSpacing.elevationLgOffset),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(DSSpacing.xxl),
                    child: vm.showForgotPasswordForm
                        ? _buildForgotPasswordForm(colors, textStyles, vm)
                        : vm.showRegisterForm
                        ? _buildRegisterForm(colors, textStyles, vm)
                        : _buildLoginForm(colors, textStyles, vm),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAside(DSColors colors, DSTextStyle textStyles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: colors.primaryGradient,
              borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: DSSpacing.xl),
          Text(
            'Seu vendedor com IA no WhatsApp',
            style: textStyles.headline1.copyWith(height: 1.1),
          ),
          const SizedBox(height: DSSpacing.md),
          Text(
            'Cadastre sua operação, conecte seu número e deixe o atendimento automatizado vender enquanto você cuida de produtos, pedidos e gestão.',
            style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DSSpacing.xl),
          _buildAsideFeature(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Atendimento contínuo com contexto do seu catálogo',
            colors: colors,
            textStyles: textStyles,
          ),
          const SizedBox(height: DSSpacing.md),
          _buildAsideFeature(
            icon: Icons.inventory_2_outlined,
            label: 'Venda registrada no painel assim que o cliente fecha',
            colors: colors,
            textStyles: textStyles,
          ),
          const SizedBox(height: DSSpacing.md),
          _buildAsideFeature(
            icon: Icons.groups_2_outlined,
            label:
                'Multi-tenant com cada negócio operando no seu próprio espaço',
            colors: colors,
            textStyles: textStyles,
          ),
        ],
      ),
    );
  }

  Widget _buildAsideFeature({
    required IconData icon,
    required String label,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          ),
          child: Icon(icon, color: colors.primaryColor, size: 20),
        ),
        const SizedBox(width: DSSpacing.md),
        Expanded(
          child: Text(
            label,
            style: textStyles.bodyMedium.copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(
    DSColors colors,
    DSTextStyle textStyles,
    LoginViewModel vm,
  ) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Acessar conta', style: textStyles.headline2),
          const SizedBox(height: DSSpacing.sm),
          Text(
            'Entre com seu e-mail e senha para acessar sua operação.',
            style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DSSpacing.xl),
          _buildFeedback(colors, textStyles, vm),
          FormTextField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            hintText: 'seu@email.com',
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),
          const SizedBox(height: DSSpacing.base),
          FormTextField(
            label: 'Senha',
            controller: _passwordController,
            obscureText: !vm.isPasswordVisible,
            prefixIcon: Icons.lock_outline,
            hintText: '••••••••',
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
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
            validator: _validatePassword,
          ),
          const SizedBox(height: DSSpacing.sm),
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
          DSButton.primary(
            label: 'Entrar',
            icon: Icons.login,
            isLoading: vm.isLoading,
            isExpanded: true,
            onTap: vm.isLoading ? null : _handleLogin,
          ),
          const SizedBox(height: DSSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ainda não tem conta?',
                style: textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              DSButton.text(
                label: 'Criar tenant',
                onTap: widget.presenter.openRegister,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(
    DSColors colors,
    DSTextStyle textStyles,
    LoginViewModel vm,
  ) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Criar conta', style: textStyles.headline2),
          const SizedBox(height: DSSpacing.sm),
          Text(
            'Crie seu tenant, defina o administrador inicial e comece com o plano trial.',
            style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DSSpacing.xl),
          _buildFeedback(colors, textStyles, vm),
          FormTextField(
            label: 'Nome do negócio',
            controller: _tenantNameController,
            prefixIcon: Icons.store_mall_directory_outlined,
            hintText: 'Ex: Cantinho da Maria',
            textInputAction: TextInputAction.next,
            validator: _validateRequiredName,
          ),
          const SizedBox(height: DSSpacing.base),
          FormTextField(
            label: 'Nome do responsável',
            controller: _adminNameController,
            prefixIcon: Icons.person_outline,
            hintText: 'Ex: Maria Oliveira',
            textInputAction: TextInputAction.next,
            validator: _validateRequiredName,
          ),
          const SizedBox(height: DSSpacing.base),
          FormTextField(
            label: 'Telefone',
            controller: _registerPhoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            hintText: '(00) 00000-0000',
            inputFormatters: [_phoneMask],
            textInputAction: TextInputAction.next,
            validator: _validatePhone,
          ),
          const SizedBox(height: DSSpacing.base),
          FormTextField(
            label: 'Email',
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            hintText: 'seu@email.com',
            helperText:
                'Se o email já existir, o sistema criará apenas o novo tenant e o vinculará como tenantAdmin.',
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),
          const SizedBox(height: DSSpacing.base),
          FormTextField(
            label: 'Senha',
            controller: _registerPasswordController,
            obscureText: !vm.isPasswordVisible,
            prefixIcon: Icons.lock_outline,
            hintText: 'Mínimo 7 caracteres',
            textInputAction: TextInputAction.next,
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
            validator: _validatePassword,
          ),
          const SizedBox(height: DSSpacing.base),
          FormTextField(
            label: 'Confirmar senha',
            controller: _registerConfirmPasswordController,
            obscureText: !vm.isPasswordVisible,
            prefixIcon: Icons.lock_reset_outlined,
            hintText: 'Repita a senha',
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirme a senha';
              }
              if (value != _registerPasswordController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
          const SizedBox(height: DSSpacing.lg),
          DSButton.primary(
            label: 'Criar conta e tenant',
            icon: Icons.app_registration_rounded,
            isLoading: vm.isLoading,
            isExpanded: true,
            onTap: vm.isLoading ? null : _handleRegister,
          ),
          const SizedBox(height: DSSpacing.md),
          DSButton.text(
            label: 'Já tenho conta',
            icon: Icons.arrow_back_rounded,
            onTap: widget.presenter.openLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordForm(
    DSColors colors,
    DSTextStyle textStyles,
    LoginViewModel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_reset_rounded, size: 56, color: colors.secundaryColor),
        const SizedBox(height: DSSpacing.base),
        Text(
          'Recuperar senha',
          style: textStyles.headline2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.sm),
        Text(
          'Digite seu email para receber o link de recuperação.',
          style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.xl),
        _buildFeedback(colors, textStyles, vm),
        if (!vm.forgotPasswordSent) ...[
          FormTextField(
            label: 'Email',
            controller: _forgotEmailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            hintText: 'seu@email.com',
            validator: _validateEmail,
          ),
          const SizedBox(height: DSSpacing.base),
          DSButton.primary(
            label: 'Enviar link',
            icon: Icons.send_rounded,
            isLoading: vm.isLoading,
            isExpanded: true,
            onTap: vm.isLoading ? null : _handleForgotPassword,
          ),
        ],
        const SizedBox(height: DSSpacing.md),
        DSButton.text(
          label: 'Voltar ao login',
          icon: Icons.arrow_back,
          onTap: widget.presenter.openLogin,
        ),
      ],
    );
  }

  Widget _buildFeedback(
    DSColors colors,
    DSTextStyle textStyles,
    LoginViewModel vm,
  ) {
    if (vm.errorMessage == null && vm.successMessage == null) {
      return const SizedBox.shrink();
    }

    final isError = vm.errorMessage != null;
    final background = isError ? colors.redLight : colors.greenLight;
    final foreground = isError ? colors.red : colors.green;
    final message = vm.errorMessage ?? vm.successMessage!;

    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.base),
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: foreground,
            size: DSSpacing.iconMd,
          ),
          const SizedBox(width: DSSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: textStyles.bodySmall.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(DSColors colors) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryColor.withValues(alpha: 0.06),
              colors.secundaryColor.withValues(alpha: 0.08),
              colors.background,
            ],
          ),
        ),
        child: CustomPaint(painter: _BackgroundPatternPainter(colors: colors)),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final success = await widget.presenter.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success) {
      widget.onLoginSuccess();
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    final success = await widget.presenter.register(
      tenantName: _tenantNameController.text,
      adminName: _adminNameController.text,
      email: _registerEmailController.text,
      phone: _registerPhoneController.text,
      password: _registerPasswordController.text,
    );

    if (success) {
      widget.onLoginSuccess();
    } else if (!widget.presenter.viewModel.showRegisterForm) {
      _emailController.text = _registerEmailController.text.trim();
      _passwordController.clear();
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty) {
      widget.presenter.viewModel = widget.presenter.viewModel.copyWith(
        errorMessage: 'Digite seu email',
        successMessage: null,
      );
      widget.presenter.onViewModelUpdated?.call();
      return;
    }
    await widget.presenter.sendPasswordReset(email);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email é obrigatório';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Formato de email inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 7) {
      return 'Senha deve ter no mínimo 7 caracteres';
    }
    return null;
  }

  String? _validateRequiredName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Use pelo menos 3 caracteres';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone inválido';
    }
    return null;
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final DSColors colors;

  _BackgroundPatternPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.primaryColor.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.18),
      140,
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.8), 180, paint);
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.14),
      90,
      paint..color = colors.secundaryColor.withValues(alpha: 0.04),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
