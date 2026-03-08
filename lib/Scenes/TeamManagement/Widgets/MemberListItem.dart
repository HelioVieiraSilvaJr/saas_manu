import 'package:flutter/material.dart';
import '../../../Commons/Enums/UserRole.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/MembershipModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../../Commons/Widgets/DesignSystem/DSBadge.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSListTile.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Sources/SessionManager.dart';

/// Widget de item de membro na lista — Módulo 9.
class MemberListItem extends StatelessWidget {
  final MembershipModel member;
  final bool isWeb;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const MemberListItem({
    super.key,
    required this.member,
    this.isWeb = false,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final currentUserId = SessionManager.instance.currentUser?.uid;

    return DSListTile(
      leading: DSAvatar(
        name: member.userName ?? member.userEmail ?? '?',
        size: 48,
      ),
      title: member.userName ?? member.userEmail ?? '—',
      subtitle: member.userEmail ?? '',
      badges: [
        DSBadge(
          label: member.role == UserRole.tenantAdmin ? 'Admin' : 'User',
          type: member.role == UserRole.tenantAdmin
              ? DSBadgeType.primary
              : DSBadgeType.info,
        ),
        if (!member.isActive)
          const DSBadge(label: 'Inativo', type: DSBadgeType.error),
        if (member.userId == currentUserId)
          const DSBadge(label: 'Você', type: DSBadgeType.success),
      ],
      metadata: _buildMetadata(),
      trailing: [
        if (isWeb) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Editar',
            onPressed: onEdit,
            color: colors.textTertiary,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Remover',
            onPressed: onRemove,
            color: colors.red,
          ),
        ] else ...[
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'remove') onRemove();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: DSSpacing.sm),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: colors.red),
                    const SizedBox(width: DSSpacing.sm),
                    Text('Remover', style: TextStyle(color: colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _buildMetadata() {
    if (!member.isActive && member.removedAt != null) {
      final days = DateTime.now().difference(member.removedAt!).inDays;
      return 'Inativo há $days dias';
    }
    return 'Adicionado em: ${member.createdAt.formatShort()}';
  }
}
