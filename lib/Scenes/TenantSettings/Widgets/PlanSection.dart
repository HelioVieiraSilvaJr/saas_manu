import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../TenantSettingsViewModel.dart';

/// Widget da seção "Plano & Assinatura" — Módulo 8.
class PlanSection extends StatelessWidget {
  final TenantSettingsViewModel viewModel;

  const PlanSection({super.key, required this.viewModel});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.credit_card_outlined,
                size: 20,
                color: colors.textTertiary,
              ),
              const SizedBox(width: DSSpacing.sm),
              Text('Plano & Assinatura', style: textStyles.headline3),
            ],
          ),
          const SizedBox(height: DSSpacing.lg),

          // Plano atual
          _buildCurrentPlan(context, colors, textStyles),
          const SizedBox(height: DSSpacing.xl),

          // Planos disponíveis
          Text(
            'Planos Disponíveis',
            style: textStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: DSSpacing.md),
          _buildPlanCards(context, colors, textStyles),
        ],
      ),
    );
  }

  Widget _buildCurrentPlan(
    BuildContext context,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: _currentPlanColor(colors).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(
          color: _currentPlanColor(colors).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Plano Atual:',
                style: textStyles.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(width: DSSpacing.sm),
              DSBadge(label: viewModel.planLabel, type: _currentPlanBadgeType),
            ],
          ),
          const SizedBox(height: DSSpacing.md),

          // Info do plano
          if (viewModel.isTrial && viewModel.trialEndDate != null) ...[
            _buildInfoRow(
              Icons.hourglass_top_rounded,
              'Válido até: ${viewModel.trialEndDate!.formatShort()} '
              '(${viewModel.trialDaysRemaining} dias)',
              colors,
              textStyles,
            ),
            if (viewModel.trialDaysRemaining <= 7 &&
                !viewModel.isTrialExpired) ...[
              const SizedBox(height: DSSpacing.sm),
              Container(
                padding: const EdgeInsets.all(DSSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.yellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: colors.yellow,
                    ),
                    const SizedBox(width: DSSpacing.xs),
                    Text(
                      'Seu trial expira em breve!',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.yellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (viewModel.isTrialExpired) ...[
              const SizedBox(height: DSSpacing.sm),
              Container(
                padding: const EdgeInsets.all(DSSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: colors.red),
                    const SizedBox(width: DSSpacing.xs),
                    Text(
                      'Trial expirado! Faça upgrade para continuar.',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          if (!viewModel.isTrial && viewModel.nextPaymentDate != null) ...[
            _buildInfoRow(
              Icons.payment_outlined,
              'Próximo pagamento: ${viewModel.nextPaymentDate!.formatShort()}',
              colors,
              textStyles,
            ),
          ],

          if (viewModel.isTrial) ...[
            const SizedBox(height: DSSpacing.md),
            DSButton.primary(
              label: 'Fazer Upgrade',
              icon: Icons.upgrade_rounded,
              onTap: () => _handleUpgrade(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCards(
    BuildContext context,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Column(
      children: [
        _buildPlanCard(
          context: context,
          planId: 'trial',
          name: 'Trial',
          price: 'Gratuito — 15 dias',
          features: [
            'Todas as funcionalidades',
            'Produtos ilimitados',
            'Clientes ilimitados',
          ],
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(height: DSSpacing.md),
        _buildPlanCard(
          context: context,
          planId: 'basic',
          name: 'Basic',
          price: 'R\$ 50,00/mês',
          features: [
            'Até 100 produtos',
            'Até 500 clientes',
            'Suporte por email',
          ],
          colors: colors,
          textStyles: textStyles,
        ),
        const SizedBox(height: DSSpacing.md),
        _buildPlanCard(
          context: context,
          planId: 'full',
          name: 'Full',
          price: 'R\$ 150,00/mês',
          features: [
            'Produtos ilimitados',
            'Clientes ilimitados',
            'Suporte prioritário',
            'Relatórios avançados',
          ],
          colors: colors,
          textStyles: textStyles,
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String planId,
    required String name,
    required String price,
    required List<String> features,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final isCurrent = viewModel.currentPlan == planId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: isCurrent
            ? colors.primaryColor.withValues(alpha: 0.03)
            : colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(
          color: isCurrent ? colors.primaryColor : colors.divider,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: textStyles.headline3.copyWith(
                  color: isCurrent ? colors.primaryColor : colors.textPrimary,
                ),
              ),
              const SizedBox(width: DSSpacing.sm),
              if (isCurrent)
                DSBadge(
                  label: 'Plano Atual',
                  type: DSBadgeType.primary,
                  size: DSBadgeSize.small,
                ),
            ],
          ),
          const SizedBox(height: DSSpacing.xxs),
          Text(
            price,
            style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DSSpacing.md),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: DSSpacing.xxs),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: colors.green,
                  ),
                  const SizedBox(width: DSSpacing.xs),
                  Text(f, style: textStyles.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.md),
          if (!isCurrent)
            DSButton.secondary(
              label: 'Selecionar $name',
              icon: Icons.arrow_forward_rounded,
              onTap: () => _handleUpgrade(context),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textTertiary),
        const SizedBox(width: DSSpacing.xs),
        Text(text, style: textStyles.bodyMedium),
      ],
    );
  }

  void _handleUpgrade(BuildContext context) {
    DSAlertDialog.showInfo(
      context: context,
      title: 'Upgrade de Plano',
      message:
          'Entre em contato com suporte@plataforma.com para realizar upgrade ou downgrade de plano.',
    );
  }

  DSBadgeType get _currentPlanBadgeType {
    switch (viewModel.currentPlan) {
      case 'trial':
        return DSBadgeType.warning;
      case 'basic':
        return DSBadgeType.info;
      case 'full':
        return DSBadgeType.success;
      default:
        return DSBadgeType.info;
    }
  }

  Color _currentPlanColor(DSColors colors) {
    switch (viewModel.currentPlan) {
      case 'trial':
        return colors.yellow;
      case 'basic':
        return colors.blue;
      case 'full':
        return colors.green;
      default:
        return colors.blue;
    }
  }
}
