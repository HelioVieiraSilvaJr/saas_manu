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
  Uint8List? _pendingImageBytes;
  String? _pendingImageFileName;

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
      _update(
        _viewModel.copyWith(
          isLoading: false,
          product: product,
          imagePreviewUrl: product.imageUrl,
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

  /// Define a imagem selecionada (preview).
  void setImage(Uint8List bytes, String fileName) {
    _pendingImageBytes = bytes;
    _pendingImageFileName = fileName;
    _update(_viewModel.copyWith(hasImageChanged: true));
  }

  /// Remove a imagem.
  void removeImage() {
    _pendingImageBytes = null;
    _pendingImageFileName = null;
    _update(_viewModel.copyWith(hasImageChanged: true, imagePreviewUrl: null));
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

      String? imageUrl = _viewModel.product?.imageUrl;

      if (_viewModel.isEditing) {
        // EDITAR
        final product = _viewModel.product!.copyWith(
          name: name,
          sku: sku,
          price: price,
          stock: stock,
          description: description,
          isActive: isActive,
          updatedAt: DateTime.now(),
        );

        // Upload de imagem se mudou
        if (_viewModel.hasImageChanged) {
          // Remover imagem antiga
          if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
            await _repository.deleteImage(product.imageUrl!);
          }

          // Upload nova imagem
          if (_pendingImageBytes != null && _pendingImageFileName != null) {
            imageUrl = await _repository.uploadImage(
              productId: product.uid,
              imageBytes: _pendingImageBytes!,
              fileName: _pendingImageFileName!,
            );
          } else {
            imageUrl = null;
          }
        }

        final updated = product.copyWith(imageUrl: imageUrl);
        final success = await _repository.update(updated);

        if (success) {
          // Alerta estoque baixo
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
      } else {
        // CRIAR
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

        if (productId != null) {
          // Upload de imagem
          if (_pendingImageBytes != null && _pendingImageFileName != null) {
            imageUrl = await _repository.uploadImage(
              productId: productId,
              imageBytes: _pendingImageBytes!,
              fileName: _pendingImageFileName!,
            );

            if (imageUrl != null) {
              await _repository.update(
                product.copyWith(uid: productId, imageUrl: imageUrl),
              );
            }
          }

          // Alerta estoque baixo
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
              errorMessage: 'Erro ao criar produto.',
              clearError: false,
            ),
          );
          return false;
        }
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

  // MARK: - Private

  void _update(ProductFormViewModel viewModel) {
    _viewModel = viewModel;
    onViewModelUpdated(viewModel);
  }
}
