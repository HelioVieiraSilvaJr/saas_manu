import '../../Commons/Models/ProductModel.dart';

/// Estado do formulário de produto.
class ProductFormViewModel {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final ProductModel? product;
  final bool isEditing;
  final bool hasImageChanged;
  final String? imagePreviewUrl;

  const ProductFormViewModel({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.product,
    this.isEditing = false,
    this.hasImageChanged = false,
    this.imagePreviewUrl,
  });

  ProductFormViewModel copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    ProductModel? product,
    bool? isEditing,
    bool? hasImageChanged,
    String? imagePreviewUrl,
    bool clearError = true,
    bool clearSuccess = true,
  }) {
    return ProductFormViewModel(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError
          ? errorMessage
          : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? successMessage
          : (successMessage ?? this.successMessage),
      product: product ?? this.product,
      isEditing: isEditing ?? this.isEditing,
      hasImageChanged: hasImageChanged ?? this.hasImageChanged,
      imagePreviewUrl: imagePreviewUrl ?? this.imagePreviewUrl,
    );
  }
}
