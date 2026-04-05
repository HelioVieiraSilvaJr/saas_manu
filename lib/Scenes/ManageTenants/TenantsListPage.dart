import 'package:flutter/material.dart';
import '../../Commons/Utils/ScreenResponsive.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Sources/Coordinators/AppShell.dart';
import 'TenantsListPresenter.dart';
import 'Web/TenantsListWebView.dart';
import 'Mobile/TenantsListMobileView.dart';

/// Página de listagem de Tenants — Módulo 7 (SuperAdmin).
class TenantsListPage extends StatefulWidget {
  const TenantsListPage({super.key});

  @override
  State<TenantsListPage> createState() => _TenantsListPageState();
}

class _TenantsListPageState extends State<TenantsListPage> {
  final _presenter = TenantsListPresenter();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter.onUpdate = () {
      if (mounted) setState(() {});
    };
    _presenter.loadTenants();
  }

  @override
  void dispose() {
    _presenter.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onCreateTenant() {
    Navigator.pushNamed(context, '/admin/tenants/new').then((_) {
      _presenter.loadTenants();
    });
  }

  void _onTapTenant(String tenantId) {
    Navigator.pushNamed(
      context,
      '/admin/tenants/detail',
      arguments: tenantId,
    ).then((_) {
      _presenter.loadTenants();
    });
  }

  void _onEditTenant(String tenantId) {
    Navigator.pushNamed(
      context,
      '/admin/tenants/edit',
      arguments: tenantId,
    ).then((_) {
      _presenter.loadTenants();
    });
  }

  Future<void> _onDeleteTenant(String tenantId) async {
    final tenant = _presenter.viewModel.allTenants
        .where((t) => t.uid == tenantId)
        .firstOrNull;
    if (tenant == null) return;

    // Primeira confirmação
    final confirmed = await DSAlertDialog.showDelete(
      context: context,
      title: 'Excluir Tenant',
      message:
          'Tem certeza que deseja excluir "${tenant.name}"? '
          'Todos os dados (produtos, clientes, vendas) serão removidos permanentemente.',
    );
    if (confirmed == true && mounted) {
      // Segunda confirmação: digitar o nome
      _showNameConfirmation(tenantId, tenant.name);
    }
  }

  void _showNameConfirmation(String tenantId, String tenantName) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digite o nome do tenant para confirmar:',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tenantName,
              style: Theme.of(
                ctx,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Nome do tenant',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim() == tenantName) {
                Navigator.pop(ctx);
                _showDeleteProgress(tenantName);
                final success = await _presenter.deleteTenant(tenantId);
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (success) {
                    await DSAlertDialog.showSuccess(
                      context: context,
                      title: 'Tenant excluído',
                      message: '"$tenantName" foi removido com sucesso.',
                    );
                  } else {
                    await DSAlertDialog.showError(
                      context: context,
                      title: 'Falha ao excluir',
                      message:
                          'Não foi possível excluir "$tenantName". Tente novamente.',
                    );
                  }
                }
              }
            },
            child: Text('Excluir', style: TextStyle(color: DSColors().red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteProgress(String tenantName) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: colors.primaryColor),
              ),
              const SizedBox(height: DSSpacing.lg),
              Text(
                'Excluindo tenant',
                style: textStyles.labelLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DSSpacing.xs),
              Text(
                'Removendo "$tenantName" e seus dados relacionados.',
                style: textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/admin/tenants',
      child: ScreenResponsive(
        web: TenantsListWebView(
          presenter: _presenter,
          viewModel: _presenter.viewModel,
          searchController: _searchController,
          onTapTenant: _onTapTenant,
          onEditTenant: _onEditTenant,
          onDeleteTenant: _onDeleteTenant,
          onCreateTenant: _onCreateTenant,
        ),
        mobile: TenantsListMobileView(
          presenter: _presenter,
          viewModel: _presenter.viewModel,
          searchController: _searchController,
          onTapTenant: _onTapTenant,
          onEditTenant: _onEditTenant,
          onDeleteTenant: _onDeleteTenant,
          onCreateTenant: _onCreateTenant,
        ),
      ),
    );
  }
}
