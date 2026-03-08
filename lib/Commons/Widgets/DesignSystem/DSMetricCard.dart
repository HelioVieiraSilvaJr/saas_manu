import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';

/// Tipo de tendência para o metric card.
enum TrendType {
  up, // ↑ Verde
  down, // ↓ Vermelho
  neutral, // - Cinza
}

/// Design System - Card de métrica/estatística.
class DSMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? comparison;
  final TrendType? trend;
  final IconData? icon;
  final Color? color;

  const DSMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.comparison,
    this.trend,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: color ?? colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (icon + title)
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    size: DSSpacing.iconMd,
                    color: colors.primaryColor,
                  ),
                ),
                const SizedBox(width: DSSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: textStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.md),

          // Value
          Text(
            value,
            style: textStyles.metricValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Comparison
          if (comparison != null && trend != null) ...[
            const SizedBox(height: DSSpacing.xs),
            Row(
              children: [
                Icon(_trendIcon, size: 14, color: _trendColor(colors)),
                const SizedBox(width: DSSpacing.xxs),
                Expanded(
                  child: Text(
                    comparison!,
                    style: textStyles.metricComparison.copyWith(
                      color: _trendColor(colors),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else if (comparison != null) ...[
            const SizedBox(height: DSSpacing.xs),
            Text(
              comparison!,
              style: textStyles.metricComparison.copyWith(
                color: colors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  IconData get _trendIcon {
    switch (trend) {
      case TrendType.up:
        return Icons.trending_up;
      case TrendType.down:
        return Icons.trending_down;
      case TrendType.neutral:
      case null:
        return Icons.trending_flat;
    }
  }

  Color _trendColor(DSColors colors) {
    switch (trend) {
      case TrendType.up:
        return colors.green;
      case TrendType.down:
        return colors.red;
      case TrendType.neutral:
      case null:
        return colors.textTertiary;
    }
  }
}
