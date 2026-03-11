import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../TenantSettingsPresenter.dart';
import '../TenantSettingsViewModel.dart';

/// Widget da seção "Dados da Empresa" — Módulo 8.
class CompanyDataSection extends StatelessWidget {
  final TenantSettingsPresenter presenter;
  final TenantSettingsViewModel viewModel;
  final GlobalKey<FormState> formKey;

  CompanyDataSection({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.formKey,
  });

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 20,
                  color: colors.textTertiary,
                ),
                const SizedBox(width: DSSpacing.sm),
                Text('Dados da Empresa', style: textStyles.headline3),
              ],
            ),
            const SizedBox(height: DSSpacing.lg),

            // Nome
            FormTextField(
              label: 'Nome da Empresa',
              controller: presenter.nameController,
              validator: presenter.validateCompanyName,
              prefixIcon: Icons.business_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            // Email
            FormTextField(
              label: 'Email de Contato',
              controller: presenter.emailController,
              validator: presenter.validateCompanyEmail,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            // Telefone
            FormTextField(
              label: 'Telefone / WhatsApp',
              controller: presenter.phoneController,
              validator: presenter.validateCompanyPhone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              hintText: '(00) 00000-0000',
              inputFormatters: [_phoneMask],
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: DSSpacing.lg),

            // Botão salvar
            Align(
              alignment: Alignment.centerRight,
              child: DSButton.primary(
                label: 'Salvar Alterações',
                icon: Icons.save_rounded,
                isLoading: viewModel.isSavingCompany,
                onTap: () => presenter.saveCompanyData(formKey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
