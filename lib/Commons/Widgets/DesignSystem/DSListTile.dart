import 'package:flutter/material.dart';
import 'DSColors.dart';
import 'DSTextStyle.dart';
import 'DSSpacing.dart';
import 'DSBadge.dart';

/// Design System v2.0 — Item de lista padronizado USE3D.
///
/// Usado em todas as listagens (Produtos, Clientes, Vendas, Equipe, Tenants).
class DSListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final List<Widget>? trailing;
  final List<DSBadge>? badges;
  final String? metadata;
  final VoidCallback? onTap;

  const DSListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badges,
    this.metadata,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
            hoverColor: colors.primarySurface.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.base,
                vertical: DSSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: DSSpacing.md),
                  ],

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          title,
                          style: textStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Subtitle
                        if (subtitle != null) ...[
                          const SizedBox(height: DSSpacing.xxs),
                          Text(
                            subtitle!,
                            style: textStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Badges
                        if (badges != null && badges!.isNotEmpty) ...[
                          const SizedBox(height: DSSpacing.xs),
                          Wrap(
                            spacing: DSSpacing.xs,
                            runSpacing: DSSpacing.xs,
                            children: badges!,
                          ),
                        ],

                        // Metadata
                        if (metadata != null) ...[
                          const SizedBox(height: DSSpacing.xs),
                          Text(
                            metadata!,
                            style: textStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing
                  if (trailing != null && trailing!.isNotEmpty) ...[
                    const SizedBox(width: DSSpacing.sm),
                    Row(mainAxisSize: MainAxisSize.min, children: trailing!),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Divider com indent para alinhar com o conteúdo (após leading)
        Padding(
          padding: EdgeInsets.only(left: leading != null ? 66 : DSSpacing.base),
          child: Divider(height: 1, thickness: 0.5, color: colors.divider),
        ),
      ],
    );
  }
}
