import 'package:flutter/material.dart';
import '../../Commons/Extensions/String+Extensions.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/FormTextField.dart';
import '../../Commons/Widgets/DesignSystem/LoadingIndicator.dart';
import 'SaleFormPresenter.dart';
import 'SaleFormViewModel.dart';
import 'Widgets/CartWidget.dart';
import 'Widgets/CustomerSearchModal.dart';
import 'Widgets/ProductSearchModal.dart';

/// Página de criação de nova venda.
///
/// Web: Layout único com cliente + produtos + resumo.
/// Mobile: Wizard de 3 passos.
class SaleFormPage extends StatefulWidget {
  const SaleFormPage({super.key});

  @override
  State<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends State<SaleFormPage> {
  final _presenter = SaleFormPresenter();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter.onUpdate = () => setState(() {});
    _presenter.init();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomer() async {
    final customer = await CustomerSearchModal.show(
      context: context,
      customers: _presenter.viewModel.customers,
      onCreateNew: () {
        Navigator.pushNamed(context, '/customers/new');
      },
    );
    if (customer != null) {
      _presenter.selectCustomer(customer);
    }
  }

  Future<void> _addProduct() async {
    final result = await ProductSearchModal.show(
      context: context,
      products: _presenter.viewModel.products,
    );
    if (result != null) {
      final error = _presenter.addToCart(
        result.product,
        quantity: result.quantity,
      );
      if (error != null && mounted) {
        await DSAlertDialog.showWarning(
          context: context,
          title: 'Estoque Insuficiente',
          message: error,
        );
      }
    }
  }

  void _updateQuantity(int index, int quantity) {
    final error = _presenter.updateCartItemQuantity(index, quantity);
    if (error != null && mounted) {
      DSAlertDialog.showWarning(
        context: context,
        title: 'Estoque Insuficiente',
        message: error,
      );
    }
  }

  Future<void> _confirmSale() async {
    if (!_presenter.viewModel.canConfirm) return;

    final confirm = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Confirmar Venda',
      message:
          'Total: ${_presenter.viewModel.cartTotal.formatToBRL()}\n'
          'Cliente: ${_presenter.viewModel.selectedCustomer!.name}\n'
          '${_presenter.viewModel.cartItems.length} produto(s)',
    );

    if (confirm != true || !mounted) return;

    final success = await _presenter.confirmSale(notes: _notesController.text);

    if (success && mounted) {
      await DSAlertDialog.showSuccess(
        context: context,
        title: 'Venda Realizada!',
        message: 'Venda registrada com sucesso.',
      );
      if (mounted) Navigator.pop(context, true);
    } else if (!success && mounted) {
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro',
        message: _presenter.viewModel.errorMessage ?? 'Erro ao registrar venda',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenResponsive(
      web: _buildWebLayout(),
      mobile: _buildMobileLayout(),
    );
  }

  // MARK: - Web Layout

  Widget _buildWebLayout() {
    final vm = _presenter.viewModel;
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Venda'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: vm.isLoading
          ? const LoadingIndicator(message: 'Carregando...')
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.pagePaddingHorizontalWeb,
                    vertical: DSSpacing.pagePaddingVerticalWeb,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Cliente
                      Text('1. Cliente *', style: textStyles.headline3),
                      const SizedBox(height: DSSpacing.sm),
                      _buildCustomerSection(vm, colors, textStyles),
                      const SizedBox(height: DSSpacing.xl),

                      // 2. Produtos
                      Text('2. Produtos *', style: textStyles.headline3),
                      const SizedBox(height: DSSpacing.sm),
                      DSButton.secondary(
                        label: 'Buscar Produto',
                        icon: Icons.search,
                        onTap: _addProduct,
                      ),
                      const SizedBox(height: DSSpacing.sm),
                      CartWidget(
                        items: vm.cartItems,
                        onUpdateQuantity: _updateQuantity,
                        onRemove: _presenter.removeFromCart,
                      ),
                      const SizedBox(height: DSSpacing.xl),

                      // 3. Observações
                      Text('3. Observações', style: textStyles.headline3),
                      const SizedBox(height: DSSpacing.sm),
                      FormTextField(
                        label: 'Observações',
                        controller: _notesController,
                        maxLines: 3,
                        maxLength: 500,
                        hintText: 'Notas sobre esta venda...',
                      ),
                      const SizedBox(height: DSSpacing.xl),

                      // Resumo
                      Container(
                        padding: const EdgeInsets.all(DSSpacing.base),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(
                            DSSpacing.radiusLg,
                          ),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal (${vm.cartItemsCount} itens)',
                                  style: textStyles.bodyMedium,
                                ),
                                Text(
                                  vm.cartTotal.formatToBRL(),
                                  style: textStyles.bodyMedium,
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('TOTAL', style: textStyles.headline3),
                                Text(
                                  vm.cartTotal.formatToBRL(),
                                  style: textStyles.headline3.copyWith(
                                    color: colors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DSSpacing.xl),

                      // Botões
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          DSButton.secondary(
                            label: 'Cancelar',
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: DSSpacing.base),
                          DSButton.primary(
                            label: 'Confirmar Venda',
                            icon: Icons.check,
                            isLoading: vm.isSaving,
                            onTap: vm.canConfirm ? _confirmSale : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: DSSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // MARK: - Mobile Layout (Wizard)

  Widget _buildMobileLayout() {
    final vm = _presenter.viewModel;
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Scaffold(
      appBar: AppBar(
        title: Text(_mobileStepTitle(vm.currentStep)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: vm.isLoading
          ? const LoadingIndicator(message: 'Carregando...')
          : Column(
              children: [
                // Stepper indicator
                _buildStepIndicator(vm.currentStep, colors, textStyles),
                // Content
                Expanded(child: _buildMobileStep(vm, colors, textStyles)),
              ],
            ),
      bottomNavigationBar: vm.isLoading
          ? null
          : _buildMobileBottomBar(vm, colors, textStyles),
    );
  }

  String _mobileStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Selecionar Cliente';
      case 1:
        return 'Adicionar Produtos';
      case 2:
        return 'Confirmar Venda';
      default:
        return 'Nova Venda';
    }
  }

  Widget _buildStepIndicator(
    int current,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Padding(
      padding: const EdgeInsets.all(DSSpacing.base),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= current;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: DSSpacing.xxs),
              decoration: BoxDecoration(
                color: isActive ? colors.primaryColor : colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMobileStep(
    SaleFormViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    switch (vm.currentStep) {
      case 0:
        return _buildMobileCustomerStep(vm, colors, textStyles);
      case 1:
        return _buildMobileProductsStep(vm, colors, textStyles);
      case 2:
        return _buildMobileConfirmStep(vm, colors, textStyles);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMobileCustomerStep(
    SaleFormViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DSSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildCustomerSection(vm, colors, textStyles)],
      ),
    );
  }

  Widget _buildMobileProductsStep(
    SaleFormViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(DSSpacing.base),
          child: DSButton.secondary(
            label: 'Buscar Produto',
            icon: Icons.search,
            isExpanded: true,
            onTap: _addProduct,
          ),
        ),
        Expanded(
          child: CartWidget(
            items: vm.cartItems,
            onUpdateQuantity: _updateQuantity,
            onRemove: _presenter.removeFromCart,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileConfirmStep(
    SaleFormViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DSSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cliente
          Text('Cliente', style: textStyles.labelLarge),
          const SizedBox(height: DSSpacing.sm),
          if (vm.selectedCustomer != null)
            ListTile(
              leading: DSAvatar(name: vm.selectedCustomer!.name, size: 40),
              title: Text(vm.selectedCustomer!.name),
              subtitle: Text(vm.selectedCustomer!.whatsapp.formatWhatsApp()),
              tileColor: colors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                side: BorderSide(color: colors.divider),
              ),
            ),
          const SizedBox(height: DSSpacing.base),

          // Produtos
          Text(
            'Produtos (${vm.cartItemsCount} itens)',
            style: textStyles.labelLarge,
          ),
          const SizedBox(height: DSSpacing.sm),
          ...vm.cartItems.map(
            (item) => ListTile(
              title: Text(item.product.name),
              subtitle: Text(
                '${item.product.price.formatToBRL()} x ${item.quantity}',
              ),
              trailing: Text(item.subtotal.formatToBRL()),
              dense: true,
            ),
          ),
          const Divider(),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: textStyles.headline3),
              Text(
                vm.cartTotal.formatToBRL(),
                style: textStyles.headline3.copyWith(
                  color: colors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.base),

          // Observações
          FormTextField(
            label: 'Observações',
            controller: _notesController,
            maxLines: 3,
            maxLength: 500,
            hintText: 'Notas sobre esta venda...',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomBar(
    SaleFormViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.base),
        child: Row(
          children: [
            if (vm.currentStep > 0)
              Expanded(
                child: DSButton.secondary(
                  label: 'Voltar',
                  onTap: _presenter.previousStep,
                ),
              ),
            if (vm.currentStep > 0) const SizedBox(width: DSSpacing.base),
            Expanded(
              child: vm.currentStep < 2
                  ? DSButton.primary(
                      label: 'Próximo',
                      onTap: _canAdvance(vm) ? _presenter.nextStep : null,
                    )
                  : DSButton.primary(
                      label: 'Confirmar Venda',
                      icon: Icons.check,
                      isLoading: vm.isSaving,
                      onTap: vm.canConfirm ? _confirmSale : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canAdvance(SaleFormViewModel vm) {
    switch (vm.currentStep) {
      case 0:
        return vm.selectedCustomer != null;
      case 1:
        return vm.cartItems.isNotEmpty;
      default:
        return false;
    }
  }

  // MARK: - Shared Widgets

  Widget _buildCustomerSection(
    SaleFormViewModel vm,
    DSColors colors,
    DSTextStyle textStyles,
  ) {
    if (vm.selectedCustomer != null) {
      final customer = vm.selectedCustomer!;
      return Container(
        padding: const EdgeInsets.all(DSSpacing.cardPaddingLg),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
          border: Border.all(color: colors.green),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: colors.green),
            const SizedBox(width: DSSpacing.sm),
            DSAvatar(name: customer.name, size: 40),
            const SizedBox(width: DSSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: textStyles.labelMedium),
                  Text(
                    customer.whatsapp.formatWhatsApp(),
                    style: textStyles.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: colors.red),
              onPressed: _presenter.clearCustomer,
              tooltip: 'Remover cliente',
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        DSButton.secondary(
          label: 'Buscar Cliente',
          icon: Icons.search,
          isExpanded: true,
          onTap: _selectCustomer,
        ),
      ],
    );
  }
}
