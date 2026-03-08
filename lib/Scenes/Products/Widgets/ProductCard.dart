import 'package:flutter/material.dart';
import '../../../Commons/Models/ProductModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Extensions/String+Extensions.dart';

/// Card de produto para grid (Web e Mobile).
class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool isWeb;

  const ProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.isWeb = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
            border: Border.all(
              color: _isHovered
                  ? colors.primaryColor.withValues(alpha: 0.3)
                  : colors.divider,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? colors.primaryColor.withValues(alpha: 0.08)
                    : colors.shadowColor,
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem
              _buildImage(colors),

              // Content
              Padding(
                padding: const EdgeInsets.all(DSSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome
                    Text(
                      widget.product.name,
                      style: textStyles.labelLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DSSpacing.xs),

                    // Preço
                    Text(
                      widget.product.price.formatToBRL(),
                      style: textStyles.headline3.copyWith(
                        color: colors.primaryColor,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.sm),

                    // SKU
                    Text(
                      'SKU: ${widget.product.sku}',
                      style: textStyles.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DSSpacing.xxs),

                    // Estoque
                    _buildStockText(colors, textStyles),
                    const SizedBox(height: DSSpacing.sm),

                    // Badge Status
                    DSBadge(
                      label: widget.product.isActive ? 'Ativo' : 'Inativo',
                      type: widget.product.isActive
                          ? DSBadgeType.success
                          : DSBadgeType.error,
                      size: DSBadgeSize.small,
                    ),
                    const SizedBox(height: DSSpacing.sm),

                    // Botões
                    _buildActions(colors),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(DSColors colors) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(DSSpacing.radiusMd),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child:
            widget.product.imageUrl != null &&
                widget.product.imageUrl!.isNotEmpty
            ? Image.network(
                widget.product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(colors),
              )
            : _imagePlaceholder(colors),
      ),
    );
  }

  Widget _imagePlaceholder(DSColors colors) {
    return Container(
      color: colors.scaffoldBackground,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 48,
          color: colors.textTertiary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildStockText(DSColors colors, DSTextStyle textStyles) {
    final stock = widget.product.stock;
    Color stockColor;
    if (stock == 0) {
      stockColor = colors.red;
    } else if (stock < 10) {
      stockColor = colors.orange;
    } else {
      stockColor = colors.green;
    }

    return Text(
      'Estoque: $stock un.',
      style: textStyles.caption.copyWith(
        color: stockColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActions(DSColors colors) {
    if (widget.isWeb) {
      // Web: apenas ícones com tooltip
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.onEdit != null)
            Tooltip(
              message: 'Editar',
              child: InkWell(
                onTap: widget.onEdit,
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.all(DSSpacing.xs),
                  child: Icon(
                    Icons.edit_outlined,
                    size: DSSpacing.iconMd,
                    color: colors.primaryColor,
                  ),
                ),
              ),
            ),
          const SizedBox(width: DSSpacing.xs),
          if (widget.onDelete != null)
            Tooltip(
              message: 'Excluir',
              child: InkWell(
                onTap: widget.onDelete,
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.all(DSSpacing.xs),
                  child: Icon(
                    Icons.delete_outline,
                    size: DSSpacing.iconMd,
                    color: colors.red,
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      // Mobile: ícone + texto
      return Row(
        children: [
          if (widget.onEdit != null)
            Expanded(
              child: InkWell(
                onTap: widget.onEdit,
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: DSSpacing.xs),
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
            ),
          if (widget.onDelete != null)
            Expanded(
              child: InkWell(
                onTap: widget.onDelete,
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: DSSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 14, color: colors.red),
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
            ),
        ],
      );
    }
  }
}
