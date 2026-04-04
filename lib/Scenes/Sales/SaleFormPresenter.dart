import 'package:flutter/foundation.dart';
import '../../Commons/Enums/SaleSource.dart';
import '../../Commons/Enums/SaleStatus.dart';
import '../../Commons/Models/CustomerModel.dart';
import '../../Commons/Models/ProductModel.dart';
import '../../Commons/Models/SaleModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../Customers/CustomersRepository.dart';
import '../Products/ProductsRepository.dart';
import 'SaleFormViewModel.dart';
import 'SalesRepository.dart';

/// Presenter do formulário de nova venda.
///
/// Gerencia seleção de cliente, carrinho de produtos e confirmação.
class SaleFormPresenter {
  final SalesRepository _salesRepository = SalesRepository();
  final CustomersRepository _customersRepository = CustomersRepository();
  final ProductsRepository _productsRepository = ProductsRepository();

  SaleFormViewModel _viewModel = const SaleFormViewModel();
  SaleFormViewModel get viewModel => _viewModel;

  VoidCallback? onUpdate;

  // MARK: - Inicialização

  /// Carrega clientes e produtos para os modais de busca.
  Future<void> init() async {
    _viewModel = _viewModel.copyWith(isLoading: true);
    onUpdate?.call();

    try {
      final customers = await _customersRepository.getAll();
      final products = await _productsRepository.getAll();

      _viewModel = _viewModel.copyWith(
        isLoading: false,
        customers: customers.where((c) => c.isActive).toList(),
        products: products.where((p) => p.isActive).toList(),
      );
    } catch (e) {
      AppLogger.error('Erro ao carregar dados do formulário', error: e);
      _viewModel = _viewModel.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dados',
      );
    }

    onUpdate?.call();
  }

  // MARK: - Cliente

  /// Seleciona um cliente para a venda.
  void selectCustomer(CustomerModel customer) {
    _viewModel = _viewModel.copyWith(selectedCustomer: customer);
    onUpdate?.call();
  }

  /// Remove o cliente selecionado.
  void clearCustomer() {
    _viewModel = _viewModel.copyWith(clearCustomer: true);
    onUpdate?.call();
  }

  /// Busca de clientes.
  void searchCustomers(String query) {
    _viewModel = _viewModel.copyWith(customerSearchQuery: query);
    onUpdate?.call();
  }

  // MARK: - Produtos / Carrinho

  /// Busca de produtos.
  void searchProducts(String query) {
    _viewModel = _viewModel.copyWith(productSearchQuery: query);
    onUpdate?.call();
  }

  /// Adiciona um produto ao carrinho.
  /// Retorna mensagem de erro se estoque insuficiente.
  String? addToCart(ProductModel product, {int quantity = 1}) {
    // Verificar estoque
    final currentInCart = _viewModel.cartItems
        .where((item) => item.product.uid == product.uid)
        .fold(0, (sum, item) => sum + item.quantity);

    if (currentInCart + quantity > product.stock) {
      return 'Estoque insuficiente. Disponível: ${product.stock} un.';
    }

    final items = List<CartItem>.from(_viewModel.cartItems);
    final existingIndex = items.indexWhere(
      (item) => item.product.uid == product.uid,
    );

    if (existingIndex >= 0) {
      items[existingIndex].quantity += quantity;
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }

    _viewModel = _viewModel.copyWith(cartItems: items);
    onUpdate?.call();
    return null;
  }

  /// Atualiza a quantidade de um item no carrinho.
  String? updateCartItemQuantity(int index, int newQuantity) {
    if (index < 0 || index >= _viewModel.cartItems.length) return null;

    final item = _viewModel.cartItems[index];
    if (newQuantity > item.product.stock) {
      return 'Estoque insuficiente. Disponível: ${item.product.stock} un.';
    }

    if (newQuantity <= 0) {
      removeFromCart(index);
      return null;
    }

    final items = List<CartItem>.from(_viewModel.cartItems);
    items[index].quantity = newQuantity;
    _viewModel = _viewModel.copyWith(cartItems: items);
    onUpdate?.call();
    return null;
  }

  /// Remove um item do carrinho.
  void removeFromCart(int index) {
    final items = List<CartItem>.from(_viewModel.cartItems);
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      _viewModel = _viewModel.copyWith(cartItems: items);
      onUpdate?.call();
    }
  }

  // MARK: - Wizard (Mobile)

  /// Avança para o próximo passo.
  void nextStep() {
    if (_viewModel.currentStep < 2) {
      _viewModel = _viewModel.copyWith(currentStep: _viewModel.currentStep + 1);
      onUpdate?.call();
    }
  }

  /// Volta para o passo anterior.
  void previousStep() {
    if (_viewModel.currentStep > 0) {
      _viewModel = _viewModel.copyWith(currentStep: _viewModel.currentStep - 1);
      onUpdate?.call();
    }
  }

  // MARK: - Confirmação

  /// Confirma a venda manual. Retorna true se sucesso.
  Future<bool> confirmSale({String? notes}) async {
    if (!_viewModel.canConfirm) return false;

    _viewModel = _viewModel.copyWith(isSaving: true, clearError: true);
    onUpdate?.call();

    try {
      final customer = _viewModel.selectedCustomer!;

      final sale = SaleModel(
        uid: '',
        customerId: customer.uid,
        customerName: customer.name,
        customerWhatsapp: customer.whatsapp,
        items: _viewModel.cartItems.map((item) => item.toSaleItem()).toList(),
        total: _viewModel.cartTotal,
        status: SaleStatus.confirmed,
        source: SaleSource.manual,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
        createdAt: DateTime.now(),
      );

      // 1. Criar venda + baixar estoque + atualizar cliente em transação
      await _salesRepository.createConfirmedManualSaleTransaction(sale);

      final now = DateTime.now();
      final updatedProducts = _viewModel.products.map((product) {
        final cartItem = _viewModel.cartItems
            .where((item) => item.product.uid == product.uid)
            .firstOrNull;
        if (cartItem == null) return product;
        return product.copyWith(
          stock: (product.stock - cartItem.quantity).clamp(0, product.stock),
          updatedAt: now,
        );
      }).toList();

      final updatedCustomers = _viewModel.customers.map((existingCustomer) {
        if (existingCustomer.uid != customer.uid) return existingCustomer;
        return existingCustomer.copyWith(
          purchaseCount: (existingCustomer.purchaseCount ?? 0) + 1,
          totalSpent: (existingCustomer.totalSpent ?? 0) + sale.total,
          lastPurchaseAt: now,
          updatedAt: now,
        );
      }).toList();

      _viewModel = _viewModel.copyWith(
        isSaving: false,
        successMessage: 'Venda registrada com sucesso!',
        products: updatedProducts,
        customers: updatedCustomers,
      );
      onUpdate?.call();

      return true;
    } catch (e) {
      AppLogger.error('Erro ao confirmar venda', error: e);
      _viewModel = _viewModel.copyWith(
        isSaving: false,
        errorMessage:
            'Erro ao registrar venda: ${e.toString().replaceAll('Exception: ', '')}',
      );
      onUpdate?.call();
      return false;
    }
  }
}
