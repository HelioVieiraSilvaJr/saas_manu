import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';
import 'DSButton.dart';

/// Design System v2.0 — Widget para estados vazios USE3D.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon — container arredondado
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.primarySurface,
                borderRadius: BorderRadius.circular(DSSpacing.radiusXl),
              ),
              child: Icon(
                icon,
                size: 40,
                color: colors.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: DSSpacing.xl),

            // Title
            Text(
              title,
              style: textStyles.headline3.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),

            // Message
            if (message != null) ...[
              const SizedBox(height: DSSpacing.sm),
              Text(
                message!,
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action Button — accent
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DSSpacing.xl),
              DSButton.accent(label: actionLabel!, onTap: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
