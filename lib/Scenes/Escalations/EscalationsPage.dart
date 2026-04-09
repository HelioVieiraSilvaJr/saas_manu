import 'dart:async';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Sources/Coordinators/AppShell.dart';
import '../../Sources/SessionManager.dart';
import 'EscalationsPresenter.dart';
import 'EscalationsViewModel.dart';
import 'Mobile/EscalationsMobileView.dart';
import 'Web/EscalationsWebView.dart';

/// Página de atendimentos escalados (real-time).
class EscalationsPage extends StatefulWidget {
  const EscalationsPage({super.key});

  @override
  State<EscalationsPage> createState() => _EscalationsPageState();
}

class _EscalationsPageState extends State<EscalationsPage> {
  final _presenter = EscalationsPresenter();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter.onUpdate = () => setState(() {});
    if (SessionManager.instance.currentTenant != null) {
      _presenter.startWatchingActive();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _presenter.dispose();
    super.dispose();
  }

  Future<void> _handleAssume(String escalationId, String customerId) async {
    final success = await _presenter.assumeEscalation(
      escalationId,
      customerId,
    );
    if (success && mounted) {
      ElegantNotification.success(
        title: const Text('Atendimento Assumido'),
        description: const Text('Você está atendendo este cliente.'),
      ).show(context);
    } else if (!success && mounted) {
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro',
        message: 'Não foi possível assumir o atendimento.',
      );
    }
  }

  Future<void> _handleComplete(String escalationId, String customerId) async {
    // Solicita notas opcionais antes de finalizar
    final notesController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Atendimento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O agente IA será reativado para este cliente.'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas do atendimento (opcional)',
                hintText: 'Descreva brevemente o que foi tratado...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final notes = notesController.text.trim().isEmpty
        ? null
        : notesController.text.trim();
    notesController.dispose();

    final success = await _presenter.completeEscalation(
      escalationId,
      customerId,
      notes: notes,
    );

    if (success && mounted) {
      ElegantNotification.success(
        title: const Text('Atendimento Finalizado'),
        description: const Text('Agente IA reativado para o cliente.'),
      ).show(context);
    } else if (!success && mounted) {
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro',
        message: 'Não foi possível finalizar o atendimento.',
      );
    }
  }

  void _handleTabChange(EscalationTab tab) {
    _presenter.setTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/escalations',
      child: ScreenResponsive(
        web: EscalationsWebView(
          presenter: _presenter,
          searchController: _searchController,
          onAssume: _handleAssume,
          onComplete: _handleComplete,
          onTabChange: _handleTabChange,
        ),
        mobile: EscalationsMobileView(
          presenter: _presenter,
          searchController: _searchController,
          onAssume: _handleAssume,
          onComplete: _handleComplete,
          onTabChange: _handleTabChange,
        ),
      ),
    );
  }
}
