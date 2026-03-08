import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'SuperAdminDashboardPresenter.dart';
import 'SuperAdminDashboardViewModel.dart';
import 'Web/SuperAdminDashboardWebView.dart';
import 'Mobile/SuperAdminDashboardMobileView.dart';

/// Página do Dashboard SuperAdmin — Módulo 6.
class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  late final SuperAdminDashboardPresenter _presenter;
  SuperAdminDashboardViewModel _viewModel =
      const SuperAdminDashboardViewModel();

  @override
  void initState() {
    super.initState();
    _presenter = SuperAdminDashboardPresenter(
      onViewModelUpdated: (vm) {
        if (mounted) setState(() => _viewModel = vm);
      },
    );
    _presenter.loadDashboard();
  }

  void _navigateToTenants() {
    Navigator.pushNamed(context, '/admin/tenants');
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/admin/dashboard',
      child: ScreenResponsive(
        web: SuperAdminDashboardWebView(
          presenter: _presenter,
          viewModel: _viewModel,
          onNavigateToTenants: _navigateToTenants,
        ),
        mobile: SuperAdminDashboardMobileView(
          presenter: _presenter,
          viewModel: _viewModel,
          onNavigateToTenants: _navigateToTenants,
        ),
      ),
    );
  }
}
