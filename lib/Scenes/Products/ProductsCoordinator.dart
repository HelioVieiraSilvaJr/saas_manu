import 'package:flutter/material.dart';
import '../../Commons/Models/ProductModel.dart';

/// Coordinator de navegação para Produtos.
class ProductsCoordinator {
  /// Navega para a lista de produtos.
  static Future<dynamic> navigateToList(BuildContext context) {
    return Navigator.pushNamed(context, '/products');
  }

  /// Navega para criar novo produto.
  static Future<dynamic> navigateToCreate(BuildContext context) {
    return Navigator.pushNamed(context, '/products/new');
  }

  /// Navega para editar produto.
  static Future<dynamic> navigateToEdit(
    BuildContext context,
    ProductModel product,
  ) {
    return Navigator.pushNamed(
      context,
      '/products/edit',
      arguments: product.uid,
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
