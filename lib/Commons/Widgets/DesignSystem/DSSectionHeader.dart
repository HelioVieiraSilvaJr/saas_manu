import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';

/// Design System v2.0 — Cabeçalho de seção padronizado USE3D.
///
/// Usado para separar blocos de conteúdo com título, subtítulo e ação opcional.
class DSSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool useOverline;

  const DSSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.useOverline = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  useOverline ? title.toUpperCase() : title,
                  style: useOverline
                      ? textStyles.overline
                      : textStyles.headline3,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: DSSpacing.xxs),
                  Text(
                    subtitle!,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
