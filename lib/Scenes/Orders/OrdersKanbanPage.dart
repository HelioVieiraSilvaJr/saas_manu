import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'OrdersKanbanPresenter.dart';
import 'Web/OrdersKanbanWebView.dart';
import 'Mobile/OrdersKanbanMobileView.dart';

/// Página do Kanban de Pedidos.
///
/// Exibe pedidos com pagamento confirmado em uma esteira de processamento:
/// Separando → Embalando → Pronto → Concluído
class OrdersKanbanPage extends StatefulWidget {
  const OrdersKanbanPage({super.key});

  @override
  State<OrdersKanbanPage> createState() => _OrdersKanbanPageState();
}

class _OrdersKanbanPageState extends State<OrdersKanbanPage> {
  final _presenter = OrdersKanbanPresenter();

  @override
  void initState() {
    super.initState();
    _presenter.onUpdate = () => setState(() {});
    _presenter.loadOrders();
    _presenter.watchOrders();
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  void _handleViewDetails(String saleId) {
    final order = _presenter.viewModel.allOrders
        .where((o) => o.uid == saleId)
        .firstOrNull;
    if (order != null) {
      Navigator.pushNamed(context, '/sales/detail', arguments: order);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/orders',
      child: ScreenResponsive(
        web: OrdersKanbanWebView(
          presenter: _presenter,
          onViewDetails: _handleViewDetails,
        ),
        mobile: OrdersKanbanMobileView(
          presenter: _presenter,
          onViewDetails: _handleViewDetails,
          onRefresh: () => _presenter.loadOrders(),
        ),
      ),
    );
  }
}
