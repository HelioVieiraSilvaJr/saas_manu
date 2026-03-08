import 'package:flutter/material.dart';
import '../../Commons/Models/SaleModel.dart';

/// Coordinator de navegação do módulo de Vendas.
class SalesCoordinator {
  final BuildContext context;

  SalesCoordinator(this.context);

  void navigateToList() {
    Navigator.pushNamed(context, '/sales');
  }

  Future<bool?> navigateToCreate() {
    return Navigator.pushNamed<bool>(context, '/sales/new');
  }

  void navigateToDetail(SaleModel sale) {
    Navigator.pushNamed(context, '/sales/detail', arguments: sale);
  }

  void navigateBack([dynamic result]) {
    Navigator.pop(context, result);
  }
}
