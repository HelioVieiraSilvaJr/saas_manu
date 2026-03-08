import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Sources/Coordinators/AppShell.dart';
import '../../Sources/SessionManager.dart';
import 'TeamManagementPresenter.dart';
import 'Web/TeamManagementWebView.dart';
import 'Mobile/TeamManagementMobileView.dart';

/// Página de Gerenciar Equipe — Módulo 9.
///
/// Guard: somente usuários com `canManageTenant()` podem acessar.
class TeamManagementPage extends StatefulWidget {
  const TeamManagementPage({super.key});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  final _presenter = TeamManagementPresenter();

  @override
  void initState() {
    super.initState();
    _presenter.onUpdate = () {
      if (mounted) setState(() {});
    };
    _presenter.loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    // Guard — somente quem pode gerenciar o tenant
    if (!SessionManager.instance.canManageTenant()) {
      return AppShell(
        currentRoute: '/team',
        child: const Center(child: Text('Acesso não autorizado.')),
      );
    }

    return AppShell(
      currentRoute: '/team',
      child: ScreenResponsive(
        mobile: TeamManagementMobileView(
          presenter: _presenter,
          viewModel: _presenter.viewModel,
        ),
        web: TeamManagementWebView(
          presenter: _presenter,
          viewModel: _presenter.viewModel,
        ),
      ),
    );
  }
}
