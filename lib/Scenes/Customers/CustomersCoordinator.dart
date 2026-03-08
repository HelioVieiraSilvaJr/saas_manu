import 'package:flutter/material.dart';
import '../../Commons/Models/CustomerModel.dart';

/// Coordinator de navegação para Clientes.
class CustomersCoordinator {
  /// Navega para a lista de clientes.
  static void navigateToList(BuildContext context) {
    Navigator.pushNamed(context, '/customers');
  }

  /// Navega para criar novo cliente.
  static void navigateToCreate(BuildContext context) {
    Navigator.pushNamed(context, '/customers/new');
  }

  /// Navega para editar cliente.
  static void navigateToEdit(BuildContext context, CustomerModel customer) {
    Navigator.pushNamed(context, '/customers/edit', arguments: customer.uid);
  }

  /// Navega para detalhes do cliente.
  static void navigateToDetail(BuildContext context, CustomerModel customer) {
    Navigator.pushNamed(context, '/customers/detail', arguments: customer);
  }

  /// Voltar.
  static void navigateBack(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }
}
