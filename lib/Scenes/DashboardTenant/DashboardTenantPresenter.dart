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
      final snapshot = await _repository.loadDashboardSnapshot();

      // Gerar alertas
      final alerts = await _generateAlerts(
        totalProducts: snapshot.totalProducts,
        productsWithoutImage: snapshot.productsWithoutImage,
        totalCustomers: snapshot.totalCustomers,
        salesCountThisMonth: snapshot.salesCountThisMonth,
        pendingEscalationsCount: snapshot.pendingEscalationsCount,
        pendingStockAlertsCount: snapshot.pendingStockAlertsCount,
      );

      _update(
        _viewModel.copyWith(
          isLoading: false,
          salesToday: snapshot.salesToday,
          salesYesterday: snapshot.salesYesterday,
          salesThisMonth: snapshot.salesThisMonth,
          salesLastMonthSamePeriod: snapshot.salesLastMonthSamePeriod,
          salesCountThisMonth: snapshot.salesCountThisMonth,
          salesCountLastMonth: snapshot.salesCountLastMonth,
          totalCustomers: snapshot.totalCustomers,
          newCustomersThisMonth: snapshot.newCustomersThisMonth,
          salesLast7Days: snapshot.salesLast7Days,
          recentSales: snapshot.recentSales,
          totalProducts: snapshot.totalProducts,
          productsWithoutImage: snapshot.productsWithoutImage,
          alerts: alerts,
          pendingEscalationsCount: snapshot.pendingEscalationsCount,
          pendingStockAlertsCount: snapshot.pendingStockAlertsCount,
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
    required int pendingEscalationsCount,
    required int pendingStockAlertsCount,
  }) async {
    final alerts = <DashboardAlert>[];
    final prefs = PreferencesManager.instance;
    final tenant = SessionManager.instance.currentTenant;

    // 1. Servi\u00e7o interrompido (ap\u00f3s grace period de 5 dias)
    if (tenant != null && tenant.isServiceInterrupted) {
      alerts.add(
        DashboardAlert(
          type: DashboardAlertType.serviceInterrupted,
          title:
              'Seu atendimento automatizado foi interrompido. Renove seu plano para reativar.',
          actionLabel: 'Renovar Agora',
          route: '/upgrade',
          isCritical: true,
        ),
      );
    }
    // 2. Plano expirado (dentro do grace period de 5 dias)
    else if (tenant != null && tenant.isInGracePeriod) {
      final graceEnd = tenant.expirationDate!.add(const Duration(days: 5));
      final graceDays = graceEnd.difference(DateTime.now()).inDays;
      alerts.add(
        DashboardAlert(
          type: DashboardAlertType.planExpired,
          title:
              'Seu plano expirou! Seus atendimentos ser\u00e3o interrompidos em $graceDays dias.',
          actionLabel: 'Renovar Agora',
          route: '/upgrade',
          isCritical: true,
        ),
      );
    }
    // 3. Plano expirando (\u2264 5 dias)
    else if (tenant != null && tenant.isExpirationWarning) {
      final days = tenant.daysUntilExpiration;
      final dismissed = await prefs.isAlertDismissed(
        'dashboard_alert_planExpiring',
      );
      if (!dismissed) {
        alerts.add(
          DashboardAlert(
            type: DashboardAlertType.planExpiring,
            title:
                'Seu plano ${tenant.planLabel} expira em $days dia${days != 1 ? "s" : ""}.',
            actionLabel: 'Renovar Agora',
            route: '/upgrade',
            isWarning: true,
          ),
        );
      }
    }
    // 4. Trial ativo (sutil) — exibir que est\u00e1 em trial com link para upgrade
    else if (tenant != null && tenant.isTrial && !tenant.isTrialExpired) {
      final days = tenant.trialDaysRemaining;
      alerts.add(
        DashboardAlert(
          type: DashboardAlertType.trialActive,
          title:
              'Voc\u00ea est\u00e1 no plano Trial \u2022 $days dias restantes',
          actionLabel: 'Fazer Upgrade',
          route: '/upgrade',
        ),
      );
    }

    // 2. Catálogo vazio
    if (totalProducts == 0) {
      final dismissed = await prefs.isAlertDismissed(
        'dashboard_alert_emptyCatalog',
      );
      if (!dismissed) {
        alerts.add(
          DashboardAlert(
            type: DashboardAlertType.emptyCatalog,
            title: 'Seu catálogo está vazio! Cadastre produtos para começar.',
            actionLabel: 'Cadastrar Primeiro Produto',
            route: '/products/new',
            isWarning: true,
          ),
        );
      }
    }

    // 3. Nenhum cliente
    if (totalCustomers == 0) {
      final dismissed = await prefs.isAlertDismissed(
        'dashboard_alert_noCustomers',
      );
      if (!dismissed) {
        alerts.add(
          DashboardAlert(
            type: DashboardAlertType.noCustomers,
            title: 'Você ainda não tem clientes cadastrados.',
            actionLabel: 'Cadastrar Primeiro Cliente',
            route: '/customers/new',
          ),
        );
      }
    }

    // 4. Produtos sem imagem (só se tem produtos)
    if (productsWithoutImage > 0 && totalProducts > 0) {
      final dismissed = await prefs.isAlertDismissed(
        'dashboard_alert_productsWithoutImage',
      );
      if (!dismissed) {
        alerts.add(
          DashboardAlert(
            type: DashboardAlertType.productsWithoutImage,
            title:
                'Você tem $productsWithoutImage produto${productsWithoutImage > 1 ? "s" : ""} sem foto cadastrada.',
            actionLabel: 'Ver Produtos',
            route: '/products',
          ),
        );
      }
    }

    // 5. Sem vendas no mês
    if (salesCountThisMonth == 0) {
      final dismissed = await prefs.isAlertDismissed(
        'dashboard_alert_noSalesThisMonth',
      );
      if (!dismissed) {
        alerts.add(
          DashboardAlert(
            type: DashboardAlertType.noSalesThisMonth,
            title: 'Você ainda não registrou vendas este mês.',
            actionLabel: 'Fazer Primeira Venda',
            route: '/sales/new',
          ),
        );
      }
    }

    // 6. Escalações pendentes
    if (pendingEscalationsCount > 0) {
      alerts.add(
        DashboardAlert(
          type: DashboardAlertType.pendingEscalations,
          title:
              'Você tem $pendingEscalationsCount escalação${pendingEscalationsCount > 1 ? "ões" : ""} pendente${pendingEscalationsCount > 1 ? "s" : ""}.',
          actionLabel: 'Ver Escalações',
          route: '/escalations',
          isWarning: true,
        ),
      );
    }

    // 7. Alertas de estoque pendentes
    if (pendingStockAlertsCount > 0) {
      alerts.add(
        DashboardAlert(
          type: DashboardAlertType.pendingStockAlerts,
          title:
              'Você tem $pendingStockAlertsCount alerta${pendingStockAlertsCount > 1 ? "s" : ""} de estoque pendente${pendingStockAlertsCount > 1 ? "s" : ""}.',
          actionLabel: 'Ver Estoque',
          route: '/stock-alerts',
          isWarning: true,
        ),
      );
    }

    // Ordenar por prioridade e limitar a 3
    alerts.sort((a, b) => a.priority.compareTo(b.priority));
    return alerts.take(3).toList();
  }
}
