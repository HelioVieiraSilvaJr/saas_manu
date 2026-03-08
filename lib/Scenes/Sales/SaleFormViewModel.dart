import '../../Commons/Models/SaleItemModel.dart';
import '../../Commons/Models/CustomerModel.dart';
import '../../Commons/Models/ProductModel.dart';

/// Item do carrinho (produto + quantidade).
class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  SaleItemModel toSaleItem() {
    return SaleItemModel(
      productId: product.uid,
      productName: product.name,
      quantity: quantity,
      unitPrice: product.price,
      subtotal: subtotal,
    );
  }
}

/// ViewModel do formulário de venda.
class SaleFormViewModel {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  // Passo atual (Mobile wizard)
  final int currentStep;

  // Cliente selecionado
  final CustomerModel? selectedCustomer;

  // Carrinho
  final List<CartItem> cartItems;

  // Observações
  final String notes;

  // Listas para busca
  final List<CustomerModel> customers;
  final List<ProductModel> products;
  final String customerSearchQuery;
  final String productSearchQuery;

  const SaleFormViewModel({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.currentStep = 0,
    this.selectedCustomer,
    this.cartItems = const [],
    this.notes = '',
    this.customers = const [],
    this.products = const [],
    this.customerSearchQuery = '',
    this.productSearchQuery = '',
  });

  SaleFormViewModel copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    int? currentStep,
    CustomerModel? selectedCustomer,
    List<CartItem>? cartItems,
    String? notes,
    List<CustomerModel>? customers,
    List<ProductModel>? products,
    String? customerSearchQuery,
    String? productSearchQuery,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearCustomer = false,
  }) {
    return SaleFormViewModel(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      currentStep: currentStep ?? this.currentStep,
      selectedCustomer: clearCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      cartItems: cartItems ?? this.cartItems,
      notes: notes ?? this.notes,
      customers: customers ?? this.customers,
      products: products ?? this.products,
      customerSearchQuery: customerSearchQuery ?? this.customerSearchQuery,
      productSearchQuery: productSearchQuery ?? this.productSearchQuery,
    );
  }

  /// Total do carrinho.
  double get cartTotal =>
      cartItems.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Total de itens no carrinho.
  int get cartItemsCount =>
      cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// Verifica se pode confirmar a venda.
  bool get canConfirm =>
      selectedCustomer != null && cartItems.isNotEmpty && !isSaving;

  /// Clientes filtrados pela busca.
  List<CustomerModel> get filteredCustomers {
    if (customerSearchQuery.isEmpty) return customers;
    final q = customerSearchQuery.toLowerCase();
    return customers
        .where(
          (c) => c.name.toLowerCase().contains(q) || c.whatsapp.contains(q),
        )
        .toList();
  }

  /// Produtos filtrados pela busca (apenas ativos com estoque).
  List<ProductModel> get filteredProducts {
    var list = products.where((p) => p.isActive && p.stock > 0).toList();
    if (productSearchQuery.isEmpty) return list;
    final q = productSearchQuery.toLowerCase();
    return list
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q),
        )
        .toList();
  }
}
