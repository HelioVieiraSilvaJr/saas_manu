import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/PlanCatalogModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../SuperAdminPlans/PlanCatalogRepository.dart';
import '../TenantSettingsViewModel.dart';

/// Widget da seção "Plano & Assinatura" — Módulo 8.
class PlanSection extends StatelessWidget {
  final TenantSettingsViewModel viewModel;
  final _planRepository = PlanCatalogRepository();

  PlanSection({super.key, required this.viewModel});

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
          StreamBuilder<List<PlanCatalogModel>>(
            stream: _planRepository.watchAll(),
            builder: (context, snapshot) {
              final plans =
                  (snapshot.data ?? PlanCatalogModel.defaults)
                      .where((plan) => plan.isActive)
                      .toList()
                    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
              return _buildPlanCards(context, colors, textStyles, plans);
            },
          ),
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
    List<PlanCatalogModel> plans,
  ) {
    return Column(
      children: plans.asMap().entries.map((entry) {
        final plan = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: entry.key == plans.length - 1 ? 0 : DSSpacing.md,
          ),
          child: _buildPlanCard(
            context: context,
            plan: plan,
            colors: colors,
            textStyles: textStyles,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required PlanCatalogModel plan,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final currentCombo = viewModel.isTrial
        ? 'trial'
        : viewModel.currentPlanTier == 'pro'
        ? '${viewModel.currentPlan}_pro'
        : viewModel.currentPlan;
    final isCurrent = currentCombo == plan.id;

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
                plan.displayName,
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
            plan.billingLabel,
            style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DSSpacing.xxs),
          Text(
            plan.limitsLabel,
            style: textStyles.bodySmall.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: DSSpacing.md),
          ...plan.features.map(
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
              label: 'Selecionar ${plan.displayName}',
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
    Navigator.pushNamed(context, '/upgrade');
  }

  DSBadgeType get _currentPlanBadgeType {
    switch (viewModel.currentPlan) {
      case 'trial':
        return DSBadgeType.warning;
      case 'monthly':
        return DSBadgeType.info;
      case 'quarterly':
        return DSBadgeType.success;
      default:
        return DSBadgeType.info;
    }
  }

  Color _currentPlanColor(DSColors colors) {
    switch (viewModel.currentPlan) {
      case 'trial':
        return colors.yellow;
      case 'monthly':
        return colors.blue;
      case 'quarterly':
        return colors.green;
      default:
        return colors.blue;
    }
  }
}
