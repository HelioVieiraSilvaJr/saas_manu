import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/ProductModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Modal de busca e seleção de produtos.
class ProductSearchModal {
  ProductSearchModal._();

  /// Exibe o modal e retorna produto + quantidade selecionados.
  static Future<({ProductModel product, int quantity})?> show({
    required BuildContext context,
    required List<ProductModel> products,
  }) {
    return showModalBottomSheet<({ProductModel product, int quantity})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return _ProductSearchContent(
            products: products,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _ProductSearchContent extends StatefulWidget {
  final List<ProductModel> products;
  final ScrollController scrollController;

  const _ProductSearchContent({
    required this.products,
    required this.scrollController,
  });

  @override
  State<_ProductSearchContent> createState() => _ProductSearchContentState();
}

class _ProductSearchContentState extends State<_ProductSearchContent> {
  final _searchController = TextEditingController();
  List<ProductModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.products
        .where((p) => p.isActive && p.stock > 0)
        .toList();
  }

  void _filter(String query) {
    setState(() {
      var list = widget.products
          .where((p) => p.isActive && p.stock > 0)
          .toList();
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        list = list
            .where(
              (p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q),
            )
            .toList();
      }
      _filtered = list;
    });
  }

  Future<void> _selectProduct(ProductModel product) async {
    final quantity = await _showQuantityDialog(product);
    if (quantity != null && quantity > 0 && mounted) {
      Navigator.pop(context, (product: product, quantity: quantity));
    }
  }

  Future<int?> _showQuantityDialog(ProductModel product) {
    int qty = 1;
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        final colors = DSColors();
        final textStyles = DSTextStyle();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Quantidade', style: textStyles.headline3),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(product.name, style: textStyles.labelMedium),
                  Text(
                    'Estoque: ${product.stock} un.',
                    style: textStyles.bodySmall,
                  ),
                  const SizedBox(height: DSSpacing.base),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty > 1
                            ? () => setDialogState(() => qty--)
                            : null,
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                          vertical: DSSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.divider),
                          borderRadius: BorderRadius.circular(
                            DSSpacing.radiusSm,
                          ),
                        ),
                        child: Text(
                          '$qty',
                          style: textStyles.headline3,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: qty < product.stock
                            ? () => setDialogState(() => qty++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.sm),
                  Text(
                    'Subtotal: ${(product.price * qty).formatToBRL()}',
                    style: textStyles.labelLarge.copyWith(
                      color: colors.primaryColor,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, qty),
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DSSpacing.radiusLg),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: DSSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(DSSpacing.base),
            child: Text('Selecionar Produto', style: textStyles.headline3),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.base),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.base,
                  vertical: DSSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.sm),
          const Divider(height: 1),
          // List
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final product = _filtered[index];
                return ListTile(
                  leading: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            DSSpacing.radiusSm,
                          ),
                          child: Image.network(
                            product.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildProductPlaceholder(colors),
                          ),
                        )
                      : _buildProductPlaceholder(colors),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.price.formatToBRL()} • Est: ${product.stock}',
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle, color: colors.primaryColor),
                    tooltip: 'Adicionar',
                    onPressed: () => _selectProduct(product),
                  ),
                  onTap: () => _selectProduct(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPlaceholder(DSColors colors) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.divider,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
      ),
      child: const Icon(Icons.inventory_2, size: 24),
    );
  }
}
