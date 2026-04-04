import 'package:flutter/material.dart';
import '../../../Commons/Models/StockAlertGroupModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Card agrupado por produto para operação de avisos de estoque.
class StockAlertCard extends StatelessWidget {
  final StockAlertGroupModel group;
  final VoidCallback? onDismiss;
  final VoidCallback? onNotify;
  final bool isActionInProgress;

  const StockAlertCard({
    super.key,
    required this.group,
    this.onDismiss,
    this.onNotify,
    this.isActionInProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final urgencyColor = _urgencyColor(colors);

    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.sm),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: urgencyColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: DSSpacing.elevationSmBlur,
            offset: const Offset(0, DSSpacing.elevationSmOffset),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 54,
                  margin: const EdgeInsets.only(right: DSSpacing.sm),
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.productName, style: textStyles.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        '${group.customerCount} cliente${group.customerCount == 1 ? '' : 's'} aguardando • ${group.totalDesiredQuantity} item${group.totalDesiredQuantity == 1 ? '' : 's'} solicitados',
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
                    DSBadge(
                      label: group.hasPendingAlerts ? 'Pendente' : 'Resolvido',
                      type: group.hasPendingAlerts
                          ? DSBadgeType.warning
                          : DSBadgeType.success,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.waitTimeFormatted,
                      style: textStyles.bodySmall.copyWith(
                        color: urgencyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.sm),
            Wrap(
              spacing: DSSpacing.xs,
              runSpacing: DSSpacing.xs,
              children: [
                _InfoChip(
                  icon: Icons.people_rounded,
                  label:
                      '${group.customerCount} interessado${group.customerCount == 1 ? '' : 's'}',
                  color: colors.secundaryColor,
                ),
                _InfoChip(
                  icon: Icons.inventory_2_rounded,
                  label: 'Demanda ${group.totalDesiredQuantity} unid.',
                  color: colors.primaryColor,
                ),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: 'Desde ${group.waitTimeFormatted.toLowerCase()}',
                  color: urgencyColor,
                ),
              ],
            ),
            if (group.alerts.isNotEmpty) ...[
              const SizedBox(height: DSSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DSSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clientes aguardando',
                      style: textStyles.caption.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.xs),
                    ...group.alerts
                        .take(3)
                        .map(
                          (alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${alert.customerName} • ${alert.desiredQuantity} unid.',
                              style: textStyles.bodySmall,
                            ),
                          ),
                        ),
                    if (group.alerts.length > 3)
                      Text(
                        '+${group.alerts.length - 3} cliente${group.alerts.length - 3 == 1 ? '' : 's'} aguardando',
                        style: textStyles.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (group.hasPendingAlerts &&
                (onDismiss != null || onNotify != null)) ...[
              const SizedBox(height: DSSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isActionInProgress ? null : onDismiss,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Encerrar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.red,
                        side: BorderSide(
                          color: colors.red.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DSSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isActionInProgress ? null : onNotify,
                      icon: isActionInProgress
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.notifications_active_rounded,
                              size: 18,
                            ),
                      label: Text(
                        isActionInProgress ? 'Enviando...' : 'Notificar',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _urgencyColor(DSColors colors) {
    final days = DateTime.now().difference(group.oldestCreatedAt).inDays;
    if (days < 3) return colors.green;
    if (days < 7) return colors.orange;
    return colors.red;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
