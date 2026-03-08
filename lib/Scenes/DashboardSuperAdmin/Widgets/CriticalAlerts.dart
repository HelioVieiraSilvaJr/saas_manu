import 'package:flutter/material.dart';
import '../../../Commons/Models/TenantModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Widget de alertas críticos do Dashboard SuperAdmin.
class CriticalAlerts extends StatelessWidget {
  final List<TenantModel> trialExpiring;
  final int inactiveCount;
  final VoidCallback? onViewTrialExpiring;
  final VoidCallback? onViewInactive;

  const CriticalAlerts({
    super.key,
    required this.trialExpiring,
    required this.inactiveCount,
    this.onViewTrialExpiring,
    this.onViewInactive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    if (trialExpiring.isEmpty && inactiveCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: colors.orange, size: 20),
              const SizedBox(width: DSSpacing.xs),
              Text('Alertas Críticos', style: textStyles.headline3),
            ],
          ),
          const SizedBox(height: DSSpacing.sm),

          // Trial expirando
          if (trialExpiring.isNotEmpty)
            _buildAlertItem(
              icon: Icons.timer_off,
              iconColor: colors.orange,
              text:
                  '${trialExpiring.length} tenant(s) com trial expirando em 3 dias',
              onTap: onViewTrialExpiring,
              colors: colors,
              textStyles: textStyles,
            ),

          // Inativos
          if (inactiveCount > 0)
            _buildAlertItem(
              icon: Icons.info_outline,
              iconColor: colors.blue,
              text: '$inactiveCount tenant(s) inativos',
              onTap: onViewInactive,
              colors: colors,
              textStyles: textStyles,
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback? onTap,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DSSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(DSSpacing.sm),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            border: Border.all(color: iconColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: DSSpacing.sm),
              Expanded(child: Text(text, style: textStyles.bodySmall)),
              if (onTap != null)
                Icon(Icons.chevron_right, color: colors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
