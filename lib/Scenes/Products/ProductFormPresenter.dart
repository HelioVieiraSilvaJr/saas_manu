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
  void initForCreate({ProductModel? duplicateFrom}) {
    final product = duplicateFrom != null
        ? duplicateFrom.copyWith(
            uid: '',
            sku: '',
            createdAt: DateTime.now(),
            updatedAt: null,
          )
        : ProductModel.newModel();
    final existingImages = duplicateFrom != null
        ? duplicateFrom.imageUrls.asMap().entries.map((entry) {
            return ProductImageItem(
              url: entry.value,
              isMain: entry.key == duplicateFrom.mainImageIndex,
            );
          }).toList()
        : const <ProductImageItem>[];

    _update(
      _viewModel.copyWith(
        product: product,
        isEditing: false,
        images: existingImages,
        removedImageUrls: const [],
      ),
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
    String? category,
    String? color,
    String? size,
    List<String> tags = const [],
    String? description,
    String? aiInstructions,
    required bool isActive,
  }) async {
    if (context == null) return false;

    _update(_viewModel.copyWith(isSaving: true));

    try {
      final resolvedSku = _resolveSku(
        requestedSku: sku,
        name: name,
        category: category,
        color: color,
        size: size,
      );

      // Validar SKU único
      final skuExists = await _repository.skuExists(
        resolvedSku,
        excludeId: _viewModel.isEditing ? _viewModel.product?.uid : null,
      );

      if (skuExists) {
        final duplicateMessage = sku.trim().isEmpty
            ? 'O SKU gerado automaticamente "$resolvedSku" já existe. Ajuste nome, categoria, cor, tamanho ou informe um SKU diferente.'
            : 'O SKU "$resolvedSku" já existe. Informe um valor diferente.';
        await DSAlertDialog.showError(
          context: context!,
          title: 'SKU já cadastrado',
          message: duplicateMessage,
        );
        _update(
          _viewModel.copyWith(
            isSaving: false,
            errorMessage: duplicateMessage,
            clearError: false,
          ),
        );
        return false;
      }

      if (_viewModel.isEditing) {
        return await _saveEdit(
          name: name,
          sku: resolvedSku,
          price: price,
          stock: stock,
          category: category,
          color: color,
          size: size,
          tags: tags,
          description: description,
          aiInstructions: aiInstructions,
          isActive: isActive,
        );
      } else {
        return await _saveCreate(
          name: name,
          sku: resolvedSku,
          price: price,
          stock: stock,
          category: category,
          color: color,
          size: size,
          tags: tags,
          description: description,
          aiInstructions: aiInstructions,
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
    String? category,
    String? color,
    String? size,
    required List<String> tags,
    String? description,
    String? aiInstructions,
    required bool isActive,
  }) async {
    final product = _viewModel.product!.copyWith(
      name: name,
      sku: sku,
      price: price,
      stock: stock,
      category: category,
      color: color,
      size: size,
      tags: tags,
      description: description,
      aiInstructions: aiInstructions,
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
    String? category,
    String? color,
    String? size,
    required List<String> tags,
    String? description,
    String? aiInstructions,
    required bool isActive,
  }) async {
    final product = ProductModel(
      uid: '',
      name: name,
      sku: sku,
      price: price,
      stock: stock,
      category: category,
      color: color,
      size: size,
      tags: tags,
      description: description,
      aiInstructions: aiInstructions,
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

      if (item.isRemote) {
        finalUrls.add(item.url!);
      } else if (item.isLocal) {
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

  Future<bool> deleteProduct(ProductModel product) async {
    if (context == null) return false;

    final hasSales = await _repository.productHasSales(product.uid);

    if (hasSales) {
      final confirm = await DSAlertDialog.showWarning(
        context: context!,
        title: 'Produto com Vendas',
        message:
            'Este produto possui vendas registradas e será inativado, sem perder o histórico.',
        confirmLabel: 'Inativar produto',
      );

      if (confirm != true) return false;

      final success = await _repository.update(
        product.copyWith(isActive: false),
      );
      if (success) {
        await DSAlertDialog.showSuccess(
          context: context!,
          title: 'Produto Inativado',
          message: '${product.name} foi inativado com sucesso.',
        );
      }
      return success;
    }

    final confirm = await DSAlertDialog.showDelete(
      context: context!,
      title: 'Excluir produto',
      message: 'Este produto será removido permanentemente.',
      content: DSAlertContentCard(
        icon: Icons.shopping_bag_outlined,
        title: product.name,
        subtitle: 'SKU: ${product.sku}',
      ),
    );

    if (confirm != true) return false;

    if (product.imageUrls.isNotEmpty) {
      await _repository.deleteImages(product.imageUrls);
    }

    final success = await _repository.delete(product.uid);
    if (success) {
      await DSAlertDialog.showSuccess(
        context: context!,
        title: 'Produto Excluído',
        message: '${product.name} foi removido permanentemente.',
      );
    }
    return success;
  }

  // MARK: - Private

  void _update(ProductFormViewModel viewModel) {
    _viewModel = viewModel;
    onViewModelUpdated(viewModel);
  }

  String _resolveSku({
    required String requestedSku,
    required String name,
    String? category,
    String? color,
    String? size,
  }) {
    final trimmed = requestedSku.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return _generateSku(
      name: name,
      category: category,
      color: color,
      size: size,
    );
  }

  String _generateSku({
    required String name,
    String? category,
    String? color,
    String? size,
  }) {
    final parts = [
      name,
      category,
      color,
      size,
    ].map(_slugifyPart).where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return 'produto';
    return parts.join('-');
  }

  String _slugifyPart(String? value) {
    if (value == null) return '';
    final normalized = value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[àáâãä]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return normalized;
  }
}
