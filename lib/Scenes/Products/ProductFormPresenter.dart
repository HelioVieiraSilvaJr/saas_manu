import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../Commons/Models/ProductModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import 'ProductsRepository.dart';
import 'ProductFormViewModel.dart';

/// Presenter do formulário de produto (criar/editar).
class ProductFormPresenter {
  final ProductsRepository _repository = ProductsRepository();
  final ValueChanged<ProductFormViewModel> onViewModelUpdated;

  ProductFormViewModel _viewModel = const ProductFormViewModel();
  ProductFormViewModel get viewModel => _viewModel;

  BuildContext? context;

  ProductFormPresenter({required this.onViewModelUpdated});

  // MARK: - Init

  /// Inicializa para criar novo produto.
  void initForCreate() {
    _update(
      _viewModel.copyWith(product: ProductModel.newModel(), isEditing: false),
    );
  }

  /// Inicializa para editar produto existente.
  Future<void> initForEdit(String productId) async {
    _update(_viewModel.copyWith(isLoading: true, isEditing: true));

    final product = await _repository.getById(productId);
    if (product != null) {
      // Converte URLs existentes em ProductImageItem
      final existingImages = <ProductImageItem>[];
      for (var i = 0; i < product.imageUrls.length; i++) {
        existingImages.add(
          ProductImageItem(
            url: product.imageUrls[i],
            isMain: i == product.mainImageIndex,
          ),
        );
      }
      // Se não há main marcado, marcar o primeiro
      if (existingImages.isNotEmpty && !existingImages.any((e) => e.isMain)) {
        existingImages[0] = existingImages[0].copyWith(isMain: true);
      }

      _update(
        _viewModel.copyWith(
          isLoading: false,
          product: product,
          images: existingImages,
        ),
      );
    } else {
      _update(
        _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Produto não encontrado.',
          clearError: false,
        ),
      );
    }
  }

  // MARK: - Image

  /// Adiciona uma nova imagem local.
  void addImage(Uint8List bytes, String fileName) {
    if (!_viewModel.canAddImage) return;

    final images = List<ProductImageItem>.from(_viewModel.images);
    final isFirst = images.isEmpty;
    images.add(
      ProductImageItem(bytes: bytes, fileName: fileName, isMain: isFirst),
    );
    _update(_viewModel.copyWith(images: images));
  }

  /// Remove uma imagem pelo índice.
  void removeImage(int index) {
    if (index < 0 || index >= _viewModel.images.length) return;

    final removed = _viewModel.images[index];
    final images = List<ProductImageItem>.from(_viewModel.images);
    final wasMain = images[index].isMain;
    images.removeAt(index);

    // Rastrear URLs remotas removidas para deletar do Storage
    final removedUrls = List<String>.from(_viewModel.removedImageUrls);
    if (removed.isRemote) {
      removedUrls.add(removed.url!);
    }

    // Se a removida era a principal, promover a primeira
    if (wasMain && images.isNotEmpty) {
      images[0] = images[0].copyWith(isMain: true);
    }

    _update(_viewModel.copyWith(images: images, removedImageUrls: removedUrls));
  }

  /// Define qual imagem é a principal.
  void setMainImage(int index) {
    if (index < 0 || index >= _viewModel.images.length) return;

    final images = _viewModel.images
        .asMap()
        .entries
        .map((e) => e.value.copyWith(isMain: e.key == index))
        .toList();
    _update(_viewModel.copyWith(images: images));
  }

  // MARK: - Validate SKU

  /// Verifica se o SKU é único.
  Future<bool> validateSku(String sku) async {
    return await _repository.skuExists(
      sku,
      excludeId: _viewModel.isEditing ? _viewModel.product?.uid : null,
    );
  }

  // MARK: - Save

  /// Salva o produto (criar ou atualizar).
  Future<bool> save({
    required String name,
    required String sku,
    required double price,
    required int stock,
    String? description,
    required bool isActive,
  }) async {
    if (context == null) return false;

    _update(_viewModel.copyWith(isSaving: true));

    try {
      // Validar SKU único
      final skuExists = await _repository.skuExists(
        sku,
        excludeId: _viewModel.isEditing ? _viewModel.product?.uid : null,
      );

      if (skuExists) {
        _update(
          _viewModel.copyWith(
            isSaving: false,
            errorMessage: 'Este SKU já está em uso.',
            clearError: false,
          ),
        );
        return false;
      }

      if (_viewModel.isEditing) {
        return await _saveEdit(
          name: name,
          sku: sku,
          price: price,
          stock: stock,
          description: description,
          isActive: isActive,
        );
      } else {
        return await _saveCreate(
          name: name,
          sku: sku,
          price: price,
          stock: stock,
          description: description,
          isActive: isActive,
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar produto', error: e);
      _update(
        _viewModel.copyWith(
          isSaving: false,
          errorMessage: 'Erro inesperado ao salvar produto.',
          clearError: false,
        ),
      );
      return false;
    }
  }

  // MARK: - Save Helpers

  Future<bool> _saveEdit({
    required String name,
    required String sku,
    required double price,
    required int stock,
    String? description,
    required bool isActive,
  }) async {
    final product = _viewModel.product!.copyWith(
      name: name,
      sku: sku,
      price: price,
      stock: stock,
      description: description,
      isActive: isActive,
      updatedAt: DateTime.now(),
    );

    // 1. Deletar imagens remotas removidas do Storage
    for (final url in _viewModel.removedImageUrls) {
      await _repository.deleteImage(url);
    }

    // 2. Upload das novas imagens locais
    final finalUrls = <String>[];
    int mainIdx = 0;

    for (var i = 0; i < _viewModel.images.length; i++) {
      final item = _viewModel.images[i];
      if (item.isMain) mainIdx = i;

      if (item.isRemote) {
        finalUrls.add(item.url!);
      } else if (item.isLocal) {
        final url = await _repository.uploadImage(
          productId: product.uid,
          imageBytes: item.bytes!,
          fileName: item.fileName!,
        );
        if (url != null) finalUrls.add(url);
      }
    }

    // Ajustar mainIdx se algum upload falhou
    if (mainIdx >= finalUrls.length) mainIdx = 0;

    final updated = product.copyWith(
      imageUrls: finalUrls,
      mainImageIndex: mainIdx,
      imageUrl: finalUrls.isNotEmpty ? finalUrls[mainIdx] : null,
    );
    final success = await _repository.update(updated);

    if (success) {
      if (stock > 0 && stock < 10 && context != null) {
        await DSAlertDialog.showWarning(
          context: context!,
          title: 'Estoque Baixo',
          message: 'Este produto está com estoque baixo ($stock unidades).',
        );
      }
      _update(_viewModel.copyWith(isSaving: false));
      return true;
    } else {
      _update(
        _viewModel.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao atualizar produto.',
          clearError: false,
        ),
      );
      return false;
    }
  }

  Future<bool> _saveCreate({
    required String name,
    required String sku,
    required double price,
    required int stock,
    String? description,
    required bool isActive,
  }) async {
    final product = ProductModel(
      uid: '',
      name: name,
      sku: sku,
      price: price,
      stock: stock,
      description: description,
      isActive: isActive,
      createdAt: DateTime.now(),
    );

    final productId = await _repository.create(product);
    if (productId == null) {
      _update(
        _viewModel.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao criar produto.',
          clearError: false,
        ),
      );
      return false;
    }

    // Upload de todas as imagens locais
    final finalUrls = <String>[];
    int mainIdx = 0;

    for (var i = 0; i < _viewModel.images.length; i++) {
      final item = _viewModel.images[i];
      if (item.isMain) mainIdx = i;

      if (item.isLocal) {
        final url = await _repository.uploadImage(
          productId: productId,
          imageBytes: item.bytes!,
          fileName: item.fileName!,
        );
        if (url != null) finalUrls.add(url);
      }
    }

    if (finalUrls.isNotEmpty) {
      if (mainIdx >= finalUrls.length) mainIdx = 0;
      await _repository.update(
        product.copyWith(
          uid: productId,
          imageUrls: finalUrls,
          mainImageIndex: mainIdx,
          imageUrl: finalUrls[mainIdx],
        ),
      );
    }

    if (stock > 0 && stock < 10 && context != null) {
      await DSAlertDialog.showWarning(
        context: context!,
        title: 'Estoque Baixo',
        message: 'Este produto está com estoque baixo ($stock unidades).',
      );
    }

    _update(_viewModel.copyWith(isSaving: false));
    return true;
  }

  // MARK: - Private

  void _update(ProductFormViewModel viewModel) {
    _viewModel = viewModel;
    onViewModelUpdated(viewModel);
  }
}
