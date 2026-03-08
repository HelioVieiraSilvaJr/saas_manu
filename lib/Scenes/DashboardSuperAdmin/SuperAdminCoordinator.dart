import 'package:flutter/material.dart';
import '../../Commons/Models/TenantModel.dart';

/// Coordinator de navegação do módulo SuperAdmin.
class SuperAdminCoordinator {
  final BuildContext context;

  SuperAdminCoordinator(this.context);

  void navigateToDashboard() {
    Navigator.pushNamed(context, '/admin/dashboard');
  }

  void navigateToTenants() {
    Navigator.pushNamed(context, '/admin/tenants');
  }

  void navigateToTenantDetail(TenantModel tenant) {
    Navigator.pushNamed(context, '/admin/tenants/detail', arguments: tenant);
  }

  void navigateBack([dynamic result]) {
    Navigator.pop(context, result);
  }
}
