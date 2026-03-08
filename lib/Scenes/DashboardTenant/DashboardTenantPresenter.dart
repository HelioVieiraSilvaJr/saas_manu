import 'package:flutter/material.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/SessionManager.dart';
import '../../Sources/PreferencesManager.dart';
import 'DashboardTenantRepository.dart';
import 'DashboardTenantViewModel.dart';

/// Presenter do Dashboard Tenant (MVP).
///
/// Contém toda a lógica de negócio para métricas, gráficos e alertas.
class DashboardTenantPresenter {
  final DashboardTenantRepository _repository = DashboardTenantRepository();
  final ValueChanged<DashboardTenantViewModel> onViewModelUpdated;

  DashboardTenantViewModel _viewModel = const DashboardTenantViewModel();
  DashboardTenantViewModel get viewModel => _viewModel;

  BuildContext? context;

  DashboardTenantPresenter({required this.onViewModelUpdated});

  // MARK: - Load Dashboard

  /// Carrega todos os dados do dashboard.
  Future<void> loadDashboard() async {
    AppLogger.info('Carregando dashboard...');
    _update(_viewModel.copyWith(isLoading: true));

    try {
      // Executar queries em paralelo para performance
      final results = await Future.wait([
        _repository.getSalesToday(),
        _repository.getSalesYesterday(),
        _repository.getSalesThisMonth(),
        _repository.getSalesLastMonthSamePeriod(),
        _repository.getTotalCustomers(),
        _repository.getNewCustomersThisMonth(),
        _repository.getSalesLast7Days(),
        _repository.getRecentSales(),
        _repository.getTotalProducts(),
        _repository.getProductsWithoutImage(),
      ]);

      final salesToday = results[0] as double;
      final salesYesterday = results[1] as double;
      final salesThisMonth = results[2] as ({double total, int count});
      final salesLastMonth = results[3] as ({double total, int count});
      final totalCustomers = results[4] as int;
      final newCustomersThisMonth = results[5] as int;
      final salesLast7Days = results[6] as List<DailySalesDTO>;
      final recentSales = results[7] as List<RecentSaleDTO>;
      final totalProducts = results[8] as int;
      final productsWithoutImage = results[9] as int;

      // Gerar alertas
      final alerts = await _generateAlerts(
        totalProducts: totalProducts,
        productsWithoutImage: productsWithoutImage,
        totalCustomers: totalCustomers,
        salesCountThisMonth: salesThisMonth.count,
      );

      _update(
        _viewModel.copyWith(
          isLoading: false,
          salesToday: salesToday,
          salesYesterday: salesYesterday,
          salesThisMonth: salesThisMonth.total,
          salesLastMonthSamePeriod: salesLastMonth.total,
          salesCountThisMonth: salesThisMonth.count,
          salesCountLastMonth: salesLastMonth.count,
          totalCustomers: totalCustomers,
          newCustomersThisMonth: newCustomersThisMonth,
          salesLast7Days: salesLast7Days,
          recentSales: recentSales,
          totalProducts: totalProducts,
          productsWithoutImage: productsWithoutImage,
          alerts: alerts,
        ),
      );

      AppLogger.info('Dashboard carregado com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao carregar dashboard', error: e);
      _update(
        _viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar dashboard. Tente novamente.',
          clearError: false,
        ),
      );
    }
  }

  // MARK: - Refresh

  /// Recarrega os dados do dashboard.
  Future<void> refresh() async {
    await loadDashboard();
  }

  // MARK: - Dismiss Alert

  /// Dispensa um alerta (não exibir por 7 dias).
  Future<void> dismissAlert(DashboardAlert alert) async {
    await PreferencesManager.instance.dismissAlert(alert.dismissKey);

    final updatedAlerts = _viewModel.alerts
        .where((a) => a.type != alert.type)
        .toList();

    _update(_viewModel.copyWith(alerts: updatedAlerts));
    AppLogger.info('Alerta dispensado: ${alert.type.name}');
  }

  // MARK: - Alert Action

  /// Navega para a rota do alerta.
  void handleAlertAction(DashboardAlert alert) {
    if (context != null) {
      Navigator.pushNamed(context!, alert.route);
    }
  }

  // MARK: - Quick Actions

  /// Navega para Nova Venda.
  void navigateToNewSale() {
    if (context != null) {
      Navigator.pushNamed(context!, '/sales/new');
    }
  }

  /// Navega para Novo Produto.
  void navigateToNewProduct() {
    if (context != null) {
      Navigator.pushNamed(context!, '/products/new');
    }
  }

  /// Navega para Novo Cliente.
  void navigateToNewCustomer() {
    if (context != null) {
      Navigator.pushNamed(context!, '/customers/new');
    }
  }

  /// Navega para ver todas as vendas.
  void navigateToAllSales() {
    if (context != null) {
      Navigator.pushNamed(context!, '/sales');
    }
  }

  // MARK: - Private

  void _update(DashboardTenantViewModel viewModel) {
    _viewModel = viewModel;
    onViewModelUpdated(viewModel);
  }

  /// Gera lista de alertas baseado nos dados, respeitando dismiss.
  Future<List<DashboardAlert>> _generateAlerts({
    required int totalProducts,
    required int productsWithoutImage,
    required int totalCustomers,
    required int salesCountThisMonth,
  }) async {
    final alerts = <DashboardAlert>[];
    final prefs = PreferencesManager.instance;
    final tenant = SessionManager.instance.currentTenant;

    // 1. Plano expirando (trial ou plano com nextPaymentDate)
    if (tenant != null) {
      final daysRemaining = tenant.trialDaysRemaining;
      if (tenant.isTrial && daysRemaining >= 0 && daysRemaining <= 7) {
        final dismissed = await prefs.isAlertDismissed('dashboard_alert_planExpiring');
        if (!dismissed) {
          alerts.add(DashboardAlert(
            type: DashboardAlertType.planExpiring,
            title: 'Seu plano ${tenant.plan.toUpperCase()} expira em $daysRemaining dias.',
            actionLabel: 'Renovar Agora',
            route: '/settings',
            isWarning: true,
          ));
        }
      }
    }

    // 2. Catálogo vazio
    if (totalProducts == 0) {
      final dismissed = await prefs.isAlertDismissed('dashboard_alert_emptyCatalog');
      if (!dismissed) {
        alerts.add(DashboardAlert(
          type: DashboardAlertType.emptyCatalog,
          title: 'Seu catálogo está vazio! Cadastre produtos para começar.',
          actionLabel: 'Cadastrar Primeiro Produto',
          route: '/products/new',
          isWarning: true,
        ));
      }
    }

    // 3. Nenhum cliente
    if (totalCustomers == 0) {
      final dismissed = await prefs.isAlertDismissed('dashboard_alert_noCustomers');
      if (!dismissed) {
        alerts.add(DashboardAlert(
          type: DashboardAlertType.noCustomers,
          title: 'Você ainda não tem clientes cadastrados.',
          actionLabel: 'Cadastrar Primeiro Cliente',
          route: '/customers/new',
        ));
      }
    }

    // 4. Produtos sem imagem (só se tem produtos)
    if (productsWithoutImage > 0 && totalProducts > 0) {
      final dismissed = await prefs.isAlertDismissed('dashboard_alert_productsWithoutImage');
      if (!dismissed) {
        alerts.add(DashboardAlert(
          type: DashboardAlertType.productsWithoutImage,
          title: 'Você tem $productsWithoutImage produto${productsWithoutImage > 1 ? "s" : ""} sem foto cadastrada.',
          actionLabel: 'Ver Produtos',
          route: '/products',
        ));
      }
    }

    // 5. Sem vendas no mês
    if (salesCountThisMonth == 0) {
      final dismissed = await prefs.isAlertDismissed('dashboard_alert_noSalesThisMonth');
      if (!dismissed) {
        alerts.add(DashboardAlert(
          type: DashboardAlertType.noSalesThisMonth,
          title: 'Você ainda não registrou vendas este mês.',
          actionLabel: 'Fazer Primeira Venda',
          route: '/sales/new',
        ));
      }
    }

    // Ordenar por prioridade e limitar a 3
    alerts.sort((a, b) => a.priority.compareTo(b.priority));
    return alerts.take(3).toList();
  }
}
