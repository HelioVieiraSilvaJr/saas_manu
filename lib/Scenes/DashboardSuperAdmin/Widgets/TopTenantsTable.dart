import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/PlatformAnalyticsModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Tabela com ranking dos top tenants por vendas no mês.
class TopTenantsTable extends StatelessWidget {
  final List<TopTenantDTO> topTenants;

  const TopTenantsTable({super.key, required this.topTenants});

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      padding: const EdgeInsets.all(DSSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: colors.orange, size: 20),
              const SizedBox(width: DSSpacing.xs),
              Text('Top Tenants por Vendas (Mês)', style: textStyles.headline3),
            ],
          ),
          const SizedBox(height: DSSpacing.md),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: DSSpacing.xs,
              horizontal: DSSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#',
                    style: textStyles.labelSmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Tenant',
                    style: textStyles.labelSmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Vendas (R\$)',
                    style: textStyles.labelSmall.copyWith(
                      color: colors.textTertiary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Qtd',
                    style: textStyles.labelSmall.copyWith(
                      color: colors.textTertiary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colors.divider, height: 1),
          ...topTenants.asMap().entries.map((entry) {
            final index = entry.key;
            final tenant = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DSSpacing.sm,
                horizontal: DSSpacing.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${index + 1}',
                      style: textStyles.bodyMedium.copyWith(
                        fontWeight: index < 3
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: index < 3
                            ? colors.primaryColor
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      tenant.tenantName,
                      style: textStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      tenant.salesMonth.formatToBRL(),
                      style: textStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tenant.salesCount.toString(),
                      style: textStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
