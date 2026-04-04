import 'package:flutter/material.dart';
import '../../../Commons/Models/TenantModel.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSButton.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSListTile.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Widget de item da lista de Tenants.
class TenantListItem extends StatelessWidget {
  final TenantModel tenant;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TenantListItem({
    super.key,
    required this.tenant,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DSListTile(
      leading: CircleAvatar(
        backgroundColor: _planColor.withValues(alpha: 0.15),
        child: Text(
          tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : 'T',
          style: DSTextStyle().bodyMedium.copyWith(
            color: _planColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: tenant.name,
      subtitle: tenant.contactEmail,
      badges: _buildBadges(),
      metadata: _buildMetadata(),
      trailing: _buildTrailing(),
      onTap: onTap,
    );
  }

  List<DSBadge> _buildBadges() {
    return [
      DSBadge(label: tenant.planLabel, type: _planBadgeType),
      DSBadge(
        label: tenant.isActive ? 'Ativo' : 'Inativo',
        type: tenant.isActive ? DSBadgeType.success : DSBadgeType.error,
      ),
      if (tenant.isExpiredDynamic)
        const DSBadge(label: 'Expirado', type: DSBadgeType.error),
    ];
  }

  String? _buildMetadata() {
    // Expirado
    if (tenant.isExpiredDynamic && tenant.expirationDate != null) {
      return 'Expirou em ${tenant.expirationDate!.formatShort()}';
    }

    // Trial com data
    if (tenant.isTrial && tenant.trialEndDate != null) {
      final days = tenant.trialDaysRemaining;
      if (days < 0) {
        return 'Trial expirado';
      }
      return 'Trial: $days dias restantes';
    }

    // Plano pago com expiração
    if (tenant.expirationDate != null) {
      final days = tenant.daysUntilExpiration;
      if (days >= 0 && days <= 5) {
        return 'Expira em $days dias (${tenant.expirationDate!.formatShort()})';
      }
      return 'Expira: ${tenant.expirationDate!.formatShort()}';
    }

    if (tenant.nextPaymentDate != null) {
      return 'Próx. pagamento: ${tenant.nextPaymentDate!.formatShort()}';
    }

    return 'Criado: ${tenant.createdAt.formatShort()}';
  }

  List<Widget> _buildTrailing() {
    return [
      if (onEdit != null)
        DSButton.text(label: '', icon: Icons.edit_outlined, onTap: onEdit!),
      if (onDelete != null)
        DSButton.text(label: '', icon: Icons.delete_outline, onTap: onDelete!),
    ];
  }

  DSBadgeType get _planBadgeType {
    if (tenant.isTrial) return DSBadgeType.warning;
    if (tenant.planTier == 'pro') return DSBadgeType.success;
    return DSBadgeType.info;
  }

  Color get _planColor {
    final colors = DSColors();
    if (tenant.isTrial) return colors.yellow;
    if (tenant.planTier == 'pro') return colors.green;
    return colors.blue;
  }
}
