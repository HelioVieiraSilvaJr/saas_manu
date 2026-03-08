import 'package:flutter/material.dart';
import '../../Commons/Models/ProductModel.dart';

/// Coordinator de navegação para Produtos.
class ProductsCoordinator {
  /// Navega para a lista de produtos.
  static void navigateToList(BuildContext context) {
    Navigator.pushNamed(context, '/products');
  }

  /// Navega para criar novo produto.
  static void navigateToCreate(BuildContext context) {
    Navigator.pushNamed(context, '/products/new');
  }

  /// Navega para editar produto.
  static void navigateToEdit(BuildContext context, ProductModel product) {
    Navigator.pushNamed(context, '/products/edit', arguments: product.uid);
  }

  /// Navega para detalhes do produto.
  static void navigateToDetail(BuildContext context, ProductModel product) {
    Navigator.pushNamed(context, '/products/detail', arguments: product);
  }

  /// Voltar.
  static void navigateBack(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }
}
