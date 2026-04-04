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

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _presenter = ProductFormPresenter(
      onViewModelUpdated: (viewModel) {
        if (mounted) {
          setState(() => _viewModel = viewModel);
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
        _presenter.initForEdit(args).then((_) => _populateFields());
      } else {
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
          _buildWebHeader(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),

          if (_viewModel.errorMessage != null) ...[
            _buildErrorBanner(colors, textStyles),
            const SizedBox(height: DSSpacing.lg),
          ],

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInfoCard(colors, textStyles),
                    const SizedBox(height: DSSpacing.xl),
                    _buildImageCard(colors, textStyles),
                    const SizedBox(height: DSSpacing.huge),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader(DSColors colors, DSTextStyle textStyles) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _viewModel.isEditing ? 'Editar Produto' : 'Novo Produto',
                style: textStyles.headline1,
              ),
              const SizedBox(height: DSSpacing.xs),
              Text(
                _viewModel.isEditing
                    ? 'Atualize as informações do produto'
                    : 'Preencha as informações para cadastrar um novo produto',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        DSButton.secondary(
          label: 'Cancelar',
          onTap: () => ProductsCoordinator.navigateBack(context),
        ),
        const SizedBox(width: DSSpacing.md),
        DSButton.primary(
          label: _viewModel.isEditing
              ? 'Salvar Alterações'
              : 'Cadastrar Produto',
          icon: _viewModel.isEditing ? Icons.save_rounded : Icons.add_rounded,
          isLoading: _viewModel.isSaving,
          onTap: _viewModel.isSaving ? null : _handleSave,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(DSColors colors, DSTextStyle textStyles) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.redLight,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.red, size: DSSpacing.iconMd),
          const SizedBox(width: DSSpacing.sm),
          Expanded(
            child: Text(
              _viewModel.errorMessage!,
              style: textStyles.bodyMedium.copyWith(color: colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    DSColors colors,
    DSTextStyle textStyles, {
    required IconData icon,
    required String title,
    String? badgeLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.lg,
        DSSpacing.lg,
        DSSpacing.lg,
        DSSpacing.base,
      ),
      child: Row(
        children: [
          Icon(icon, size: DSSpacing.iconMd, color: colors.primaryColor),
          const SizedBox(width: DSSpacing.sm),
          Text(title, style: textStyles.headline3),
          const Spacer(),
          if (badgeLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.md,
                vertical: DSSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.scaffoldBackground,
                borderRadius: BorderRadius.circular(DSSpacing.radiusFull),
                border: Border.all(color: colors.divider),
              ),
              child: Text(
                badgeLabel,
                style: textStyles.caption.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DSColors colors, DSTextStyle textStyles) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: DSSpacing.elevationSmBlur,
            offset: const Offset(0, DSSpacing.elevationSmOffset),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            colors,
            textStyles,
            icon: Icons.description_outlined,
            title: 'Informações Gerais',
            badgeLabel: 'obrigatório',
          ),
          Divider(height: 1, color: colors.divider),

          Padding(
            padding: const EdgeInsets.all(DSSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FormTextField(
                        label: 'Nome do Produto',
                        controller: _nameController,
                        hintText: 'Ex: Suporte Celular Universal',
                        maxLength: 100,
                        validator: _validateName,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: DSSpacing.lg),
                    Expanded(
                      child: FormTextField(
                        label: 'SKU',
                        controller: _skuController,
                        hintText: 'Ex: SUP-CEL-001',
                        validator: _validateSku,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.lg),

                FormTextField(
                  label: 'Descrição',
                  controller: _descriptionController,
                  hintText:
                      'Descrição detalhada do produto, características, materiais, instruções de uso...',
                  maxLength: 500,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: DSSpacing.lg),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FormTextField(
                        label: 'Preço',
                        controller: _priceController,
                        hintText: 'Ex: 89,90',
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
                        label: 'Estoque',
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
                const SizedBox(height: DSSpacing.lg),

                _buildStatusToggle(colors, textStyles),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Image Card (Multi-Photo)

  Widget _buildImageCard(DSColors colors, DSTextStyle textStyles) {
    final imageCount = _viewModel.imageCount;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: DSSpacing.elevationSmBlur,
            offset: const Offset(0, DSSpacing.elevationSmOffset),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            colors,
            textStyles,
            icon: Icons.photo_library_outlined,
            title: 'Fotos do Produto',
            badgeLabel: '$imageCount / 5',
          ),
          Divider(height: 1, color: colors.divider),

          Padding(
            padding: const EdgeInsets.all(DSSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid de fotos
                Wrap(
                  spacing: DSSpacing.md,
                  runSpacing: DSSpacing.md,
                  children: [
                    for (var i = 0; i < _viewModel.images.length; i++)
                      _buildImageThumbnail(colors, textStyles, i),
                    if (_viewModel.canAddImage)
                      _buildAddImageButton(colors, textStyles),
                  ],
                ),
                const SizedBox(height: DSSpacing.md),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: DSSpacing.xs),
                    Text(
                      'Formatos: JPG, PNG, WEBP (até 5MB). Clique na estrela para definir a foto principal.',
                      style: textStyles.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(
    DSColors colors,
    DSTextStyle textStyles,
    int index,
  ) {
    final item = _viewModel.images[index];

    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: 108,
        height: 130,
        child: Column(
          children: [
            // Thumbnail com botões sobrepostos
            SizedBox(
              width: 108,
              height: 108,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Imagem
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                      border: Border.all(
                        color: item.isMain
                            ? colors.secundaryColor
                            : colors.divider,
                        width: item.isMain ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        DSSpacing.radiusMd - 1,
                      ),
                      child: item.isLocal
                          ? Image.memory(item.bytes!, fit: BoxFit.cover)
                          : item.isRemote
                          ? AppNetworkImage(
                              url: item.url,
                              fit: BoxFit.cover,
                              placeholder: _imagePlaceholder(colors),
                            )
                          : _imagePlaceholder(colors),
                    ),
                  ),

                  // Botão remover (canto superior direito)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _presenter.removeImage(index),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.cardBackground,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Badge principal (canto inferior esquerdo)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: () => _presenter.setMainImage(index),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: item.isMain
                              ? colors.secundaryColor
                              : colors.cardBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: item.isMain
                                ? colors.secundaryColor
                                : colors.divider,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: item.isMain
                              ? Colors.white
                              : colors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DSSpacing.xs),
            // Label
            Text(
              item.isMain ? 'Principal' : 'Foto ${index + 1}',
              style: textStyles.caption.copyWith(
                color: item.isMain
                    ? colors.secundaryColor
                    : colors.textTertiary,
                fontWeight: item.isMain ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageButton(DSColors colors, DSTextStyle textStyles) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.scaffoldBackground,
            borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
            border: Border.all(
              color: colors.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: DSSpacing.iconLg,
                color: colors.primaryColor,
              ),
              const SizedBox(height: DSSpacing.xxs),
              Text(
                'Adicionar',
                style: textStyles.caption.copyWith(
                  color: colors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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

  // MARK: - Form (Mobile)

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
          if (_viewModel.errorMessage != null) ...[
            _buildErrorBanner(colors, textStyles),
            const SizedBox(height: DSSpacing.lg),
          ],

          _buildImageSection(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),

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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          const SizedBox(height: DSSpacing.lg),

          FormTextField(
            label: 'Descrição',
            controller: _descriptionController,
            hintText: 'Descrição do produto (opcional)',
            maxLength: 500,
            maxLines: 4,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: DSSpacing.lg),

          _buildStatusToggle(colors, textStyles),
          const SizedBox(height: DSSpacing.xl),

          _buildMobileActionButtons(colors),
          const SizedBox(height: DSSpacing.xl),
        ],
      ),
    );
  }

  // MARK: - Image Section (Mobile)

  Widget _buildImageSection(DSColors colors, DSTextStyle textStyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotos do Produto', style: textStyles.labelLarge),
        const SizedBox(height: DSSpacing.xs),
        Text(
          'JPG, PNG ou WEBP • Máximo 5MB • Até 5 fotos',
          style: textStyles.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: DSSpacing.md),

        Wrap(
          spacing: DSSpacing.sm,
          runSpacing: DSSpacing.sm,
          children: [
            for (var i = 0; i < _viewModel.images.length; i++)
              _buildMobileImageThumbnail(colors, textStyles, i),
            if (_viewModel.canAddImage)
              _buildMobileAddButton(colors, textStyles),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileImageThumbnail(
    DSColors colors,
    DSTextStyle textStyles,
    int index,
  ) {
    final item = _viewModel.images[index];

    return SizedBox(
      width: 88,
      height: 104,
      child: Column(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                    border: Border.all(
                      color: item.isMain
                          ? colors.secundaryColor
                          : colors.divider,
                      width: item.isMain ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DSSpacing.radiusMd - 1),
                    child: item.isLocal
                        ? Image.memory(item.bytes!, fit: BoxFit.cover)
                        : item.isRemote
                        ? AppNetworkImage(
                            url: item.url,
                            fit: BoxFit.cover,
                            placeholder: _imagePlaceholder(colors),
                          )
                        : _imagePlaceholder(colors),
                  ),
                ),

                // Remover
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _presenter.removeImage(index),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.cardBackground,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Marcar principal
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () => _presenter.setMainImage(index),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: item.isMain
                            ? colors.secundaryColor
                            : colors.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.isMain
                              ? colors.secundaryColor
                              : colors.divider,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        size: 10,
                        color: item.isMain ? Colors.white : colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.isMain ? 'Principal' : '',
            style: textStyles.caption.copyWith(
              color: colors.secundaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAddButton(DSColors colors, DSTextStyle textStyles) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.scaffoldBackground,
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          border: Border.all(color: colors.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: DSSpacing.iconMd,
              color: colors.primaryColor,
            ),
            Text(
              'Adicionar',
              style: textStyles.caption.copyWith(
                color: colors.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
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
            activeThumbColor: colors.green,
          ),
        ],
      ),
    );
  }

  // MARK: - Action Buttons

  Widget _buildMobileActionButtons(DSColors colors) {
    return DSButton.primary(
      label: _viewModel.isEditing ? 'Salvar Alterações' : 'Criar Produto',
      icon: _viewModel.isEditing ? Icons.save_rounded : Icons.add_rounded,
      isLoading: _viewModel.isSaving,
      isExpanded: true,
      onTap: _viewModel.isSaving ? null : _handleSave,
    );
  }

  // MARK: - Actions

  Future<void> _pickImage() async {
    if (!_viewModel.canAddImage) return;

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

        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Imagem muito grande. Máximo 5MB.')),
            );
          }
          return;
        }

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

        _presenter.addImage(bytes, picked.name);
      }
    } catch (_) {
      // Permissão negada ou erro
    }
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
