import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../Commons/Enums/BusinessSegment.dart';
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
            const SizedBox(height: DSSpacing.md),

            Text('Segmento do Negócio', style: textStyles.textFieldLabel),
            const SizedBox(height: 6),
            DropdownButtonFormField<BusinessSegment>(
              initialValue: BusinessSegment.fromString(
                viewModel.businessSegment,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.inputBackground,
                prefixIcon: Icon(
                  Icons.category_outlined,
                  color: colors.greyLight,
                  size: DSSpacing.iconMd,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.md,
                  vertical: DSSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                  borderSide: BorderSide(
                    color: colors.inputBorderFocused,
                    width: 2,
                  ),
                ),
              ),
              items: BusinessSegment.values.map((segment) {
                return DropdownMenuItem<BusinessSegment>(
                  value: segment,
                  child: Text(segment.label, style: textStyles.textField),
                );
              }).toList(),
              onChanged: presenter.updateBusinessSegment,
            ),
            const SizedBox(height: DSSpacing.md),

            FormTextField(
              label: 'Subsegmento',
              controller: presenter.businessSubsegmentController,
              prefixIcon: Icons.label_outline,
              hintText: 'Ex: Moda feminina casual, Marmitas fitness...',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            FormTextField(
              label: 'Descrição do Negócio',
              controller: presenter.businessDescriptionController,
              prefixIcon: Icons.storefront_outlined,
              hintText: 'Explique o que a empresa vende e seus diferenciais.',
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            FormTextField(
              label: 'Público-alvo',
              controller: presenter.targetAudienceController,
              prefixIcon: Icons.groups_outlined,
              hintText: 'Ex: mulheres 25-45, famílias, empresas...',
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            FormTextField(
              label: 'Tom de voz da marca',
              controller: presenter.toneOfVoiceController,
              prefixIcon: Icons.record_voice_over_outlined,
              hintText: 'Ex: acolhedor, premium, técnico, descontraído...',
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            FormTextField(
              label: 'Horário de atendimento',
              controller: presenter.businessHoursController,
              prefixIcon: Icons.schedule_outlined,
              hintText: 'Ex: seg-sex 08h às 18h, sáb 09h às 13h',
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            FormTextField(
              label: 'Playbook de vendas',
              controller: presenter.salesPlaybookController,
              prefixIcon: Icons.psychology_outlined,
              hintText:
                  'Argumentos de venda, objeções comuns, gatilhos e ofertas que convertem melhor.',
              maxLines: 4,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            FormTextField(
              label: 'Políticas de entrega',
              controller: presenter.deliveryPoliciesController,
              prefixIcon: Icons.local_shipping_outlined,
              hintText: 'Prazo, retirada, regiões atendidas, frete...',
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            FormTextField(
              label: 'Políticas de pagamento',
              controller: presenter.paymentPoliciesController,
              prefixIcon: Icons.payments_outlined,
              hintText: 'PIX, cartão, parcelamento, sinal...',
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.md),

            FormTextField(
              label: 'Trocas e devoluções',
              controller: presenter.exchangePoliciesController,
              prefixIcon: Icons.swap_horiz_outlined,
              hintText: 'Prazo de troca, condições, regras de devolução...',
              maxLines: 3,
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
