import 'package:flutter/material.dart';
import '../../../Commons/Enums/StockAlertStatus.dart';
import '../../../Commons/Models/StockAlertModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Card de aviso de estoque reutilizável (mobile + web).
class StockAlertCard extends StatelessWidget {
  final StockAlertModel alert;
  final VoidCallback? onDismiss;
  final VoidCallback? onNotified;
  final VoidCallback? onWhatsApp;
  final bool isActionInProgress;

  const StockAlertCard({
    super.key,
    required this.alert,
    this.onDismiss,
    this.onNotified,
    this.onWhatsApp,
    this.isActionInProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final daysColor = _getDaysColor(colors);

    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.sm),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(
          color: alert.isPending
              ? daysColor.withValues(alpha: 0.4)
              : colors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: DSSpacing.elevationSmBlur,
            offset: Offset(0, DSSpacing.elevationSmOffset),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar, nome, badge, dias
            Row(
              children: [
                // Indicador de tempo (barra lateral)
                if (alert.isPending)
                  Container(
                    width: 4,
                    height: 48,
                    margin: const EdgeInsets.only(right: DSSpacing.sm),
                    decoration: BoxDecoration(
                      color: daysColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                DSAvatar(name: alert.customerName, size: 40),
                const SizedBox(width: DSSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.customerName,
                        style: textStyles.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.customerWhatsapp,
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(colors),
                    const SizedBox(height: 4),
                    Text(
                      alert.waitTimeFormatted,
                      style: textStyles.bodySmall.copyWith(
                        color: daysColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Produto desejado
            const SizedBox(height: DSSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DSSpacing.sm),
              decoration: BoxDecoration(
                color: colors.scaffoldBackground,
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 16,
                    color: colors.primaryColor,
                  ),
                  const SizedBox(width: DSSpacing.xs),
                  Expanded(
                    child: Text(
                      alert.productName,
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Qtd: ${alert.desiredQuantity}',
                      style: textStyles.caption.copyWith(
                        color: colors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notas (se resolvido)
            if (!alert.isPending &&
                alert.notes != null &&
                alert.notes!.isNotEmpty) ...[
              const SizedBox(height: DSSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 14,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      alert.notes!,
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Ações (apenas pendentes)
            if (alert.isPending) ...[
              const SizedBox(height: DSSpacing.sm),
              Row(
                children: [
                  // WhatsApp
                  if (onWhatsApp != null)
                    _ActionChip(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: onWhatsApp!,
                    ),
                  const Spacer(),
                  // Ações
                  if (isActionInProgress)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    if (onDismiss != null)
                      OutlinedButton.icon(
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Encerrar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.red,
                          side: BorderSide(
                            color: colors.red.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DSSpacing.sm,
                            vertical: DSSpacing.xs,
                          ),
                        ),
                      ),
                    const SizedBox(width: DSSpacing.xs),
                    if (onNotified != null)
                      FilledButton.icon(
                        onPressed: onNotified,
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Notificado'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: DSSpacing.sm,
                            vertical: DSSpacing.xs,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DSColors colors) {
    DSBadgeType type;
    switch (alert.status) {
      case StockAlertStatus.pending:
        type = DSBadgeType.warning;
        break;
      case StockAlertStatus.notified:
        type = DSBadgeType.success;
        break;
      case StockAlertStatus.dismissed:
        type = DSBadgeType.error;
        break;
    }
    return DSBadge(label: alert.status.shortLabel, type: type);
  }

  Color _getDaysColor(DSColors colors) {
    final days = alert.daysSinceCreation;
    if (days < 3) return colors.green;
    if (days < 7) return colors.orange;
    return colors.red;
  }
}

/// Chip de ação compacto.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.sm,
          vertical: DSSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
