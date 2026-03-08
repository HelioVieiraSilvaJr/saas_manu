import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'DashboardTenantPresenter.dart';
import 'DashboardTenantViewModel.dart';
import 'Web/DashboardTenantWebView.dart';
import 'Mobile/DashboardTenantMobileView.dart';

/// Dashboard Tenant - Módulo 2.
///
/// Métricas, gráfico de vendas, vendas recentes, ações rápidas e alertas.
class DashboardTenantPage extends StatefulWidget {
  const DashboardTenantPage({super.key});

  @override
  State<DashboardTenantPage> createState() => _DashboardTenantPageState();
}

class _DashboardTenantPageState extends State<DashboardTenantPage> {
  late final DashboardTenantPresenter _presenter;
  DashboardTenantViewModel _viewModel = const DashboardTenantViewModel();

  @override
  void initState() {
    super.initState();
    _presenter = DashboardTenantPresenter(
      onViewModelUpdated: (viewModel) {
        if (mounted) {
          setState(() => _viewModel = viewModel);
        }
      },
    );
    _presenter.context = context;
    _presenter.loadDashboard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presenter.context = context;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/dashboard',
      child: ScreenResponsive(
        mobile: DashboardTenantMobileView(
          presenter: _presenter,
          viewModel: _viewModel,
        ),
        web: DashboardTenantWebView(
          presenter: _presenter,
          viewModel: _viewModel,
        ),
      ),
    );
  }
}
