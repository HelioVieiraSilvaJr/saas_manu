import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'CustomerFormPresenter.dart';
import 'CustomerFormViewModel.dart';
import 'CustomersCoordinator.dart';

/// Página de criação/edição de cliente.
///
/// Formulário com validação, máscara WhatsApp, campo único.
class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({super.key});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  late final CustomerFormPresenter _presenter;
  CustomerFormViewModel _viewModel = const CustomerFormViewModel();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  bool _initialized = false;

  final _whatsappMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _presenter = CustomerFormPresenter(
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
        // Edição: argumento é customerId
        _presenter.initForEdit(args).then((_) => _populateFields());
      } else {
        // Criação
        _presenter.initForCreate();
      }
    }
  }

  void _populateFields() {
    final customer = _viewModel.customer;
    if (customer != null) {
      _nameController.text = customer.name;
      // Formatar WhatsApp com máscara
      if (customer.whatsapp.isNotEmpty) {
        _whatsappController.text = _whatsappMask.maskText(customer.whatsapp);
      }
      _emailController.text = customer.email ?? '';
      _notesController.text = customer.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/customers',
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
      return const LoadingIndicator(message: 'Carregando cliente...');
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
                _viewModel.isEditing ? 'Editar Cliente' : 'Novo Cliente',
                style: textStyles.headline1,
              ),
              const SizedBox(height: DSSpacing.xs),
              Text(
                _viewModel.isEditing
                    ? 'Atualize as informações do cliente'
                    : 'Preencha as informações para cadastrar um novo cliente',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        DSButton.secondary(
          label: 'Cancelar',
          onTap: () => CustomersCoordinator.navigateBack(context),
        ),
        const SizedBox(width: DSSpacing.md),
        DSButton.primary(
          label: _viewModel.isEditing
              ? 'Salvar Alterações'
              : 'Cadastrar Cliente',
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
            icon: Icons.person_outline_rounded,
            title: 'Dados do Cliente',
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
                        label: 'Nome Completo *',
                        controller: _nameController,
                        hintText: 'Ex: João da Silva',
                        prefixIcon: Icons.person_outline,
                        maxLength: 100,
                        validator: _validateName,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: DSSpacing.lg),
                    Expanded(
                      child: FormTextField(
                        label: 'WhatsApp *',
                        controller: _whatsappController,
                        hintText: '(11) 98765-4321',
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [_whatsappMask],
                        validator: _validateWhatsApp,
                        helperText: 'Principal meio de contato',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.lg),

                FormTextField(
                  label: 'Email',
                  controller: _emailController,
                  hintText: 'email@exemplo.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: DSSpacing.lg),

                FormTextField(
                  label: 'Observações',
                  controller: _notesController,
                  hintText: 'Observações sobre o cliente (opcional)',
                  maxLength: 500,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                ),
              ],
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
      return const LoadingIndicator(message: 'Carregando cliente...');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewModel.isEditing ? 'Editar Cliente' : 'Novo Cliente',
          style: textStyles.headline3,
        ),
        leading: IconButton(
          onPressed: () => CustomersCoordinator.navigateBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        backgroundColor: colors.cardBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DSSpacing.md),
        child: _buildMobileForm(colors, textStyles),
      ),
    );
  }

  Widget _buildMobileForm(DSColors colors, DSTextStyle textStyles) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_viewModel.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(DSSpacing.md),
              decoration: BoxDecoration(
                color: colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
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

          FormTextField(
            label: 'Nome Completo *',
            controller: _nameController,
            hintText: 'Ex: João da Silva',
            prefixIcon: Icons.person_outline,
            maxLength: 100,
            validator: _validateName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: DSSpacing.lg),

          FormTextField(
            label: 'WhatsApp *',
            controller: _whatsappController,
            hintText: '(11) 98765-4321',
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [_whatsappMask],
            validator: _validateWhatsApp,
            helperText: 'Principal meio de contato',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: DSSpacing.lg),

          FormTextField(
            label: 'Email',
            controller: _emailController,
            hintText: 'email@exemplo.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: DSSpacing.lg),

          FormTextField(
            label: 'Observações',
            controller: _notesController,
            hintText: 'Observações sobre o cliente (opcional)',
            maxLength: 500,
            maxLines: 4,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: DSSpacing.xl),

          DSButton.primary(
            label: _viewModel.isEditing ? 'Salvar Alterações' : 'Salvar',
            icon: _viewModel.isEditing ? Icons.save_rounded : Icons.add_rounded,
            isLoading: _viewModel.isSaving,
            isExpanded: true,
            onTap: _viewModel.isSaving ? null : _handleSave,
          ),
          const SizedBox(height: DSSpacing.xl),
        ],
      ),
    );
  }

  // MARK: - Actions

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Extrair apenas números do WhatsApp
    final whatsapp = _whatsappController.text.replaceAll(RegExp(r'[^\d]'), '');

    final success = await _presenter.save(
      name: _nameController.text.trim(),
      whatsapp: whatsapp,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (success && mounted) {
      CustomersCoordinator.navigateBack(context, result: true);
    }
  }

  // MARK: - Validators

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nome é obrigatório';
    if (value.trim().length < 3) return 'Mínimo de 3 caracteres';
    if (value.trim().length > 100) return 'Máximo de 100 caracteres';
    return null;
  }

  String? _validateWhatsApp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'WhatsApp é obrigatório';
    }
    final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length != 11) {
      return 'WhatsApp inválido (11 dígitos)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Opcional
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email inválido';
    }
    return null;
  }
}
