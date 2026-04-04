import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'CustomersListPresenter.dart';
import 'CustomersListViewModel.dart';
import 'Web/CustomersListWebView.dart';
import 'Mobile/CustomersListMobileView.dart';

/// Página de listagem de clientes - Módulo 4.
///
/// Lista/cards com busca, filtros, ordenação e CRUD.
class CustomersListPage extends StatefulWidget {
  const CustomersListPage({super.key});

  @override
  State<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends State<CustomersListPage> {
  late final CustomersListPresenter _presenter;
  CustomersListViewModel _viewModel = const CustomersListViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter = CustomersListPresenter(
      onViewModelUpdated: (viewModel) {
        if (mounted) {
          setState(() => _viewModel = viewModel);
        }
      },
    );
    _presenter.context = context;
    _presenter.loadCustomers();
    _presenter.watchCustomers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presenter.context = context;
  }

  @override
  void dispose() {
    _presenter.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/customers',
      child: ScreenResponsive(
        mobile: CustomersListMobileView(
          presenter: _presenter,
          viewModel: _viewModel,
          searchController: _searchController,
        ),
        web: CustomersListWebView(
          presenter: _presenter,
          viewModel: _viewModel,
          searchController: _searchController,
        ),
      ),
    );
  }
}
