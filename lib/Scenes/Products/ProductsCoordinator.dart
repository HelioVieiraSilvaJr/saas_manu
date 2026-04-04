import 'package:flutter/material.dart';
import '../../Commons/Models/ProductModel.dart';

class ProductFormRouteArgs {
  final String? productId;
  final ProductModel? duplicateFrom;

  const ProductFormRouteArgs._({this.productId, this.duplicateFrom});

  const ProductFormRouteArgs.edit(String productId)
    : this._(productId: productId);

  const ProductFormRouteArgs.duplicate(ProductModel product)
    : this._(duplicateFrom: product);

  bool get isEdit => productId != null && productId!.isNotEmpty;
  bool get isDuplicate => duplicateFrom != null;
}

/// Coordinator de navegação para Produtos.
class ProductsCoordinator {
  /// Navega para a lista de produtos.
  static Future<dynamic> navigateToList(BuildContext context) {
    return Navigator.pushNamed(context, '/products');
  }

  /// Navega para criar novo produto.
  static Future<dynamic> navigateToCreate(
    BuildContext context, {
    ProductModel? duplicateFrom,
  }) {
    return Navigator.pushNamed(
      context,
      '/products/new',
      arguments: duplicateFrom != null
          ? ProductFormRouteArgs.duplicate(duplicateFrom)
          : null,
    );
  }

  /// Navega para editar produto.
  static Future<dynamic> navigateToEdit(
    BuildContext context,
    ProductModel product,
  ) {
    return Navigator.pushNamed(
      context,
      '/products/edit',
      arguments: ProductFormRouteArgs.edit(product.uid),
    );
  }

  /// Navega para detalhes do produto (redireciona para edição).
  static Future<dynamic> navigateToDetail(
    BuildContext context,
    ProductModel product,
  ) {
    return navigateToEdit(context, product);
  }

  /// Voltar.
  static void navigateBack(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }
}
