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

  Future<void> _handleDismiss(String alertId) async {
    final confirm = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Encerrar Aviso',
      message:
          'Deseja encerrar este aviso de estoque? O cliente não será notificado.',
    );

    if (confirm != true || !mounted) return;

    final success = await _presenter.dismissAlert(alertId);
    if (success && mounted) {
      ElegantNotification.success(
        title: const Text('Aviso Encerrado'),
        description: const Text('O aviso foi encerrado com sucesso.'),
      ).show(context);
    } else if (!success && mounted) {
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro',
        message: 'Não foi possível encerrar o aviso.',
      );
    }
  }

  Future<void> _handleNotified(String alertId) async {
    final confirm = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Marcar como Notificado',
      message:
          'Confirma que o cliente foi notificado sobre a reposição do estoque?',
    );

    if (confirm != true || !mounted) return;

    final success = await _presenter.markNotified(alertId);
    if (success && mounted) {
      ElegantNotification.success(
        title: const Text('Cliente Notificado'),
        description: const Text(
          'O aviso foi marcado como notificado com sucesso.',
        ),
      ).show(context);
    } else if (!success && mounted) {
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro',
        message: 'Não foi possível atualizar o aviso.',
      );
    }
  }

  void _handleTabChange(StockAlertTab tab) {
    _presenter.setTab(tab);
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
          onNotified: _handleNotified,
          onTabChange: _handleTabChange,
        ),
        mobile: StockAlertsMobileView(
          presenter: _presenter,
          searchController: _searchController,
          onDismiss: _handleDismiss,
          onNotified: _handleNotified,
          onTabChange: _handleTabChange,
        ),
      ),
    );
  }
}
