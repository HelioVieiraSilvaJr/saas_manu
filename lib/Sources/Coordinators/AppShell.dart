import 'package:flutter/material.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../SessionManager.dart';
import '../PreferencesManager.dart';
import '../../Scenes/Login/LoginCoordinator.dart';

/// Shell principal da aplicação após login.
///
/// Fornece Drawer/Sidebar com navegação, tenant switcher e logout.
class AppShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({super.key, required this.child, required this.currentRoute});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final session = SessionManager.instance;
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.scaffoldBackground,
      appBar: _buildAppBar(colors, session, isWide),
      drawer: isWide ? null : _buildDrawer(colors, session),
      body: Row(
        children: [
          // Sidebar para Web
          if (isWide) _buildSidebar(colors, session),

          // Conteúdo principal
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  // MARK: - AppBar

  PreferredSizeWidget _buildAppBar(
    DSColors colors,
    SessionManager session,
    bool isWide,
  ) {
    final textStyles = DSTextStyle();

    return AppBar(
      backgroundColor: colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: isWide
          ? null
          : IconButton(
              icon: Icon(Icons.menu, color: colors.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: Row(
        children: [
          if (isWide) ...[
            Icon(
              Icons.storefront_rounded,
              color: colors.primaryColor,
              size: 28,
            ),
            const SizedBox(width: DSSpacing.sm),
          ],
          Expanded(
            child: Text(
              session.currentTenant?.name ?? 'SaaS CRM',
              style: textStyles.headline3.copyWith(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Tenant Switcher (se tiver múltiplos tenants)
        if (session.hasMultipleTenants)
          PopupMenuButton<String>(
            icon: Icon(Icons.swap_horiz, color: colors.textSecondary),
            tooltip: 'Trocar Tenant',
            onSelected: (tenantId) => _switchTenant(tenantId),
            itemBuilder: (context) {
              return session.allMemberships.map((m) {
                final isSelected = m.tenantId == session.currentTenant?.uid;
                return PopupMenuItem<String>(
                  value: m.tenantId,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? colors.primaryColor
                            : colors.greyLight,
                        size: DSSpacing.iconMd,
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      Expanded(
                        child: Text(
                          m.tenantId,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DSAvatar(name: session.currentUser?.name ?? 'U', size: 32),
                const SizedBox(width: DSSpacing.xs),
                Icon(Icons.arrow_drop_down, color: colors.textSecondary),
              ],
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') _handleLogout();
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
                      style: textStyles.bodyLarge,
                    ),
                    Text(
                      session.currentUser?.email ?? '',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.xs),
                    DSBadge(
                      label: session.currentMembership?.role.label ?? 'User',
                      type: session.isSuperAdmin
                          ? DSBadgeType.primary
                          : session.isTenantAdmin
                          ? DSBadgeType.info
                          : DSBadgeType.success,
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Sair'),
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

  // MARK: - Sidebar (Web)

  Widget _buildSidebar(DSColors colors, SessionManager session) {
    final textStyles = DSTextStyle();

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colors.white,
        border: Border(right: BorderSide(color: colors.divider)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: DSSpacing.base),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/dashboard',
                  colors: colors,
                  textStyles: textStyles,
                ),

                // Seção CRM - acessível a todos
                _buildSectionHeader('CRM', textStyles, colors),
                _buildNavItem(
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2,
                  label: 'Produtos',
                  route: '/products',
                  colors: colors,
                  textStyles: textStyles,
                ),
                _buildNavItem(
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  label: 'Clientes',
                  route: '/customers',
                  colors: colors,
                  textStyles: textStyles,
                ),
                _buildNavItem(
                  icon: Icons.shopping_cart_outlined,
                  selectedIcon: Icons.shopping_cart,
                  label: 'Vendas',
                  route: '/sales',
                  colors: colors,
                  textStyles: textStyles,
                ),

                // Seção Admin - apenas TenantAdmin/SuperAdmin
                if (session.canManageTenant()) ...[
                  _buildSectionHeader('Administração', textStyles, colors),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: 'Configurações',
                    route: '/settings',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                  _buildNavItem(
                    icon: Icons.group_outlined,
                    selectedIcon: Icons.group,
                    label: 'Equipe',
                    route: '/team',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                ],

                // SuperAdmin
                if (session.isSuperAdmin) ...[
                  _buildSectionHeader('Super Admin', textStyles, colors),
                  _buildNavItem(
                    icon: Icons.admin_panel_settings_outlined,
                    selectedIcon: Icons.admin_panel_settings,
                    label: 'Dashboard Admin',
                    route: '/admin/dashboard',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                  _buildNavItem(
                    icon: Icons.business_outlined,
                    selectedIcon: Icons.business,
                    label: 'Tenants',
                    route: '/admin/tenants',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Drawer (Mobile)

  Widget _buildDrawer(DSColors colors, SessionManager session) {
    final textStyles = DSTextStyle();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(DSSpacing.base),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.divider)),
              ),
              child: Row(
                children: [
                  DSAvatar(name: session.currentUser?.name ?? 'U', size: 48),
                  const SizedBox(width: DSSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.currentUser?.name ?? '',
                          style: textStyles.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: DSSpacing.xxs),
                        Text(
                          session.currentTenant?.name ?? '',
                          style: textStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
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
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    route: '/dashboard',
                    colors: colors,
                    textStyles: textStyles,
                  ),

                  const Divider(),
                  _buildDrawerSectionHeader('CRM', textStyles, colors),
                  _buildDrawerItem(
                    icon: Icons.inventory_2,
                    label: 'Produtos',
                    route: '/products',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                  _buildDrawerItem(
                    icon: Icons.people,
                    label: 'Clientes',
                    route: '/customers',
                    colors: colors,
                    textStyles: textStyles,
                  ),
                  _buildDrawerItem(
                    icon: Icons.shopping_cart,
                    label: 'Vendas',
                    route: '/sales',
                    colors: colors,
                    textStyles: textStyles,
                  ),

                  if (session.canManageTenant()) ...[
                    const Divider(),
                    _buildDrawerSectionHeader(
                      'Administração',
                      textStyles,
                      colors,
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings,
                      label: 'Configurações',
                      route: '/settings',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                    _buildDrawerItem(
                      icon: Icons.group,
                      label: 'Equipe',
                      route: '/team',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ],

                  if (session.isSuperAdmin) ...[
                    const Divider(),
                    _buildDrawerSectionHeader(
                      'Super Admin',
                      textStyles,
                      colors,
                    ),
                    _buildDrawerItem(
                      icon: Icons.admin_panel_settings,
                      label: 'Dashboard Admin',
                      route: '/admin/dashboard',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                    _buildDrawerItem(
                      icon: Icons.business,
                      label: 'Tenants',
                      route: '/admin/tenants',
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ],
                ],
              ),
            ),

            // Tenant switcher (mobile)
            if (session.hasMultipleTenants)
              Container(
                padding: const EdgeInsets.all(DSSpacing.md),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trocar Tenant',
                      style: textStyles.labelSmall.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.sm),
                    ...session.allMemberships.map((m) {
                      final isSelected =
                          m.tenantId == session.currentTenant?.uid;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? colors.primaryColor
                              : colors.greyLight,
                          size: DSSpacing.iconMd,
                        ),
                        title: Text(
                          m.tenantId,
                          style: textStyles.bodySmall.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: isSelected
                            ? null
                            : () {
                                Navigator.pop(context); // Fechar drawer
                                _switchTenant(m.tenantId);
                              },
                      );
                    }),
                  ],
                ),
              ),

            // Logout
            Container(
              padding: const EdgeInsets.all(DSSpacing.md),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.divider)),
              ),
              child: ListTile(
                leading: Icon(Icons.logout, color: colors.red),
                title: Text(
                  'Sair',
                  style: DSTextStyle().bodyMedium.copyWith(color: colors.red),
                ),
                onTap: _handleLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Navigation Items

  Widget _buildSectionHeader(
    String title,
    DSTextStyle textStyles,
    DSColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.base,
        DSSpacing.lg,
        DSSpacing.base,
        DSSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: textStyles.labelSmall.copyWith(
          color: colors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String route,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final isSelected = widget.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.sm,
        vertical: DSSpacing.xxs,
      ),
      child: Material(
        color: isSelected
            ? colors.primaryColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
          onTap: isSelected ? null : () => _navigateTo(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.md,
              vertical: DSSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? colors.primaryColor
                      : colors.textSecondary,
                  size: DSSpacing.iconLg,
                ),
                const SizedBox(width: DSSpacing.md),
                Text(
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
        DSSpacing.base,
        DSSpacing.sm,
        DSSpacing.base,
        DSSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: textStyles.labelSmall.copyWith(
          color: colors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required String route,
    required DSColors colors,
    required DSTextStyle textStyles,
  }) {
    final isSelected = widget.currentRoute == route;

    return ListTile(
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
      selected: isSelected,
      selectedTileColor: colors.primaryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
      ),
      onTap: () {
        Navigator.pop(context); // Fechar drawer
        if (!isSelected) _navigateTo(route);
      },
    );
  }

  // MARK: - Actions

  void _navigateTo(String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  Future<void> _switchTenant(String tenantId) async {
    try {
      await SessionManager.instance.switchTenant(tenantId);
      if (mounted) {
        // Recarregar a tela atual
        Navigator.of(context).pushReplacementNamed('/dashboard');
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
      await SessionManager.instance.signOut();
      await PreferencesManager.instance.clear();
      if (mounted) {
        LoginCoordinator.navigateToLoginAndClearStack(context);
      }
    }
  }
}
