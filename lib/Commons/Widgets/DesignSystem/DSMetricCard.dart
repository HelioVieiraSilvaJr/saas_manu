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

/// Design System v2.0 — Card de métrica/estatística USE3D.
class DSMetricCard extends StatefulWidget {
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
  State<DSMetricCard> createState() => _DSMetricCardState();
}

class _DSMetricCardState extends State<DSMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(DSSpacing.cardPaddingLg),
        decoration: BoxDecoration(
          color: widget.color ?? colors.cardBackground,
          borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          border: Border.all(
            color: _isHovered
                ? colors.primaryLight.withValues(alpha: 0.3)
                : colors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? colors.shadowMedium : colors.shadowColor,
              blurRadius: _isHovered
                  ? DSSpacing.elevationMdBlur
                  : DSSpacing.elevationSmBlur,
              offset: Offset(
                0,
                _isHovered
                    ? DSSpacing.elevationMdOffset
                    : DSSpacing.elevationSmOffset,
              ),
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
                if (widget.icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primarySurface,
                      borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                    ),
                    child: Icon(
                      widget.icon,
                      size: DSSpacing.iconMd,
                      color: colors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.md),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: textStyles.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.base),

            // Value
            Text(
              widget.value,
              style: textStyles.metricValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Comparison
            if (widget.comparison != null && widget.trend != null) ...[
              const SizedBox(height: DSSpacing.xs),
              Row(
                children: [
                  Icon(_trendIcon, size: 14, color: _trendColor(colors)),
                  const SizedBox(width: DSSpacing.xxs),
                  Expanded(
                    child: Text(
                      widget.comparison!,
                      style: textStyles.metricComparison.copyWith(
                        color: _trendColor(colors),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else if (widget.comparison != null) ...[
              const SizedBox(height: DSSpacing.xs),
              Text(
                widget.comparison!,
                style: textStyles.metricComparison.copyWith(
                  color: colors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _trendIcon {
    switch (widget.trend) {
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
    switch (widget.trend) {
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
