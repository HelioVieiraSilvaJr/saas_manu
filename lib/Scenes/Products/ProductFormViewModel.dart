import 'dart:typed_data';

import '../../Commons/Models/ProductModel.dart';

/// Representa uma imagem no form (nova local ou existente remota).
class ProductImageItem {
  final Uint8List? bytes;
  final String? fileName;
  final String? url;
  final bool isMain;

  const ProductImageItem({
    this.bytes,
    this.fileName,
    this.url,
    this.isMain = false,
  });

  bool get isLocal => bytes != null;
  bool get isRemote => url != null && url!.isNotEmpty;

  ProductImageItem copyWith({bool? isMain}) {
    return ProductImageItem(
      bytes: bytes,
      fileName: fileName,
      url: url,
      isMain: isMain ?? this.isMain,
    );
  }
}

/// Estado do formulário de produto.
class ProductFormViewModel {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final ProductModel? product;
  final bool isEditing;
  final List<ProductImageItem> images;
  final List<String> removedImageUrls;

  const ProductFormViewModel({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.product,
    this.isEditing = false,
    this.images = const [],
    this.removedImageUrls = const [],
  });

  /// Índice da imagem principal.
  int get mainImageIndex =>
      images.indexWhere((i) => i.isMain).clamp(0, images.length - 1);

  /// Quantidade de imagens.
  int get imageCount => images.length;

  /// Pode adicionar mais imagens (máximo 5).
  bool get canAddImage => images.length < 5;

  ProductFormViewModel copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    ProductModel? product,
    bool? isEditing,
    List<ProductImageItem>? images,
    List<String>? removedImageUrls,
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
      images: images ?? this.images,
      removedImageUrls: removedImageUrls ?? this.removedImageUrls,
    );
  }
}
