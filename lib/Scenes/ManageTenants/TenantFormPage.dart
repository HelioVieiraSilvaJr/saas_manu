import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'TenantFormPresenter.dart';

/// Página de criação/edição de Tenant — Módulo 7.
class TenantFormPage extends StatefulWidget {
  const TenantFormPage({super.key});

  @override
  State<TenantFormPage> createState() => _TenantFormPageState();
}

class _TenantFormPageState extends State<TenantFormPage> {
  late final TenantFormPresenter _presenter;
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _presenter = TenantFormPresenter();
    _presenter.onUpdate = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final tenantId = ModalRoute.of(context)?.settings.arguments as String?;
      if (tenantId != null) {
        _presenter.initWithTenant(tenantId);
      }
    }
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final success = await _presenter.save(_formKey);
    if (success && mounted) {
      final temporaryPassword = _presenter.lastCreatedTemporaryPassword;
      final creationMessage = _presenter.lastCreatedAdminWasNewUser
          ? temporaryPassword != null && temporaryPassword.isNotEmpty
                ? 'Tenant criado com sucesso. Senha temporária do admin: $temporaryPassword'
                : 'Tenant criado com sucesso. O admin inicial foi provisionado no backend.'
          : 'Tenant criado com sucesso. O admin inicial já existia na plataforma.';
      DSAlertDialog.showSuccess(
        context: context,
        title: _presenter.isEditing ? 'Tenant atualizado' : 'Tenant criado',
        message: _presenter.isEditing
            ? 'As alterações foram salvas com sucesso.'
            : creationMessage,
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final isWeb = MediaQuery.of(context).size.width >= 1000;

    return AppShell(
      currentRoute: '/admin/tenants',
      child: _presenter.isLoading
          ? const LoadingIndicator(message: 'Carregando tenant...')
          : Scaffold(
              backgroundColor: colors.background,
              appBar: AppBar(
                title: Text(
                  _presenter.isEditing ? 'Editar Tenant' : 'Novo Tenant',
                  style: textStyles.headline2,
                ),
                backgroundColor: colors.cardBackground,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? DSSpacing.xxxl : DSSpacing.md,
                  vertical: DSSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildForm(colors, textStyles),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildForm(DSColors colors, DSTextStyle textStyles) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome
          FormTextField(
            label: 'Nome do Tenant',
            controller: _presenter.nameController,
            validator: _presenter.validateName,
            prefixIcon: Icons.business_outlined,
            hintText: 'Ex: Empresa XYZ',
            maxLength: 100,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: DSSpacing.md),

          // E-mail
          FormTextField(
            label: 'E-mail de contato',
            controller: _presenter.emailController,
            validator: _presenter.validateEmail,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            hintText: 'admin@empresa.com',
            helperText: _presenter.isEditing
                ? null
                : 'Será o primeiro usuário Admin do tenant',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: DSSpacing.md),

          // Telefone
          FormTextField(
            label: 'Telefone',
            controller: _presenter.phoneController,
            validator: _presenter.validatePhone,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            hintText: '(00) 00000-0000',
            inputFormatters: [_phoneMask],
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: DSSpacing.lg),

          // Plano
          Text(
            'Plano',
            style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DSSpacing.sm),
          _buildPlanSelector(colors, textStyles),
          const SizedBox(height: DSSpacing.lg),

          // Ativo
          Row(
            children: [
              Text(
                'Status:',
                style: textStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: DSSpacing.md),
              Switch(
                value: _presenter.isActive,
                onChanged: (v) => _presenter.setActive(v),
                activeThumbColor: colors.primaryColor,
              ),
              Text(
                _presenter.isActive ? 'Ativo' : 'Inativo',
                style: textStyles.bodyMedium.copyWith(
                  color: _presenter.isActive ? colors.green : colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xxl),

          // Error message
          if (_presenter.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(DSSpacing.sm),
              decoration: BoxDecoration(
                color: colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colors.red, size: 20),
                  const SizedBox(width: DSSpacing.sm),
                  Expanded(
                    child: Text(
                      _presenter.errorMessage!,
                      style: textStyles.bodySmall.copyWith(color: colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DSSpacing.md),
          ],

          // Botões
          Row(
            children: [
              Expanded(
                child: DSButton.secondary(
                  label: 'Cancelar',
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: DSSpacing.md),
              Expanded(
                child: DSButton.primary(
                  label: _presenter.isEditing ? 'Salvar' : 'Criar Tenant',
                  icon: _presenter.isEditing
                      ? Icons.save_rounded
                      : Icons.add_rounded,
                  isLoading: _presenter.isSaving,
                  onTap: _onSave,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(DSColors colors, DSTextStyle textStyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlanRadio(
          value: 'trial',
          title: 'Trial',
          description: '30 dias grátis para teste',
          icon: Icons.hourglass_top_rounded,
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(height: DSSpacing.sm),
        _buildPlanRadio(
          value: 'monthly',
          title: 'Mensal',
          description: 'Renovação a cada 30 dias',
          icon: Icons.calendar_month_rounded,
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(height: DSSpacing.sm),
        _buildPlanRadio(
          value: 'quarterly',
          title: 'Trimestral',
          description: 'Renovação a cada 90 dias',
          icon: Icons.date_range_rounded,
          colors: colors,
          textStyles: textStyles,
        ),

        // Tier selector (only for paid plans)
        if (_presenter.selectedPlan != 'trial') ...[
          const SizedBox(height: DSSpacing.lg),
          Text(
            'Nível do Plano',
            style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: DSSpacing.sm),
          _buildTierRadio(
            value: 'standard',
            title: 'Standard',
            description: 'Até 1.000 clientes e 50 produtos',
            icon: Icons.star_border_rounded,
            colors: colors,
            textStyles: textStyles,
          ),
          const SizedBox(height: DSSpacing.sm),
          _buildTierRadio(
            value: 'pro',
            title: 'Pro',
            description: 'Clientes ilimitados e até 500 produtos',
            icon: Icons.star_rounded,
            colors: colors,
            textStyles: textStyles,
          ),
        ],
      ],
    );
  }

  Widget _buildTierRadio({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final isSelected = _presenter.selectedPlanTier == value;

    return InkWell(
      onTap: () => _presenter.setPlanTier(value),
      borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colors.primaryColor : colors.inputBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          color: isSelected
              ? colors.primaryColor.withValues(alpha: 0.05)
              : colors.cardBackground,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _presenter.selectedPlanTier,
              onChanged: (v) {
                if (v != null) _presenter.setPlanTier(v);
              },
              activeColor: colors.primaryColor,
            ),
            Icon(
              icon,
              color: isSelected ? colors.primaryColor : colors.textTertiary,
            ),
            const SizedBox(width: DSSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colors.primaryColor
                          : colors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanRadio({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final isSelected = _presenter.selectedPlan == value;

    return InkWell(
      onTap: () => _presenter.setPlan(value),
      borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colors.primaryColor : colors.inputBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          color: isSelected
              ? colors.primaryColor.withValues(alpha: 0.05)
              : colors.cardBackground,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _presenter.selectedPlan,
              onChanged: (v) {
                if (v != null) _presenter.setPlan(v);
              },
              activeColor: colors.primaryColor,
            ),
            Icon(
              icon,
              color: isSelected ? colors.primaryColor : colors.textTertiary,
            ),
            const SizedBox(width: DSSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colors.primaryColor
                          : colors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
