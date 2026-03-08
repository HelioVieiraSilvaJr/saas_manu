import 'package:flutter/material.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSListTile.dart';
import '../../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/EmptyState.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Enums/SaleSource.dart';
import '../DashboardTenantRepository.dart';

/// Widget de vendas recentes (últimas 5 vendas).
class RecentSalesWidget extends StatelessWidget {
  final List<RecentSaleDTO> sales;
  final VoidCallback? onViewAll;
  final ValueChanged<RecentSaleDTO>? onSaleTap;

  const RecentSalesWidget({
    super.key,
    required this.sales,
    this.onViewAll,
    this.onSaleTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
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
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DSSpacing.base,
              DSSpacing.base,
              DSSpacing.base,
              DSSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Últimas Vendas', style: textStyles.headline3),
                if (sales.isNotEmpty && onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      'Ver todas →',
                      style: textStyles.labelMedium.copyWith(
                        color: colors.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          if (sales.isEmpty)
            const Padding(
              padding: EdgeInsets.all(DSSpacing.xl),
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nenhuma venda registrada',
                message: 'Suas vendas aparecerão aqui.',
              ),
            )
          else
            ...sales.map((sale) => _buildSaleItem(sale, colors)),

          if (sales.isNotEmpty) const SizedBox(height: DSSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildSaleItem(RecentSaleDTO sale, DSColors colors) {
    final source = SaleSource.fromString(sale.source);
    final badgeType = source == SaleSource.whatsapp_automation
        ? DSBadgeType.primary
        : DSBadgeType.info;
    final badgeIcon = source == SaleSource.whatsapp_automation
        ? Icons.smart_toy_outlined
        : Icons.person_outline;

    return DSListTile(
      leading: DSAvatar(name: sale.customerName, size: 40),
      title: sale.customerName,
      subtitle:
          '${sale.itemCount} ${sale.itemCount == 1 ? "item" : "itens"} • ${sale.totalValue.formatToBRL()}',
      badges: [
        DSBadge(
          label: source.label,
          type: badgeType,
          icon: badgeIcon,
          size: DSBadgeSize.small,
        ),
      ],
      metadata: sale.createdAt.timeAgo(),
      onTap: onSaleTap != null ? () => onSaleTap!(sale) : null,
    );
  }
}
