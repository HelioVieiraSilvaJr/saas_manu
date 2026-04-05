import 'dart:async';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import '../../Commons/Constants/AppConstants.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Scenes/Escalations/EscalationsRepository.dart';
import '../../Scenes/StockAlerts/StockAlertsRepository.dart';
import '../../Scenes/Sales/SalesRepository.dart';
import '../SessionManager.dart';
import '../PreferencesManager.dart';
import '../../Scenes/Login/LoginCoordinator.dart';

/// Shell principal da aplicação — USE3D v2.0.
///
/// Fornece Sidebar/Drawer com navegação, tenant switcher e logout.
class AppShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({super.key, required this.child, required this.currentRoute});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<int>? _pendingCountSub;
  StreamSubscription<int>? _stockAlertCountSub;
  StreamSubscription<int>? _salesPendingCountSub;
  StreamSubscription<int>? _orderActiveCountSub;
  int _escalationPendingCount = 0;
  int _stockAlertPendingCount = 0;
  int _salesPendingCount = 0;
  int _orderActiveCount = 0;

  // Static para evitar subscriptions duplicadas entre instâncias de AppShell.
  static StreamSubscription? _automatedSalesSub;
  static String? _automatedSalesTenantId;
  static int _lastKnownSalesCount = -1;

  @override
  void initState() {
    super.initState();
    final session = SessionManager.instance;
    if (session.currentTenant != null && !session.isSuperAdmin) {
      _pendingCountSub = EscalationsRepository().watchPendingCount().listen((
        count,
      ) {
        if (mounted && count != _escalationPendingCount) {
          setState(() => _escalationPendingCount = count);
        }
      });
      _stockAlertCountSub = StockAlertsRepository().watchPendingCount().listen((
        count,
      ) {
        if (mounted && count != _stockAlertPendingCount) {
          setState(() => _stockAlertPendingCount = count);
        }
      });
      _salesPendingCountSub = SalesRepository().watchPendingSalesCount().listen(
        (count) {
          if (mounted && count != _salesPendingCount) {
            setState(() => _salesPendingCount = count);
          }
        },
      );
      _orderActiveCountSub = SalesRepository().watchActiveOrdersCount().listen((
        count,
      ) {
        if (mounted && count != _orderActiveCount) {
          setState(() => _orderActiveCount = count);
        }
      });
      _setupGlobalSalesListener();
    }
  }

  void _setupGlobalSalesListener() {
    final tenantId = SessionManager.instance.currentTenant?.uid;
    if (tenantId == null) return;

    if (_automatedSalesSub != null && _automatedSalesTenantId == tenantId) {
      return;
    }

    _automatedSalesSub?.cancel();
    _automatedSalesSub = null;
    _automatedSalesTenantId = tenantId;
    _lastKnownSalesCount = -1;

    _automatedSalesSub = SalesRepository().watchNewAutomatedSales().listen((
      newSales,
    ) {
      if (newSales.isEmpty) {
        _lastKnownSalesCount = 0;
        return;
      }
      if (_lastKnownSalesCount == -1) {
        // Primeira emissão: marcar contagem sem notificar
        _lastKnownSalesCount = newSales.length;
        return;
      }
      if (newSales.length > _lastKnownSalesCount && mounted) {
        final diff = newSales.length - _lastKnownSalesCount;
        ElegantNotification.success(
          title: const Text('Nova Venda WhatsApp!'),
          description: Text(
            '$diff nova(s) venda(s) automática(s) recebida(s).',
          ),
        ).show(context);
      }
      _lastKnownSalesCount = newSales.length;
    });
  }

  /// Cancela a subscription global (chamado no logout).
  static void cancelGlobalListeners() {
    _automatedSalesSub?.cancel();
    _automatedSalesSub = null;
    _automatedSalesTenantId = null;
    _lastKnownSalesCount = -1;
  }

  @override
  void dispose() {
    _pendingCountSub?.cancel();
    _stockAlertCountSub?.cancel();
    _salesPendingCountSub?.cancel();
    _orderActiveCountSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final session = SessionManager.instance;
    final isWide =
        MediaQuery.of(context).size.width >= DSSpacing.breakpointTablet;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.scaffoldBackground,
      appBar: _buildAppBar(colors, session, isWide),
      drawer: isWide ? null : _buildDrawer(colors, session),
      body: Row(
        children: [
          if (isWide) _buildSidebar(colors, session),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // APPBAR
  // ══════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(
    DSColors colors,
    SessionManager session,
    bool isWide,
  ) {
    final textStyles = DSTextStyle();

    return AppBar(
      backgroundColor: colors.surfaceColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: isWide
          ? null
          : IconButton(
              icon: Icon(Icons.menu_rounded, color: colors.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: Row(
        children: [
          if (isWide) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: colors.primaryGradient,
                borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: DSSpacing.md),
          ],
          Expanded(
            child: Text(
              session.currentTenant?.name ?? 'SaaS CRM',
              style: textStyles.headline3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Tenant Switcher
        if (session.hasMultipleTenants && !session.isInspectingTenantAsAdmin)
          PopupMenuButton<String>(
            icon: Icon(Icons.swap_horiz_rounded, color: colors.textSecondary),
            tooltip: 'Trocar Tenant',
            onSelected: (tenantId) => _switchTenant(tenantId),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
            ),
            itemBuilder: (context) {
              return session.allMemberships.map((m) {
                final isSelected = m.tenantId == session.currentTenant?.uid;
                final displayName = m.tenantName ?? m.tenantId;
                final roleLabel = m.role.label;
                return PopupMenuItem<String>(
                  value: m.tenantId,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? colors.secundaryColor
                            : colors.greyLight,
                        size: DSSpacing.iconMd,
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      Expanded(
                        child: Text(
                          '$displayName ($roleLabel)',
                          style: textStyles.bodyMedium.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),

        // User menu
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DSAvatar(
                  name: session.currentUser?.name ?? 'U',
                  size: 34,
                  showBorder: true,
                ),
                const SizedBox(width: DSSpacing.xs),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') _handleLogout();
            if (value == 'end_inspection') _stopTenantInspection();
          },
          itemBuilder: (context) {
            final textStyles = DSTextStyle();
            return [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.currentUser?.name ?? '',
                      style: textStyles.labelLarge,
                    ),
                    const SizedBox(height: DSSpacing.xxs),
                    Text(
                      session.currentUser?.email ?? '',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.xs),
                    Text(
                      'Versão ${AppConstants.appVersion}',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.sm),
                    DSBadge(
                      label: session.isInspectingTenantAsAdmin
                          ? 'Inspecionando como Admin'
                          : session.currentMembership?.role.label ?? 'User',
                      type: session.isInspectingTenantAsAdmin
                          ? DSBadgeType.warning
                          : session.isSuperAdmin
                          ? DSBadgeType.primary
                          : session.isTenantAdmin
                          ? DSBadgeType.info
                          : DSBadgeType.success,
                    ),
                  ],
                ),
              ),
              if (session.isInspectingTenantAsAdmin) const PopupMenuDivider(),
              if (session.isInspectingTenantAsAdmin)
                PopupMenuItem<String>(
                  value: 'end_inspection',
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      Text('Encerrar inspeção', style: textStyles.bodyMedium),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: colors.red),
                    const SizedBox(width: DSSpacing.sm),
                    Text(
                      'Sair',
                      style: textStyles.bodyMedium.copyWith(color: colors.red),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: colors.divider),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // SIDEBAR (Web)
  // ══════════════════════════════════════════════

  Widget _buildSidebar(DSColors colors, SessionManager session) {
    final textStyles = DSTextStyle();

    return Container(
      width: DSSpacing.sidebarWidthExpanded,
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        border: Border(right: BorderSide(color: colors.divider)),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: DSSpacing.elevationSmBlur,
            offset: Offset(DSSpacing.elevationSmOffset, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: DSSpacing.md),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: session.isSuperAdmin
                      ? '/admin/dashboard'
                      : '/dashboard',
                  colors: colors,
                  textStyles: textStyles,
                ),

                if (!session.isSuperAdmin) ...[
                  _buildSectionHeader('CRM', textStyles, colors),
                  _buildNavItem(
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2_rounded,
                    label: 'Produtos',
                    route: '/products',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                  _buildNavItem(
                    icon: Icons.people_outline_rounded,
                    selectedIcon: Icons.people_rounded,
                    label: 'Clientes',
                    route: '/customers',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                  _buildNavItem(
                    icon: Icons.shopping_cart_outlined,
                    selectedIcon: Icons.shopping_cart_rounded,
                    label: 'Vendas',
                    route: '/sales',
                    colors: colors,
                    textStyles: textStyles,
                    badgeCount: _salesPendingCount,
                  ),
                  _buildNavItem(
                    icon: Icons.view_kanban_outlined,
                    selectedIcon: Icons.view_kanban_rounded,
                    label: 'Pedidos',
                    route: '/orders',
                    colors: colors,
                    textStyles: textStyles,
                    badgeCount: _orderActiveCount,
                  ),
                  _buildNavItem(
                    icon: Icons.support_agent_outlined,
                    selectedIcon: Icons.support_agent_rounded,
                    label: 'Atendimentos',
                    route: '/escalations',
                    colors: colors,
                    textStyles: textStyles,
                    badgeCount: _escalationPendingCount,
                  ),
                  _buildNavItem(
                    icon: Icons.notifications_outlined,
                    selectedIcon: Icons.notifications_rounded,
                    label: 'Avisos de Estoque',
                    route: '/stock-alerts',
                    colors: colors,
                    textStyles: textStyles,
                    badgeCount: _stockAlertPendingCount,
                  ),
                ],

                if (session.canManageTenant() && !session.isSuperAdmin) ...[
                  _buildSectionHeader('Administração', textStyles, colors),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    label: 'Configurações',
                    route: '/settings',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                  _buildNavItem(
                    icon: Icons.group_outlined,
                    selectedIcon: Icons.group_rounded,
                    label: 'Equipe',
                    route: '/team',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                ],

                if (session.isSuperAdmin) ...[
                  _buildSectionHeader('Gerenciamento', textStyles, colors),
                  _buildNavItem(
                    icon: Icons.business_outlined,
                    selectedIcon: Icons.business_rounded,
                    label: 'Tenants',
                    route: '/admin/tenants',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                  _buildNavItem(
                    icon: Icons.sell_outlined,
                    selectedIcon: Icons.sell_rounded,
                    label: 'Planos',
                    route: '/admin/plans',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              DSSpacing.lg,
              DSSpacing.sm,
              DSSpacing.lg,
              DSSpacing.lg,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.divider)),
            ),
            child: Text(
              'Versão ${AppConstants.appVersion}',
              style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // DRAWER (Mobile)
  // ══════════════════════════════════════════════

  Widget _buildDrawer(DSColors colors, SessionManager session) {
    final textStyles = DSTextStyle();

    return Drawer(
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(DSSpacing.radiusLg),
          bottomRight: Radius.circular(DSSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header com gradiente
            Container(
              padding: const EdgeInsets.all(DSSpacing.lg),
              decoration: BoxDecoration(gradient: colors.primaryGradient),
              child: Row(
                children: [
                  DSAvatar(
                    name: session.currentUser?.name ?? 'U',
                    size: 48,
                    showBorder: true,
                  ),
                  const SizedBox(width: DSSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.currentUser?.name ?? '',
                          style: textStyles.labelLarge.copyWith(
                            color: colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: DSSpacing.xxs),
                        Text(
                          session.currentTenant?.name ?? '',
                          style: textStyles.bodySmall.copyWith(
                            color: colors.white.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: DSSpacing.sm),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    route: session.isSuperAdmin
                        ? '/admin/dashboard'
                        : '/dashboard',
                    colors: colors,
                    textStyles: textStyles,
                  ),

                  if (!session.isSuperAdmin) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.base,
                      ),
                      child: Divider(
                        color: colors.divider,
                        height: DSSpacing.base,
                      ),
                    ),
                    _buildDrawerSectionHeader('CRM', textStyles, colors),
                    _buildDrawerItem(
                      icon: Icons.inventory_2_rounded,
                      label: 'Produtos',
                      route: '/products',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                    _buildDrawerItem(
                      icon: Icons.people_rounded,
                      label: 'Clientes',
                      route: '/customers',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                    _buildDrawerItem(
                      icon: Icons.shopping_cart_rounded,
                      label: 'Vendas',
                      route: '/sales',
                      colors: colors,
                      textStyles: textStyles,
                      badgeCount: _salesPendingCount,
                    ),
                    _buildDrawerItem(
                      icon: Icons.view_kanban_rounded,
                      label: 'Pedidos',
                      route: '/orders',
                      colors: colors,
                      textStyles: textStyles,
                      badgeCount: _orderActiveCount,
                    ),
                    _buildDrawerItem(
                      icon: Icons.support_agent_rounded,
                      label: 'Atendimentos',
                      route: '/escalations',
                      colors: colors,
                      textStyles: textStyles,
                      badgeCount: _escalationPendingCount,
                    ),
                    _buildDrawerItem(
                      icon: Icons.notifications_rounded,
                      label: 'Avisos de Estoque',
                      route: '/stock-alerts',
                      colors: colors,
                      textStyles: textStyles,
                      badgeCount: _stockAlertPendingCount,
                    ),
                  ],

                  if (session.canManageTenant() && !session.isSuperAdmin) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.base,
                      ),
                      child: Divider(
                        color: colors.divider,
                        height: DSSpacing.base,
                      ),
                    ),
                    _buildDrawerSectionHeader(
                      'Administração',
                      textStyles,
                      colors,
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings_rounded,
                      label: 'Configurações',
                      route: '/settings',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                    _buildDrawerItem(
                      icon: Icons.group_rounded,
                      label: 'Equipe',
                      route: '/team',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ],

                  if (session.isSuperAdmin) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.base,
                      ),
                      child: Divider(
                        color: colors.divider,
                        height: DSSpacing.base,
                      ),
                    ),
                    _buildDrawerSectionHeader(
                      'Gerenciamento',
                      textStyles,
                      colors,
                    ),
                    _buildDrawerItem(
                      icon: Icons.business_rounded,
                      label: 'Tenants',
                      route: '/admin/tenants',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                    _buildDrawerItem(
                      icon: Icons.sell_rounded,
                      label: 'Planos',
                      route: '/admin/plans',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ],
                ],
              ),
            ),

            // Tenant switcher (mobile)
            if (session.hasMultipleTenants &&
                !session.isInspectingTenantAsAdmin)
              Container(
                padding: const EdgeInsets.all(DSSpacing.md),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TROCAR TENANT', style: textStyles.overline),
                    const SizedBox(height: DSSpacing.sm),
                    ...session.allMemberships.map((m) {
                      final isSelected =
                          m.tenantId == session.currentTenant?.uid;
                      final displayName = m.tenantName ?? m.tenantId;
                      final roleLabel = m.role.label;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? colors.secundaryColor
                              : colors.greyLight,
                          size: DSSpacing.iconMd,
                        ),
                        title: Text(
                          '$displayName ($roleLabel)',
                          style: textStyles.bodySmall.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: isSelected
                            ? null
                            : () {
                                Navigator.pop(context);
                                _switchTenant(m.tenantId);
                              },
                      );
                    }),
                  ],
                ),
              ),

            // Logout
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.md,
                vertical: DSSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.divider)),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
                ),
                leading: Icon(Icons.logout_rounded, color: colors.red),
                title: Text(
                  'Sair',
                  style: textStyles.bodyMedium.copyWith(color: colors.red),
                ),
                onTap: _handleLogout,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: DSSpacing.md),
              child: Text(
                'Versão ${AppConstants.appVersion}',
                style: textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // NAVIGATION ITEMS
  // ══════════════════════════════════════════════

  Widget _buildSectionHeader(
    String title,
    DSTextStyle textStyles,
    DSColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.lg,
        DSSpacing.lg,
        DSSpacing.lg,
        DSSpacing.sm,
      ),
      child: Text(title.toUpperCase(), style: textStyles.overline),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String route,
    required DSColors colors,
    required DSTextStyle textStyles,
    int badgeCount = 0,
  }) {
    final isSelected = widget.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: isSelected ? colors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
          hoverColor: colors.primarySurface.withValues(alpha: 0.5),
          onTap: isSelected ? null : () => _navigateTo(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.md,
              vertical: DSSpacing.md,
            ),
            child: Row(
              children: [
                // Barra lateral de indicação ativa (teal)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: isSelected ? 24 : 0,
                  margin: const EdgeInsets.only(right: DSSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.secundaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? colors.primaryColor
                      : colors.textSecondary,
                  size: DSSpacing.iconLg,
                ),
                const SizedBox(width: DSSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: textStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? colors.primaryColor
                          : colors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(
    String title,
    DSTextStyle textStyles,
    DSColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.lg,
        DSSpacing.sm,
        DSSpacing.lg,
        DSSpacing.xs,
      ),
      child: Text(title.toUpperCase(), style: textStyles.overline),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required String route,
    required DSColors colors,
    required DSTextStyle textStyles,
    int badgeCount = 0,
  }) {
    final isSelected = widget.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.sm,
        vertical: 1,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? colors.primaryColor : colors.textSecondary,
        ),
        title: Text(
          label,
          style: textStyles.bodyMedium.copyWith(
            color: isSelected ? colors.primaryColor : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor: colors.primarySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        ),
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) _navigateTo(route);
        },
      ),
    );
  }

  // MARK: - Actions

  void _navigateTo(String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  Future<void> _switchTenant(String tenantId) async {
    try {
      cancelGlobalListeners();
      await SessionManager.instance.switchTenant(tenantId);
      if (mounted) {
        final route = SessionManager.instance.isSuperAdmin
            ? '/admin/dashboard'
            : '/dashboard';
        Navigator.of(context).pushReplacementNamed(route);
      }
    } catch (e) {
      if (mounted) {
        await DSAlertDialog.showError(
          context: context,
          title: 'Erro',
          message: 'Não foi possível trocar de tenant: $e',
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await DSAlertDialog.showConfirm(
      context: context,
      title: 'Sair',
      message: 'Deseja realmente sair da sua conta?',
      confirmLabel: 'Sair',
    );

    if (confirm == true && mounted) {
      _pendingCountSub?.cancel();
      _stockAlertCountSub?.cancel();
      _salesPendingCountSub?.cancel();
      _orderActiveCountSub?.cancel();
      cancelGlobalListeners();
      await SessionManager.instance.signOut();
      await PreferencesManager.instance.clear();
      if (mounted) {
        LoginCoordinator.navigateToLoginAndClearStack(context);
      }
    }
  }

  Future<void> _stopTenantInspection() async {
    final inspectedTenantId = SessionManager.instance.currentTenant?.uid;

    try {
      cancelGlobalListeners();
      await SessionManager.instance.stopTenantInspection();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/admin/tenants/detail',
          (_) => false,
          arguments: inspectedTenantId,
        );
      }
    } catch (e) {
      if (mounted) {
        await DSAlertDialog.showError(
          context: context,
          title: 'Erro',
          message: 'Não foi possível encerrar a inspeção: $e',
        );
      }
    }
  }
}
