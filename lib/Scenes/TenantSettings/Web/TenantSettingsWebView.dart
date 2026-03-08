import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../TenantSettingsPresenter.dart';
import '../TenantSettingsViewModel.dart';
import '../Widgets/CompanyDataSection.dart';
import '../Widgets/IntegrationsSection.dart';
import '../Widgets/PlanSection.dart';

/// Configurações do Tenant — Layout Web (>= 1000px).
///
/// Coluna única centralizada com as 3 seções: Dados da Empresa,
/// Integrações e Plano & Assinatura.
class TenantSettingsWebView extends StatelessWidget {
  final TenantSettingsPresenter presenter;
  final TenantSettingsViewModel viewModel;
  final GlobalKey<FormState> companyFormKey;

  const TenantSettingsWebView({
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
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text('Configurações', style: textStyles.headline1),
              const SizedBox(height: DSSpacing.xl),

              // Seção 1: Dados da Empresa
              CompanyDataSection(
                presenter: presenter,
                viewModel: viewModel,
                formKey: companyFormKey,
              ),
              const SizedBox(height: DSSpacing.xl),

              // Seção 2: Integrações
              IntegrationsSection(presenter: presenter, viewModel: viewModel),
              const SizedBox(height: DSSpacing.xl),

              // Seção 3: Plano & Assinatura
              PlanSection(viewModel: viewModel),
              const SizedBox(height: DSSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
