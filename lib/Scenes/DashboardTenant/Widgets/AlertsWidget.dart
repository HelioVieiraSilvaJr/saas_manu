import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../DashboardTenantViewModel.dart';

/// Widget de alertas/notificações do Dashboard.
///
/// Exibe alertas dispensáveis com prioridade e limite de 3 visíveis.
class AlertsWidget extends StatelessWidget {
  final List<DashboardAlert> alerts;
  final ValueChanged<DashboardAlert>? onDismiss;
  final ValueChanged<DashboardAlert>? onAction;

  const AlertsWidget({
    super.key,
    required this.alerts,
    this.onDismiss,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: alerts
          .map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: DSSpacing.sm),
              child: _AlertCard(
                alert: alert,
                onDismiss: onDismiss != null ? () => onDismiss!(alert) : null,
                onAction: onAction != null ? () => onAction!(alert) : null,
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Card individual de alerta.
class _AlertCard extends StatelessWidget {
  final DashboardAlert alert;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;

  const _AlertCard({required this.alert, this.onDismiss, this.onAction});

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData alertIcon;

    if (alert.isWarning) {
      bgColor = colors.yellowLight;
      borderColor = colors.orange.withValues(alpha: 0.3);
      iconColor = colors.orange;
      alertIcon = Icons.warning_amber_rounded;
    } else {
      bgColor = colors.blueLight;
      borderColor = colors.blue.withValues(alpha: 0.3);
      iconColor = colors.blue;
      alertIcon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone
          Icon(alertIcon, color: iconColor, size: DSSpacing.iconMd),
          const SizedBox(width: DSSpacing.md),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: textStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: DSSpacing.xs),
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    alert.actionLabel,
                    style: textStyles.labelMedium.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botão fechar
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(DSSpacing.xxs),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: colors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
