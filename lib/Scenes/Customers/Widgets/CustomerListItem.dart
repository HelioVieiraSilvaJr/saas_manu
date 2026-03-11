import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Commons/Models/CustomerModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../../Commons/Widgets/DesignSystem/DSListTile.dart';
import '../../../Commons/Extensions/String+Extensions.dart';

/// Item de lista/card para clientes.
///
/// Web: formato lista compacta com DSListTile.
/// Mobile: card com informações.
class CustomerListItem extends StatelessWidget {
  final CustomerModel customer;
  final bool isWeb;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CustomerListItem({
    super.key,
    required this.customer,
    this.isWeb = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isWeb) {
      return _buildWebListItem(context);
    }
    return _buildMobileCard(context);
  }

  // MARK: - Web (Lista compacta com DSListTile)

  Widget _buildWebListItem(BuildContext context) {
    final colors = DSColors();

    final subtitleParts = <String>[customer.whatsapp.formatWhatsApp()];
    if (customer.email != null && customer.email!.isNotEmpty) {
      subtitleParts.add(customer.email!);
    }

    final metadata = customer.hasPurchases
        ? 'Última compra: ${customer.lastPurchaseAt?.timeAgo() ?? "–"} • Total: ${(customer.totalSpent ?? 0.0).formatToBRL()}'
        : 'Nunca comprou';

    return DSListTile(
      leading: DSAvatar(name: customer.name, size: 48),
      title: customer.name,
      subtitle: subtitleParts.join(' • '),
      metadata: metadata,
      trailing: [
        IconButton(
          icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
          tooltip: 'WhatsApp',
          onPressed: () => _openWhatsApp(),
        ),
        IconButton(
          icon: Icon(Icons.edit_outlined, color: colors.primaryColor),
          tooltip: 'Editar',
          onPressed: onEdit,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: colors.red),
          tooltip: 'Excluir',
          onPressed: onDelete,
        ),
      ],
      onTap: onTap,
    );
  }

  // MARK: - Mobile (Card)

  Widget _buildMobileCard(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DSSpacing.sm),
        padding: const EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          border: Border.all(color: colors.divider),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: DSSpacing.elevationSmBlur,
              offset: Offset(0, DSSpacing.elevationSmOffset),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Nome + WhatsApp button
            Row(
              children: [
                DSAvatar(name: customer.name, size: 44),
                const SizedBox(width: DSSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: textStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: DSSpacing.xxs),
                      Text(
                        customer.whatsapp.formatWhatsApp(),
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // WhatsApp button
                GestureDetector(
                  onTap: _openWhatsApp,
                  child: Container(
                    padding: const EdgeInsets.all(DSSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      color: Color(0xFF25D366),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.sm),

            // Email (se tiver)
            if (customer.email != null && customer.email!.isNotEmpty) ...[
              Text(
                customer.email!,
                style: textStyles.caption.copyWith(color: colors.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DSSpacing.xs),
            ],

            // Info de compras
            Divider(color: colors.divider, height: DSSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customer.hasPurchases
                      ? 'Última: ${customer.lastPurchaseAt?.timeAgo() ?? "–"}'
                      : 'Nunca comprou',
                  style: textStyles.caption.copyWith(
                    color: customer.hasPurchases
                        ? colors.textSecondary
                        : colors.textTertiary,
                  ),
                ),
                if (customer.hasPurchases)
                  Text(
                    'Total: ${(customer.totalSpent ?? 0.0).formatToBRL()}',
                    style: textStyles.caption.copyWith(
                      color: colors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DSSpacing.sm),

            // Ações: Editar e Excluir
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: onEdit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: colors.primaryColor,
                          ),
                          const SizedBox(width: DSSpacing.xxs),
                          Text(
                            'Editar',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (onDelete != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: colors.red,
                          ),
                          const SizedBox(width: DSSpacing.xxs),
                          Text(
                            'Excluir',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Actions

  void _openWhatsApp() {
    final url = 'https://wa.me/55${customer.whatsapp}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
