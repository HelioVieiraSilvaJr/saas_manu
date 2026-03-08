import 'package:flutter/material.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../Sources/SessionManager.dart';
import '../../Sources/Coordinators/AppShell.dart';

/// Placeholder do Dashboard Tenant.
///
/// Será substituído pelo Módulo 2 completo.
class DashboardTenantPage extends StatelessWidget {
  const DashboardTenantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(currentRoute: '/dashboard', child: _buildContent());
  }

  Widget _buildContent() {
    final colors = DSColors();
    final textStyles = DSTextStyle();
    final session = SessionManager.instance;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_rounded,
              size: 80,
              color: colors.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: DSSpacing.xl),
            Text(
              'Dashboard',
              style: textStyles.headline1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.sm),
            Text(
              'Bem-vindo, ${session.currentUser?.name ?? "Usuário"}!',
              style: textStyles.bodyLarge.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.base),
            Text(
              'Tenant: ${session.currentTenant?.name ?? "—"}\n'
              'Plano: ${session.currentTenant?.plan.toUpperCase() ?? "—"}\n'
              'Role: ${session.currentMembership?.role.label ?? "—"}',
              style: textStyles.bodyMedium.copyWith(color: colors.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.xxl),
            Text(
              'Este dashboard será implementado no Módulo 2.',
              style: textStyles.caption.copyWith(color: colors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
