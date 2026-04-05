import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../Commons/Constants/AppConstants.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../LoginPresenter.dart';
import '../LoginViewModel.dart';

/// View Mobile da tela de Login.
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
    final vm = widget.viewModel;

    return Scaffold(
      backgroundColor: colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.xl,
            vertical: DSSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DSSpacing.lg),
              _buildHeader(colors),
              const SizedBox(height: DSSpacing.xl),
              if (vm.showForgotPasswordForm)
                _buildForgotPasswordForm(colors)
              else if (vm.showRegisterForm)
                _buildRegisterForm(colors)
              else
                _buildLoginForm(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DSColors colors) {
    final textStyles = DSTextStyle();
    return Column(
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: colors.primaryGradient,
              borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: DSSpacing.xl),
        Text(
          AppConstants.appName,
          style: textStyles.headline1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.sm),
        Text(
          'Transforme seu WhatsApp em um vendedor com IA conectado ao seu catálogo.',
          style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.sm),
        Text(
          'Versão ${AppConstants.appVersion}',
          style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(DSColors colors) {
    final textStyles = DSTextStyle();
    final vm = widget.viewModel;

    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Entrar', style: textStyles.headline2),
          const SizedBox(height: DSSpacing.sm),
          _buildFeedback(colors, vm),
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
          const SizedBox(height: DSSpacing.lg),
          DSButton.primary(
            label: 'Entrar',
            icon: Icons.login,
            isLoading: vm.isLoading,
            isExpanded: true,
            onTap: vm.isLoading ? null : _handleLogin,
          ),
          const SizedBox(height: DSSpacing.md),
          DSButton.text(
            label: 'Criar conta',
            icon: Icons.app_registration_rounded,
            onTap: widget.presenter.openRegister,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(DSColors colors) {
    final textStyles = DSTextStyle();
    final vm = widget.viewModel;

    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Criar conta', style: textStyles.headline2),
          const SizedBox(height: DSSpacing.sm),
          Text(
            'Seu tenant será criado com um administrador inicial e começará em trial.',
            style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DSSpacing.base),
          _buildFeedback(colors, vm),
          FormTextField(
            label: 'Nome do negócio',
            controller: _tenantNameController,
            prefixIcon: Icons.store_mall_directory_outlined,
            hintText: 'Ex: Loja da Maria',
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
                'Se o email já existir, apenas criaremos e vincularemos o novo tenant.',
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
          const SizedBox(height: DSSpacing.sm),
          DSButton.text(
            label: 'Voltar ao login',
            icon: Icons.arrow_back_rounded,
            onTap: widget.presenter.openLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordForm(DSColors colors) {
    final textStyles = DSTextStyle();
    final vm = widget.viewModel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Recuperar senha', style: textStyles.headline2),
        const SizedBox(height: DSSpacing.sm),
        Text(
          'Digite o email da sua conta para receber o link de recuperação.',
          style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: DSSpacing.base),
        _buildFeedback(colors, vm),
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

  Widget _buildFeedback(DSColors colors, LoginViewModel vm) {
    if (vm.errorMessage == null && vm.successMessage == null) {
      return const SizedBox.shrink();
    }

    final textStyles = DSTextStyle();
    final isError = vm.errorMessage != null;
    final message = vm.errorMessage ?? vm.successMessage!;

    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.base),
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: isError ? colors.redLight : colors.greenLight,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? colors.red : colors.green,
            size: DSSpacing.iconMd,
          ),
          const SizedBox(width: DSSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: textStyles.bodySmall.copyWith(
                color: isError ? colors.red : colors.green,
              ),
            ),
          ),
        ],
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
      return 'Mínimo 7 caracteres';
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
