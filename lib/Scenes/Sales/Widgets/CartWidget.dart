import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Widgets/DesignSystem/AppNetworkImage.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../SaleFormViewModel.dart';

/// Widget do carrinho de compras para nova venda.
class CartWidget extends StatelessWidget {
  final List<CartItem> items;
  final void Function(int index, int quantity)? onUpdateQuantity;
  final void Function(int index)? onRemove;

  const CartWidget({
    super.key,
    required this.items,
    this.onUpdateQuantity,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: colors.textTertiary,
              ),
              const SizedBox(height: DSSpacing.sm),
              Text(
                'Carrinho vazio',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: DSSpacing.xs),
              Text('Adicione produtos à venda', style: textStyles.caption),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.base,
            vertical: DSSpacing.sm,
          ),
          child: Text(
            'Carrinho (${items.length} ${items.length == 1 ? 'item' : 'itens'})',
            style: textStyles.labelLarge,
          ),
        ),

        // Items
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildCartItem(context, index, item, colors, textStyles);
        }),

        // Total
        Container(
          padding: const EdgeInsets.all(DSSpacing.base),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.divider, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: textStyles.headline3),
              Text(
                _calculateTotal().formatToBRL(),
                style: textStyles.headline3.copyWith(
                  color: colors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    int index,
    CartItem item,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.base,
        vertical: DSSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Imagem/Placeholder
          AppNetworkImage(
            url: item.product.imageUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
            placeholder: _buildPlaceholder(colors),
          ),
          const SizedBox(width: DSSpacing.sm),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: textStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.product.price.formatToBRL()} x ${item.quantity}',
                  style: textStyles.bodySmall,
                ),
              ],
            ),
          ),

          // Quantidade
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: item.quantity > 1
                    ? () => onUpdateQuantity?.call(index, item.quantity - 1)
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.divider),
                    borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: item.quantity > 1
                        ? colors.textPrimary
                        : colors.textTertiary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm),
                child: Text('${item.quantity}', style: textStyles.labelMedium),
              ),
              InkWell(
                onTap: item.quantity < item.product.stock
                    ? () => onUpdateQuantity?.call(index, item.quantity + 1)
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.divider),
                    borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: item.quantity < item.product.stock
                        ? colors.textPrimary
                        : colors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: DSSpacing.sm),

          // Subtotal
          SizedBox(
            width: 80,
            child: Text(
              item.subtotal.formatToBRL(),
              style: textStyles.labelMedium,
              textAlign: TextAlign.right,
            ),
          ),

          // Remover
          IconButton(
            icon: Icon(Icons.close, size: 18, color: colors.red),
            onPressed: () => onRemove?.call(index),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Remover',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(DSColors colors) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.divider,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
      ),
      child: const Icon(Icons.inventory_2, size: 20),
    );
  }

  double _calculateTotal() {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }
}
