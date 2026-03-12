import 'package:flutter/material.dart';
import '../../../Commons/Enums/SaleSource.dart';
import '../../../Commons/Enums/SaleStatus.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/SaleModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSListTile.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Widget de item de venda para listagem.
///
/// Web: DSListTile compacto.
/// Mobile: Card com informações detalhadas.
class SaleListItem extends StatelessWidget {
  final SaleModel sale;
  final bool isWeb;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSendPaymentRequest;
  final VoidCallback? onConfirmPayment;
  final VoidCallback? onCancelSale;

  const SaleListItem({
    super.key,
    required this.sale,
    required this.isWeb,
    this.onTap,
    this.onDelete,
    this.onSendPaymentRequest,
    this.onConfirmPayment,
    this.onCancelSale,
  });

  @override
  Widget build(BuildContext context) {
    return isWeb ? _buildWebItem(context) : _buildMobileItem(context);
  }

  // MARK: - Web (DSListTile)

  Widget _buildWebItem(BuildContext context) {
    return DSListTile(
      leading: DSAvatar(name: sale.customerName, size: 48),
      title: '#${sale.number} • ${sale.customerName}',
      subtitle:
          '${sale.total.formatToBRL()} • ${sale.itemsCount} ${sale.itemsCount == 1 ? 'item' : 'itens'}',
      badges: [
        DSBadge(
          label: sale.source.label,
          type: sale.source == SaleSource.manual
              ? DSBadgeType.info
              : DSBadgeType.primary,
        ),
        DSBadge(label: sale.status.label, type: _statusBadgeType),
      ],
      metadata: sale.createdAt.formatDateTime(),
      trailing: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          tooltip: 'Ver Detalhes',
          onPressed: onTap,
        ),
        IconButton(
          icon: Icon(Icons.delete, size: 20, color: DSColors().red),
          tooltip: 'Deletar',
          onPressed: onDelete,
        ),
      ],
      onTap: onTap,
    );
  }

  // MARK: - Mobile (Card)

  Widget _buildMobileItem(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Card(
      margin: const EdgeInsets.only(bottom: DSSpacing.sm),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DSSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: número + data
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${sale.number}', style: textStyles.labelLarge),
                  Text(
                    sale.createdAt.formatDateTime(),
                    style: textStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.sm),

              // Cliente
              Row(
                children: [
                  DSAvatar(name: sale.customerName, size: 36),
                  const SizedBox(width: DSSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customerName,
                          style: textStyles.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${sale.itemsCount} ${sale.itemsCount == 1 ? 'item' : 'itens'}',
                          style: textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    sale.total.formatToBRL(),
                    style: textStyles.labelLarge.copyWith(
                      color: colors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.sm),

              // Badges
              Row(
                children: [
                  DSBadge(
                    label: sale.source.label,
                    type: sale.source == SaleSource.manual
                        ? DSBadgeType.info
                        : DSBadgeType.primary,
                    size: DSBadgeSize.small,
                  ),
                  const SizedBox(width: DSSpacing.xs),
                  DSBadge(
                    label: sale.status.label,
                    type: _statusBadgeType,
                    size: DSBadgeSize.small,
                  ),
                  const Spacer(),
                  // Deletar
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: colors.red,
                    ),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Deletar',
                  ),
                ],
              ),

              // Ações rápidas (pendentes / cobrança enviada)
              if (sale.canSendPaymentRequest ||
                  sale.canConfirmPayment ||
                  (sale.canCancel && !sale.isConfirmed)) ...[
                const SizedBox(height: DSSpacing.sm),
                Row(
                  children: [
                    if (sale.canSendPaymentRequest)
                      Expanded(
                        child: _ActionChipButton(
                          label: 'Cobrar',
                          icon: Icons.send_rounded,
                          color: colors.blue,
                          bgColor: colors.blueLight,
                          onTap: onSendPaymentRequest,
                        ),
                      ),
                    if (sale.canSendPaymentRequest && sale.canConfirmPayment)
                      const SizedBox(width: DSSpacing.xs),
                    if (sale.canConfirmPayment)
                      Expanded(
                        child: _ActionChipButton(
                          label: 'Pago',
                          icon: Icons.check_circle_rounded,
                          color: colors.green,
                          bgColor: colors.greenLight,
                          onTap: onConfirmPayment,
                        ),
                      ),
                    if (sale.canCancel && !sale.isConfirmed) ...[
                      const SizedBox(width: DSSpacing.xs),
                      Expanded(
                        child: _ActionChipButton(
                          label: 'Cancelar',
                          icon: Icons.cancel_rounded,
                          color: colors.red,
                          bgColor: colors.redLight,
                          onTap: onCancelSale,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Helpers

  DSBadgeType get _statusBadgeType {
    switch (sale.status) {
      case SaleStatus.confirmed:
        return DSBadgeType.success;
      case SaleStatus.pending:
        return DSBadgeType.warning;
      case SaleStatus.payment_sent:
        return DSBadgeType.info;
      case SaleStatus.cancelled:
        return DSBadgeType.error;
    }
  }
}

/// Botão de ação compacto para cards mobile.
class _ActionChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _ActionChipButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.sm,
            vertical: DSSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: DSSpacing.xxs),
              Text(
                label,
                style: DSTextStyle().caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
