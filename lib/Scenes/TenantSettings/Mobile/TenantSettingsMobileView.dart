import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../TenantSettingsPresenter.dart';
import '../TenantSettingsViewModel.dart';
import '../Widgets/CompanyDataSection.dart';
import '../Widgets/IntegrationsSection.dart';
import '../Widgets/PlanSection.dart';

/// Configurações do Tenant — Layout Mobile (< 1000px).
///
/// ScrollView com as 3 seções empilhadas verticalmente.
class TenantSettingsMobileView extends StatelessWidget {
  final TenantSettingsPresenter presenter;
  final TenantSettingsViewModel viewModel;
  final GlobalKey<FormState> companyFormKey;

  const TenantSettingsMobileView({
    super.key,
    required this.presenter,
    required this.viewModel,
    required this.companyFormKey,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando configurações...');
    }

    final textStyles = DSTextStyle();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DSSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text('Configurações', style: textStyles.headline2),
          const SizedBox(height: DSSpacing.base),

          // Seção 1: Dados da Empresa
          CompanyDataSection(
            presenter: presenter,
            viewModel: viewModel,
            formKey: companyFormKey,
          ),
          const SizedBox(height: DSSpacing.base),

          // Seção 2: Integrações
          IntegrationsSection(presenter: presenter, viewModel: viewModel),
          const SizedBox(height: DSSpacing.base),

          // Seção 3: Plano & Assinatura
          PlanSection(viewModel: viewModel),
          const SizedBox(height: DSSpacing.xl),
        ],
      ),
    );
  }
}
