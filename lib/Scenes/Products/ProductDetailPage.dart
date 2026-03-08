import 'package:flutter/material.dart';
import '../../Commons/Models/ProductModel.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../Commons/Extensions/String+Extensions.dart';
import '../../Sources/Coordinators/AppShell.dart';
import '../../Commons/Widgets/DesignSystem/AppNetworkImage.dart';
import 'ProductsCoordinator.dart';
import 'ProductsListPresenter.dart';
import 'ProductsRepository.dart';

/// Página de detalhes do produto.
///
/// Exibe imagem, informações, metadados e ações (editar/excluir).
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductModel? _product;
  late final ProductsListPresenter _presenter;
  final ProductsRepository _repository = ProductsRepository();

  @override
  void initState() {
    super.initState();
    _presenter = ProductsListPresenter(onViewModelUpdated: (_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presenter.context = context;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProductModel && _product == null) {
      _product = args;
    }
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  // MARK: - Reload

  Future<void> _reloadProduct() async {
    if (_product == null) return;
    final fresh = await _repository.getById(_product!.uid);
    if (fresh != null && mounted) setState(() => _product = fresh);
  }

  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return const Scaffold(
        body: Center(child: Text('Produto não encontrado.')),
      );
    }

    return AppShell(
      currentRoute: '/products',
      child: ScreenResponsive(
        web: _buildWebLayout(),
        mobile: _buildMobileLayout(),
      ),
    );
  }

  // MARK: - Web Layout

  Widget _buildWebLayout() {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final product = _product!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => ProductsCoordinator.navigateBack(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: DSSpacing.sm),
              Expanded(
                child: Text('Detalhes do Produto', style: textStyles.headline1),
              ),
              Tooltip(
                message: 'Editar',
                child: IconButton(
                  onPressed: () async {
                    await ProductsCoordinator.navigateToEdit(context, product);
                    _reloadProduct();
                  },
                  icon: Icon(Icons.edit_outlined, color: colors.primaryColor),
                ),
              ),
              const SizedBox(width: DSSpacing.xs),
              Tooltip(
                message: 'Excluir',
                child: IconButton(
                  onPressed: () => _handleDelete(product),
                  icon: Icon(Icons.delete_outline, color: colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagem
                  _buildImageCard(colors, size: 300),
                  const SizedBox(width: DSSpacing.xl),

                  // Info
                  Expanded(child: _buildInfoCard(colors, textStyles)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Mobile Layout

  Widget _buildMobileLayout() {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final product = _product!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes', style: textStyles.headline3),
        leading: IconButton(
          onPressed: () => ProductsCoordinator.navigateBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        backgroundColor: colors.cardBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await ProductsCoordinator.navigateToEdit(context, product);
              _reloadProduct();
            },
            icon: Icon(Icons.edit_outlined, color: colors.primaryColor),
          ),
          IconButton(
            onPressed: () => _handleDelete(product),
            icon: Icon(Icons.delete_outline, color: colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DSSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem
            Center(child: _buildImageCard(colors, size: 250)),
            const SizedBox(height: DSSpacing.lg),

            // Info
            _buildInfoCard(colors, textStyles),
          ],
        ),
      ),
    );
  }

  // MARK: - Components

  Widget _buildImageCard(DSColors colors, {required double size}) {
    final product = _product!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        child: AppNetworkImage(
          url: product.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: _imagePlaceholder(colors),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(DSColors colors) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 56,
        color: colors.textTertiary.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildInfoCard(DSColors colors, DSTextStyle textStyles) {
    final product = _product!;

    return Container(
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome e Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(product.name, style: textStyles.headline2)),
              DSBadge(
                label: product.isActive ? 'Ativo' : 'Inativo',
                type: product.isActive
                    ? DSBadgeType.success
                    : DSBadgeType.error,
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.lg),

          // Preço
          _buildInfoRow(
            colors,
            textStyles,
            icon: Icons.attach_money_rounded,
            label: 'Preço',
            value: product.price.formatToBRL(),
            valueColor: colors.primaryColor,
            valueFontSize: 20,
          ),
          const Divider(height: DSSpacing.xl),

          // SKU
          _buildInfoRow(
            colors,
            textStyles,
            icon: Icons.qr_code_rounded,
            label: 'SKU',
            value: product.sku,
          ),
          const Divider(height: DSSpacing.xl),

          // Estoque
          _buildInfoRow(
            colors,
            textStyles,
            icon: Icons.inventory_2_outlined,
            label: 'Estoque',
            value: '${product.stock} unidades',
            valueColor: _stockColor(colors, product.stock),
          ),
          const Divider(height: DSSpacing.xl),

          // Descrição
          if (product.description != null &&
              product.description!.isNotEmpty) ...[
            _buildInfoRow(
              colors,
              textStyles,
              icon: Icons.description_outlined,
              label: 'Descrição',
              value: product.description!,
            ),
            const Divider(height: DSSpacing.xl),
          ],

          // Metadados
          Text('Informações', style: textStyles.labelLarge),
          const SizedBox(height: DSSpacing.sm),

          _buildMetaRow(
            colors,
            textStyles,
            'Criado em',
            product.createdAt.formatDateTime(),
          ),
          const SizedBox(height: DSSpacing.xs),

          if (product.updatedAt != null)
            _buildMetaRow(
              colors,
              textStyles,
              'Atualizado em',
              product.updatedAt!.formatDateTime(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    DSColors colors,
    DSTextStyle textStyles, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    double? valueFontSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: DSSpacing.iconMd, color: colors.textTertiary),
        const SizedBox(width: DSSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textStyles.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: DSSpacing.xxs),
            Text(
              value,
              style: textStyles.bodyLarge.copyWith(
                color: valueColor,
                fontSize: valueFontSize,
                fontWeight: valueColor != null ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaRow(
    DSColors colors,
    DSTextStyle textStyles,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: textStyles.caption.copyWith(color: colors.textTertiary),
        ),
        Text(value, style: textStyles.caption),
      ],
    );
  }

  Color _stockColor(DSColors colors, int stock) {
    if (stock == 0) return colors.red;
    if (stock < 10) return colors.orange;
    return colors.green;
  }

  // MARK: - Actions

  Future<void> _handleDelete(ProductModel product) async {
    await _presenter.deleteProduct(product);
    // Se deletou (hard ou soft), volta para lista
    if (mounted) {
      ProductsCoordinator.navigateBack(context, result: true);
    }
  }
}
