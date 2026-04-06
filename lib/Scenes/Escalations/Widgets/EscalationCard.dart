import 'package:flutter/material.dart';
import '../../../Commons/Enums/EscalationStatus.dart';
import '../../../Commons/Models/EscalationModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Card de escalação reutilizável (mobile + web).
class EscalationCard extends StatelessWidget {
  final EscalationModel escalation;
  final VoidCallback? onAssume;
  final VoidCallback? onComplete;
  final VoidCallback? onWhatsApp;
  final bool isActionInProgress;

  const EscalationCard({
    super.key,
    required this.escalation,
    this.onAssume,
    this.onComplete,
    this.onWhatsApp,
    this.isActionInProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final urgencyColor = _getUrgencyColor(colors);

    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.sm),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(
          color: escalation.isPending
              ? urgencyColor.withValues(alpha: 0.4)
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
            // Header: avatar, nome, badge, tempo
            Row(
              children: [
                // Indicador de urgência (barra lateral)
                if (escalation.isPending)
                  Container(
                    width: 4,
                    height: 48,
                    margin: const EdgeInsets.only(right: DSSpacing.sm),
                    decoration: BoxDecoration(
                      color: urgencyColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                DSAvatar(name: escalation.customerName, size: 40),
                const SizedBox(width: DSSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        escalation.customerName,
                        style: textStyles.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        escalation.customerWhatsapp,
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
                      escalation.waitTimeFormatted,
                      style: textStyles.bodySmall.copyWith(
                        color: urgencyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Motivo da escalação
            if (escalation.reason != null && escalation.reason!.isNotEmpty) ...[
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
                      'Motivo da escalação',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      escalation.reasonLabel,
                      style: textStyles.bodyMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],

            // Resumo da conversa do agente
            if (escalation.agentConversationSummary != null &&
                escalation.agentConversationSummary!.isNotEmpty) ...[
              const SizedBox(height: DSSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DSSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.blueLight.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                  border: Border.all(
                    color: colors.blue.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy_rounded,
                          size: 14,
                          color: colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Contexto do agente',
                          style: textStyles.bodySmall.copyWith(
                            color: colors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      escalation.agentConversationSummary!,
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Atendente (se in_progress)
            if (escalation.isInProgress &&
                escalation.assignedToName != null) ...[
              const SizedBox(height: DSSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.headset_mic_rounded,
                    size: 14,
                    color: colors.secundaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Atendente: ${escalation.assignedToName}',
                    style: textStyles.bodySmall.copyWith(
                      color: colors.secundaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Notas (se finalizados)
            if (escalation.isCompleted &&
                escalation.notes != null &&
                escalation.notes!.isNotEmpty) ...[
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
                      escalation.notes!,
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

            // Ações
            if (!escalation.isCompleted) ...[
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
                  // Ação principal
                  if (isActionInProgress)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (escalation.isPending && onAssume != null)
                    FilledButton.icon(
                      onPressed: onAssume,
                      icon: const Icon(Icons.headset_mic_rounded, size: 18),
                      label: const Text('Assumir'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DSSpacing.base,
                          vertical: DSSpacing.xs,
                        ),
                      ),
                    )
                  else if (escalation.isInProgress && onComplete != null)
                    FilledButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Finalizar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DSSpacing.base,
                          vertical: DSSpacing.xs,
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

  Widget _buildStatusBadge(DSColors colors) {
    DSBadgeType type;
    switch (escalation.status) {
      case EscalationStatus.pending:
        type = DSBadgeType.warning;
        break;
      case EscalationStatus.in_progress:
        type = DSBadgeType.info;
        break;
      case EscalationStatus.completed:
        type = DSBadgeType.success;
        break;
    }
    return DSBadge(label: escalation.status.shortLabel, type: type);
  }

  Color _getUrgencyColor(DSColors colors) {
    final minutes = escalation.minutesSinceCreation;
    if (minutes < 5) return colors.green;
    if (minutes < 15) return colors.orange;
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
