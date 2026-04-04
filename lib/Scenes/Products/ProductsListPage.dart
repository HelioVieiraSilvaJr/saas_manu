import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'ProductsListPresenter.dart';
import 'ProductsListViewModel.dart';
import 'Web/ProductsListWebView.dart';
import 'Mobile/ProductsListMobileView.dart';

/// Página de listagem de produtos - Módulo 3.
///
/// Grid de produtos com busca, filtros, ordenação e CRUD.
class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  late final ProductsListPresenter _presenter;
  ProductsListViewModel _viewModel = const ProductsListViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter = ProductsListPresenter(
      onViewModelUpdated: (viewModel) {
        if (mounted) {
          setState(() => _viewModel = viewModel);
        }
      },
    );
    _presenter.context = context;
    _presenter.loadProducts();
    _presenter.watchProducts();
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
      currentRoute: '/products',
      child: ScreenResponsive(
        mobile: ProductsListMobileView(
          presenter: _presenter,
          viewModel: _viewModel,
          searchController: _searchController,
        ),
        web: ProductsListWebView(
          presenter: _presenter,
          viewModel: _viewModel,
          searchController: _searchController,
        ),
      ),
    );
  }
}
