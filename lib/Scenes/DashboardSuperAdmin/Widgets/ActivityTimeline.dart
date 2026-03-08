import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../SuperAdminRepository.dart';

/// Timeline de atividades recentes do SuperAdmin.
class ActivityTimeline extends StatelessWidget {
  final List<ActivityDTO> activities;

  const ActivityTimeline({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

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
          Text('Últimas Atividades', style: textStyles.headline3),
          const SizedBox(height: DSSpacing.sm),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DSSpacing.xl),
              child: Center(
                child: Text(
                  'Nenhuma atividade recente',
                  style: textStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...activities.map(
              (activity) => _buildActivityItem(activity, colors, textStyles),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    ActivityDTO activity,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DSSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _typeColor(activity.type, colors).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _typeIcon(activity.type),
              size: 16,
              color: _typeColor(activity.type, colors),
            ),
          ),
          const SizedBox(width: DSSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.description, style: textStyles.bodySmall),
                Text(
                  '"${activity.tenantName}"',
                  style: textStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  activity.timestamp.timeAgo(),
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return Icons.add_circle_outline;
      case ActivityType.upgraded:
        return Icons.upgrade;
      case ActivityType.deactivated:
        return Icons.block;
      case ActivityType.reactivated:
        return Icons.check_circle_outline;
    }
  }

  Color _typeColor(ActivityType type, DSColors colors) {
    switch (type) {
      case ActivityType.created:
        return colors.green;
      case ActivityType.upgraded:
        return colors.blue;
      case ActivityType.deactivated:
        return colors.red;
      case ActivityType.reactivated:
        return colors.primaryColor;
    }
  }
}
