import 'package:flutter/material.dart';
import '../../../Commons/Models/ProductModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/AppNetworkImage.dart';
import '../../../Commons/Extensions/String+Extensions.dart';

/// Card de produto para grid (Web e Mobile).
class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final bool isWeb;

  const ProductCard({
    super.key,
    required this.product,
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
            borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
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
            children: [
              // Imagem
              _buildImage(colors),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(DSSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      if ((widget.product.color?.isNotEmpty ?? false) ||
                          (widget.product.size?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: DSSpacing.xxs),
                        Text(
                          _buildVariantLabel(),
                          style: textStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(DSColors colors) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: AppNetworkImage(
        url: widget.product.mainImageUrl,
        fit: BoxFit.cover,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DSSpacing.radiusLg),
        ),
        placeholder: Icon(
          Icons.inventory_2_outlined,
          size: 40,
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

  String _buildVariantLabel() {
    final parts = <String>[];
    if (widget.product.color?.isNotEmpty ?? false) {
      parts.add('Cor: ${widget.product.color}');
    }
    if (widget.product.size?.isNotEmpty ?? false) {
      parts.add('Tam: ${widget.product.size}');
    }
    return parts.join(' • ');
  }
}
