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
      DSBadge(label: _planLabel, type: _planBadgeType),
      DSBadge(
        label: tenant.isActive ? 'Ativo' : 'Inativo',
        type: tenant.isActive ? DSBadgeType.success : DSBadgeType.error,
      ),
    ];
  }

  String? _buildMetadata() {
    if (tenant.isTrial && tenant.trialEndDate != null) {
      final days = tenant.trialDaysRemaining;
      if (days < 0) {
        return 'Trial expirado';
      }
      return 'Trial: $days dias restantes';
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

  String get _planLabel {
    switch (tenant.plan) {
      case 'trial':
        return 'Trial';
      case 'basic':
        return 'Basic';
      case 'full':
        return 'Full';
      default:
        return tenant.plan;
    }
  }

  DSBadgeType get _planBadgeType {
    switch (tenant.plan) {
      case 'trial':
        return DSBadgeType.warning;
      case 'basic':
        return DSBadgeType.info;
      case 'full':
        return DSBadgeType.success;
      default:
        return DSBadgeType.info;
    }
  }

  Color get _planColor {
    final colors = DSColors();
    switch (tenant.plan) {
      case 'trial':
        return colors.yellow;
      case 'basic':
        return colors.blue;
      case 'full':
        return colors.green;
      default:
        return colors.blue;
    }
  }
}
