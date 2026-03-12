import 'dart:async';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import '../../Commons/Models/SaleModel.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'Mobile/SalesListMobileView.dart';
import 'SalesCoordinator.dart';
import 'SalesListPresenter.dart';
import 'Web/SalesListWebView.dart';
import '../Products/ProductsRepository.dart';
import '../Customers/CustomersRepository.dart';

/// Página de listagem de vendas.
class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key});

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  final _presenter = SalesListPresenter();
  final _searchController = TextEditingController();
  late final SalesCoordinator _coordinator;
  final _productsRepository = ProductsRepository();
  final _customersRepository = CustomersRepository();
  StreamSubscription<List<SaleModel>>? _automatedSalesSubscription;

  @override
  void initState() {
    super.initState();
    _coordinator = SalesCoordinator(context);
    _presenter.onUpdate = () => setState(() {});
    _presenter.loadSales();
    _setupAutomatedSalesListener();
  }

  void _setupAutomatedSalesListener() {
    _automatedSalesSubscription = _presenter.watchNewAutomatedSales().listen((
      newSales,
    ) {
      if (newSales.isNotEmpty && mounted) {
        ElegantNotification.success(
          title: const Text('Nova Venda!'),
          description: Text(
            '${newSales.length} nova(s) venda(s) automática(s).',
          ),
        ).show(context);
        _presenter.loadSales();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _presenter.dispose();
    _automatedSalesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleDeleteSale(String saleId) async {
    final sale = _presenter.viewModel.allSales
        .where((s) => s.uid == saleId)
        .firstOrNull;

    if (sale == null) return;

    final confirm = await DSAlertDialog.showDelete(
      context: context,
      title: 'Confirmar Exclusão',
      message: 'Tem certeza que deseja excluir esta venda?',
    );

    if (confirm != true || !mounted) return;

    for (var item in sale.items) {
      await _productsRepository.incrementStock(item.productId, item.quantity);
    }

    await _customersRepository.decrementPurchaseStats(
      sale.customerId,
      sale.total,
    );

    final success = await _presenter.deleteSale(saleId);

    if (success && mounted) {
      await DSAlertDialog.showSuccess(
        context: context,
        title: 'Venda Excluída',
        message: 'A venda foi excluída e o estoque atualizado.',
      );
    }
  }

  Future<void> _handleSendPaymentRequest(String saleId) async {
    final confirm = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Enviar Cobrança',
      message: 'Enviar solicitação de pagamento ao cliente via WhatsApp?',
      confirmLabel: 'Enviar',
    );

    if (confirm != true || !mounted) return;

    final success = await _presenter.sendPaymentRequest(saleId);

    if (success && mounted) {
      ElegantNotification.success(
        title: const Text('Cobrança Enviada'),
        description: const Text('Solicitação de pagamento enviada.'),
      ).show(context);
    }
  }

  Future<void> _handleConfirmPayment(String saleId) async {
    final confirm = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Confirmar Pagamento',
      message:
          'Confirmar o recebimento do pagamento? O pedido entrará na esteira de processamento.',
      confirmLabel: 'Confirmar',
    );

    if (confirm != true || !mounted) return;

    final success = await _presenter.confirmPayment(saleId);

    if (success && mounted) {
      ElegantNotification.success(
        title: const Text('Pagamento Confirmado'),
        description: const Text(
          'Pedido adicionado à esteira de processamento.',
        ),
      ).show(context);
    }
  }

  Future<void> _handleCancelSale(String saleId) async {
    final confirm = await DSAlertDialog.showDelete(
      context: context,
      title: 'Cancelar Venda',
      message: 'Tem certeza que deseja cancelar esta venda?',
      confirmLabel: 'Cancelar Venda',
    );

    if (confirm != true || !mounted) return;

    final sale = _presenter.viewModel.allSales
        .where((s) => s.uid == saleId)
        .firstOrNull;

    if (sale != null) {
      for (var item in sale.items) {
        await _productsRepository.incrementStock(item.productId, item.quantity);
      }
      await _customersRepository.decrementPurchaseStats(
        sale.customerId,
        sale.total,
      );
    }

    final success = await _presenter.cancelSale(saleId);

    if (success && mounted) {
      ElegantNotification.success(
        title: const Text('Venda Cancelada'),
        description: const Text('Venda cancelada e estoque devolvido.'),
      ).show(context);
    }
  }

  void _handleViewDetails(String saleId) {
    final sale = _presenter.viewModel.allSales
        .where((s) => s.uid == saleId)
        .firstOrNull;
    if (sale != null) {
      _coordinator.navigateToDetail(sale);
    }
  }

  void _handleNewSale() async {
    final result = await _coordinator.navigateToCreate();
    if (result == true) {
      _presenter.loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/sales',
      child: ScreenResponsive(
        web: SalesListWebView(
          presenter: _presenter,
          searchController: _searchController,
          onNewSale: _handleNewSale,
          onViewDetails: _handleViewDetails,
          onDeleteSale: _handleDeleteSale,
          onSendPaymentRequest: _handleSendPaymentRequest,
          onConfirmPayment: _handleConfirmPayment,
          onCancelSale: _handleCancelSale,
        ),
        mobile: SalesListMobileView(
          presenter: _presenter,
          searchController: _searchController,
          onNewSale: _handleNewSale,
          onViewDetails: _handleViewDetails,
          onDeleteSale: _handleDeleteSale,
          onRefresh: () => _presenter.loadSales(),
        ),
      ),
    );
  }
}
