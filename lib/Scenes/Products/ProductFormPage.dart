import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../Commons/Widgets/DesignSystem/AppNetworkImage.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'ProductFormPresenter.dart';
import 'ProductFormViewModel.dart';
import 'ProductsCoordinator.dart';

/// Página de criação/edição de produto.
///
/// Formulário com validação, upload de imagem, máscara de moeda.
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late final ProductFormPresenter _presenter;
  ProductFormViewModel _viewModel = const ProductFormViewModel();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;

  Uint8List? _imagePreview;
  String? _imagePreviewUrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _presenter = ProductFormPresenter(
      onViewModelUpdated: (viewModel) {
        if (mounted) {
          setState(() {
            _viewModel = viewModel;
            _imagePreviewUrl = viewModel.imagePreviewUrl;
          });
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presenter.context = context;

    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        // Edição: o argumento é o productId
        _presenter.initForEdit(args).then((_) => _populateFields());
      } else {
        // Criação
        _presenter.initForCreate();
        _stockController.text = '0';
      }
    }
  }

  void _populateFields() {
    final product = _viewModel.product;
    if (product != null) {
      _nameController.text = product.name;
      _skuController.text = product.sku;
      _priceController.text = product.price
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _stockController.text = product.stock.toString();
      _descriptionController.text = product.description ?? '';
      _isActive = product.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    if (_viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando produto...');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.pagePaddingHorizontalWeb,
        vertical: DSSpacing.pagePaddingVerticalWeb,
      ),
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
              Text(
                _viewModel.isEditing ? 'Editar Produto' : 'Novo Produto',
                style: textStyles.headline1,
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),

          // Formulário centralizado
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildForm(colors, textStyles, isWeb: true),
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

    if (_viewModel.isLoading) {
      return const LoadingIndicator(message: 'Carregando produto...');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewModel.isEditing ? 'Editar Produto' : 'Novo Produto',
          style: textStyles.headline3,
        ),
        leading: IconButton(
          onPressed: () => ProductsCoordinator.navigateBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        backgroundColor: colors.cardBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DSSpacing.md),
        child: _buildForm(colors, textStyles, isWeb: false),
      ),
    );
  }

  // MARK: - Form

  Widget _buildForm(
    DSColors colors,
    DSTextStyle textStyles, {
    required bool isWeb,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensagem de erro
          if (_viewModel.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(DSSpacing.md),
              decoration: BoxDecoration(
                color: colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                border: Border.all(color: colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colors.red,
                    size: DSSpacing.iconMd,
                  ),
                  const SizedBox(width: DSSpacing.sm),
                  Expanded(
                    child: Text(
                      _viewModel.errorMessage!,
                      style: textStyles.bodyMedium.copyWith(color: colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DSSpacing.lg),
          ],

          // Imagem
          _buildImageSection(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),

          // Campos - Web: 2 colunas, Mobile: 1 coluna
          if (isWeb) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'Nome do Produto *',
                    controller: _nameController,
                    hintText: 'Ex: Camiseta Básica',
                    maxLength: 100,
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: DSSpacing.lg),
                Expanded(
                  child: FormTextField(
                    label: 'SKU *',
                    controller: _skuController,
                    hintText: 'Ex: CAM-001',
                    prefixIcon: Icons.qr_code_rounded,
                    validator: _validateSku,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormTextField(
                    label: 'Preço *',
                    controller: _priceController,
                    hintText: 'Ex: 49,90',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validatePrice,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: DSSpacing.lg),
                Expanded(
                  child: FormTextField(
                    label: 'Estoque *',
                    controller: _stockController,
                    hintText: 'Ex: 100',
                    prefixIcon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    validator: _validateStock,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
          ] else ...[
            FormTextField(
              label: 'Nome do Produto *',
              controller: _nameController,
              hintText: 'Ex: Camiseta Básica',
              maxLength: 100,
              validator: _validateName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.lg),
            FormTextField(
              label: 'SKU *',
              controller: _skuController,
              hintText: 'Ex: CAM-001',
              prefixIcon: Icons.qr_code_rounded,
              validator: _validateSku,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.lg),
            FormTextField(
              label: 'Preço *',
              controller: _priceController,
              hintText: 'Ex: 49,90',
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validatePrice,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: DSSpacing.lg),
            FormTextField(
              label: 'Estoque *',
              controller: _stockController,
              hintText: 'Ex: 100',
              prefixIcon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
              validator: _validateStock,
              textInputAction: TextInputAction.next,
            ),
          ],
          const SizedBox(height: DSSpacing.lg),

          // Descrição
          FormTextField(
            label: 'Descrição',
            controller: _descriptionController,
            hintText: 'Descrição do produto (opcional)',
            maxLength: 500,
            maxLines: 4,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: DSSpacing.lg),

          // Status toggle
          _buildStatusToggle(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),

          // Botões
          _buildActionButtons(colors, isWeb),
          const SizedBox(height: DSSpacing.xl),
        ],
      ),
    );
  }

  // MARK: - Image Section

  Widget _buildImageSection(DSColors colors, DSTextStyle textStyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imagem do Produto', style: textStyles.labelLarge),
        const SizedBox(height: DSSpacing.sm),
        Text(
          'JPG, PNG ou WEBP • Máximo 5MB',
          style: textStyles.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: DSSpacing.md),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Preview
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: colors.scaffoldBackground,
                borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
                border: Border.all(color: colors.divider),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
                child: _buildImagePreview(colors),
              ),
            ),
            const SizedBox(width: DSSpacing.md),

            // Botões de upload/remover
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSButton.secondary(
                  label: 'Escolher Imagem',
                  icon: Icons.upload_rounded,
                  onTap: _pickImage,
                ),
                if (_imagePreview != null || _imagePreviewUrl != null) ...[
                  const SizedBox(height: DSSpacing.sm),
                  DSButton.text(
                    label: 'Remover',
                    icon: Icons.delete_outline,
                    onTap: _removeImage,
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(DSColors colors) {
    if (_imagePreview != null) {
      return Image.memory(_imagePreview!, fit: BoxFit.cover);
    }
    if (_imagePreviewUrl != null && _imagePreviewUrl!.isNotEmpty) {
      return AppNetworkImage(
        url: _imagePreviewUrl,
        fit: BoxFit.cover,
        placeholder: _imagePlaceholder(colors),
      );
    }
    return _imagePlaceholder(colors);
  }

  Widget _imagePlaceholder(DSColors colors) {
    return Center(
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: 48,
        color: colors.textTertiary.withValues(alpha: 0.4),
      ),
    );
  }

  // MARK: - Status Toggle

  Widget _buildStatusToggle(DSColors colors, DSTextStyle textStyles) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.check_circle_rounded : Icons.block_rounded,
            color: _isActive ? colors.green : colors.red,
          ),
          const SizedBox(width: DSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status do Produto', style: textStyles.labelLarge),
                const SizedBox(height: DSSpacing.xxs),
                Text(
                  _isActive
                      ? 'Produto ativo e visível'
                      : 'Produto inativo e oculto',
                  style: textStyles.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeColor: colors.green,
          ),
        ],
      ),
    );
  }

  // MARK: - Action Buttons

  Widget _buildActionButtons(DSColors colors, bool isWeb) {
    return Row(
      mainAxisAlignment: isWeb
          ? MainAxisAlignment.end
          : MainAxisAlignment.center,
      children: [
        if (isWeb) ...[
          DSButton.secondary(
            label: 'Cancelar',
            onTap: () => ProductsCoordinator.navigateBack(context),
          ),
          const SizedBox(width: DSSpacing.md),
        ],
        DSButton.primary(
          label: _viewModel.isEditing ? 'Salvar Alterações' : 'Criar Produto',
          icon: _viewModel.isEditing ? Icons.save_rounded : Icons.add_rounded,
          isLoading: _viewModel.isSaving,
          isExpanded: !isWeb,
          onTap: _viewModel.isSaving ? null : _handleSave,
        ),
      ],
    );
  }

  // MARK: - Actions

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final fileSize = bytes.length;

        // Validar tamanho (5MB)
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Imagem muito grande. Máximo 5MB.')),
            );
          }
          return;
        }

        // Validar extensão
        final ext = picked.name.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Formato não suportado. Use JPG, PNG ou WEBP.'),
              ),
            );
          }
          return;
        }

        setState(() => _imagePreview = bytes);
        _presenter.setImage(bytes, picked.name);
      }
    } catch (_) {
      // Permissão negada ou erro
    }
  }

  void _removeImage() {
    setState(() {
      _imagePreview = null;
      _imagePreviewUrl = null;
    });
    _presenter.removeImage();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final priceText = _priceController.text
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final price = double.tryParse(priceText) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;

    final success = await _presenter.save(
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      price: price,
      stock: stock,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActive,
    );

    if (success && mounted) {
      ProductsCoordinator.navigateBack(context, result: true);
    }
  }

  // MARK: - Validators

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nome é obrigatório';
    if (value.trim().length < 3) return 'Mínimo de 3 caracteres';
    if (value.trim().length > 100) return 'Máximo de 100 caracteres';
    return null;
  }

  String? _validateSku(String? value) {
    if (value == null || value.trim().isEmpty) return 'SKU é obrigatório';
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Preço é obrigatório';
    final parsed = double.tryParse(
      value.replaceAll('.', '').replaceAll(',', '.'),
    );
    if (parsed == null || parsed <= 0) return 'Informe um valor maior que zero';
    return null;
  }

  String? _validateStock(String? value) {
    if (value == null || value.trim().isEmpty) return 'Estoque é obrigatório';
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) return 'Informe um valor válido (≥ 0)';
    return null;
  }
}
