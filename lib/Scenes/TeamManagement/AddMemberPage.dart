import 'package:flutter/material.dart';
import '../../Commons/Enums/UserRole.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../../Sources/Coordinators/AppShell.dart';
import '../../Sources/SessionManager.dart';
import 'AddMemberPresenter.dart';

/// Página de Adicionar Membro à Equipe — Módulo 9.
class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _presenter = AddMemberPresenter();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _presenter.onUpdate = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Guard
    if (!SessionManager.instance.canManageTenant()) {
      return AppShell(
        currentRoute: '/team',
        child: const Center(child: Text('Acesso não autorizado.')),
      );
    }

    final colors = DSColors();
    final textStyles = DSTextStyle();

    return AppShell(
      currentRoute: '/team',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.pagePaddingHorizontalWeb,
          vertical: DSSpacing.pagePaddingVerticalWeb,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      Text('Adicionar Membro', style: textStyles.headline1),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.xl),

                  // Card do formulário
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DSSpacing.cardPaddingLg),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        FormTextField(
                          label: 'Email *',
                          hintText: 'usuario@email.com',
                          controller: _presenter.emailController,
                          validator: _presenter.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: DSSpacing.xxs),
                        Text(
                          'Se já existir na plataforma, será adicionado a este tenant.',
                          style: textStyles.bodySmall.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: DSSpacing.lg),

                        // Nome
                        FormTextField(
                          label: 'Nome Completo *',
                          hintText: 'João Santos',
                          controller: _presenter.nameController,
                          validator: _presenter.validateName,
                        ),
                        const SizedBox(height: DSSpacing.xxs),
                        Text(
                          'Usado apenas se for novo usuário.',
                          style: textStyles.bodySmall.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: DSSpacing.lg),

                        // Permissão
                        Text(
                          'Permissão *',
                          style: textStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: DSSpacing.sm),
                        _buildRoleOption(
                          role: UserRole.tenantAdmin,
                          colors: colors,
                          textStyles: textStyles,
                        ),
                        const SizedBox(height: DSSpacing.sm),
                        _buildRoleOption(
                          role: UserRole.user,
                          colors: colors,
                          textStyles: textStyles,
                        ),
                        const SizedBox(height: DSSpacing.xl),

                        // Ações
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            DSButton.text(
                              label: 'Cancelar',
                              onTap: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: DSSpacing.md),
                            DSButton.primary(
                              label: 'Adicionar',
                              icon: Icons.person_add_outlined,
                              isLoading: _presenter.isAdding,
                              onTap: _presenter.isAdding
                                  ? null
                                  : () =>
                                        _presenter.addMember(context, _formKey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final isSelected = _presenter.selectedRole == role;

    return InkWell(
      onTap: () => _presenter.setRole(role),
      borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryColor.withValues(alpha: 0.05)
              : colors.scaffoldBackground,
          borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? colors.primaryColor : colors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? colors.primaryColor : colors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: DSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: textStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colors.primaryColor
                          : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.description,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
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
