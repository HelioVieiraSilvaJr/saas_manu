import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Sources/Coordinators/AppShell.dart';
import '../../Sources/SessionManager.dart';
import 'TenantSettingsPresenter.dart';
import 'Web/TenantSettingsWebView.dart';
import 'Mobile/TenantSettingsMobileView.dart';

/// Página de Configurações do Tenant — Módulo 8.
///
/// Guard: somente usuários com `canManageTenant()` podem acessar.
/// Exibe 3 seções: Dados da Empresa, Integrações, Plano & Assinatura.
class TenantSettingsPage extends StatefulWidget {
  const TenantSettingsPage({super.key});

  @override
  State<TenantSettingsPage> createState() => _TenantSettingsPageState();
}

class _TenantSettingsPageState extends State<TenantSettingsPage> {
  final _presenter = TenantSettingsPresenter();
  final _companyFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _presenter.onUpdate = () {
      if (mounted) {
        setState(() {});

        // Notificação de sucesso
        if (_presenter.viewModel.successMessage != null) {
          ElegantNotification.success(
            title: const Text('Sucesso'),
            description: Text(_presenter.viewModel.successMessage!),
          ).show(context);
          _presenter.viewModel = _presenter.viewModel.copyWith(
            successMessage: null,
          );
        }

        // Notificação de erro
        if (_presenter.viewModel.errorMessage != null) {
          ElegantNotification.error(
            title: const Text('Erro'),
            description: Text(_presenter.viewModel.errorMessage!),
          ).show(context);
          _presenter.viewModel = _presenter.viewModel.copyWith(
            errorMessage: null,
          );
        }
      }
    };
    _presenter.loadSettings();
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Guard — somente quem pode gerenciar o tenant
    if (!SessionManager.instance.canManageTenant()) {
      return AppShell(
        currentRoute: '/settings',
        child: const Center(child: Text('Acesso não autorizado.')),
      );
    }

    return AppShell(
      currentRoute: '/settings',
      child: ScreenResponsive(
        mobile: TenantSettingsMobileView(
          presenter: _presenter,
          viewModel: _presenter.viewModel,
          companyFormKey: _companyFormKey,
        ),
        web: TenantSettingsWebView(
          presenter: _presenter,
          viewModel: _presenter.viewModel,
          companyFormKey: _companyFormKey,
        ),
      ),
    );
  }
}
