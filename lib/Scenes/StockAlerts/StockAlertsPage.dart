import 'dart:async';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'StockAlertsPresenter.dart';
import 'StockAlertsViewModel.dart';
import 'Mobile/StockAlertsMobileView.dart';
import 'Web/StockAlertsWebView.dart';

/// Página de avisos de estoque (real-time).
class StockAlertsPage extends StatefulWidget {
  const StockAlertsPage({super.key});

  @override
  State<StockAlertsPage> createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage> {
  final _presenter = StockAlertsPresenter();
  final _searchController = TextEditingController();
  bool _didApplyRouteFilter = false;

  @override
  void initState() {
    super.initState();
    _presenter.onUpdate = () => setState(() {});
    _presenter.startWatchingPending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _presenter.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyRouteFilter) return;
    _didApplyRouteFilter = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final productId = args['productId'] as String?;
      final productName = args['productName'] as String?;
      if (productId != null && productId.isNotEmpty) {
        _presenter.setProductFilter(productId, productName: productName);
      }
    }
  }

  Future<void> _handleDismiss(String productId) async {
    final confirm = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Encerrar Avisos',
      message:
          'Deseja encerrar todos os avisos pendentes deste produto? Os clientes não serão notificados.',
    );

    if (confirm != true || !mounted) return;

    final success = await _presenter.dismissGroup(productId);
    if (success && mounted) {
      ElegantNotification.success(
        title: const Text('Avisos Encerrados'),
        description: const Text('Os avisos do produto foram encerrados.'),
      ).show(context);
    } else if (!success && mounted) {
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro',
        message: 'Não foi possível encerrar o aviso.',
      );
    }
  }

  Future<void> _handleNotify(String productId) async {
    final confirm = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Notificar Clientes',
      message:
          'Confirma o disparo das notificações de reposição para todos os clientes deste produto?',
    );

    if (confirm != true || !mounted) return;

    final result = await _presenter.notifyGroup(productId);
    if ((result['ok'] == true) && mounted) {
      final notifiedCount = result['notifiedCount'] ?? 0;
      final failedCount = result['failedCount'] ?? 0;
      ElegantNotification.success(
        title: const Text('Notificações Disparadas'),
        description: Text(
          '$notifiedCount clientes notificados${failedCount > 0 ? ' • $failedCount falhas' : ''}.',
        ),
      ).show(context);
    } else if (mounted) {
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro',
        message: 'Não foi possível disparar as notificações de reposição.',
      );
    }
  }

  void _handleTabChange(StockAlertTab tab) {
    _presenter.setTab(tab);
  }

  void _clearProductFilter() {
    _presenter.setProductFilter(null);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/stock-alerts',
      child: ScreenResponsive(
        web: StockAlertsWebView(
          presenter: _presenter,
          searchController: _searchController,
          onDismiss: _handleDismiss,
          onNotify: _handleNotify,
          onTabChange: _handleTabChange,
          onClearProductFilter: _clearProductFilter,
        ),
        mobile: StockAlertsMobileView(
          presenter: _presenter,
          searchController: _searchController,
          onDismiss: _handleDismiss,
          onNotify: _handleNotify,
          onTabChange: _handleTabChange,
          onClearProductFilter: _clearProductFilter,
        ),
      ),
    );
  }
}
