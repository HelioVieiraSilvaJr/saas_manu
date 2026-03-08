import 'package:flutter/material.dart';
import '../../Commons/Enums/UserRole.dart';
import '../../Commons/Models/MembershipModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../Sources/SessionManager.dart';
import 'TeamManagementRepository.dart';
import 'TeamManagementViewModel.dart';

/// Presenter para Gerenciar Equipe — Módulo 9.
class TeamManagementPresenter {
  final TeamManagementRepository _repository = TeamManagementRepository();
  TeamManagementViewModel viewModel = const TeamManagementViewModel();
  void Function()? onUpdate;

  void _notify() {
    onUpdate?.call();
  }

  // MARK: - Carregar membros

  Future<void> loadMembers() async {
    final tenantId = SessionManager.instance.currentTenant?.uid;
    if (tenantId == null) return;

    viewModel = viewModel.copyWith(isLoading: true);
    _notify();

    try {
      final members = await _repository.fetchMembers(tenantId);
      viewModel = viewModel.copyWith(isLoading: false, members: members);
      _notify();
    } catch (e) {
      AppLogger.error('Erro ao carregar membros', error: e);
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar membros.',
      );
      _notify();
    }
  }

  // MARK: - Busca

  void onSearch(String query) {
    viewModel = viewModel.copyWith(searchQuery: query);
    _notify();
  }

  // MARK: - Editar membro (role + ativo)

  Future<void> editMember(BuildContext context, MembershipModel member) async {
    // Variáveis editáveis
    UserRole selectedRole = member.role;
    bool isActive = member.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final colors = DSColors();
            return AlertDialog(
              title: const Text('Editar Membro'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info do membro
                    Text(
                      member.userName ?? member.userEmail ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      member.userEmail ?? '',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(height: 24),

                    // Permissão
                    const Text(
                      'Permissão',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<UserRole>(
                      title: Text(UserRole.tenantAdmin.label),
                      subtitle: Text(UserRole.tenantAdmin.description),
                      value: UserRole.tenantAdmin,
                      groupValue: selectedRole,
                      onChanged: (v) {
                        setDialogState(() => selectedRole = v!);
                      },
                    ),
                    RadioListTile<UserRole>(
                      title: Text(UserRole.user.label),
                      subtitle: Text(UserRole.user.description),
                      value: UserRole.user,
                      groupValue: selectedRole,
                      onChanged: (v) {
                        setDialogState(() => selectedRole = v!);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Status ativo
                    SwitchListTile(
                      title: const Text('Membro ativo'),
                      subtitle: Text(
                        isActive
                            ? 'Com acesso ao tenant'
                            : 'Sem acesso ao tenant',
                      ),
                      value: isActive,
                      onChanged: (v) {
                        setDialogState(() => isActive = v);
                      },
                    ),
                    if (!isActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(
                          'Se desmarcar, o usuário perde acesso.',
                          style: TextStyle(fontSize: 12, color: colors.yellow),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Salvar Alterações'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    // Validações

    // Não pode inativar a si mesmo
    if (member.userId == SessionManager.instance.currentUser!.uid &&
        !isActive) {
      await DSAlertDialog.showWarning(
        context: context,
        title: 'Ação Não Permitida',
        message: 'Você não pode inativar seu próprio acesso.',
      );
      return;
    }

    // Não pode remover último admin
    if (member.role == UserRole.tenantAdmin && selectedRole == UserRole.user) {
      final tenantId = SessionManager.instance.currentTenant!.uid;
      final adminCount = await _repository.countActiveAdmins(tenantId);
      if (adminCount <= 1) {
        await DSAlertDialog.showWarning(
          context: context,
          title: 'Ação Não Permitida',
          message: 'Deve haver pelo menos 1 Administrador na equipe.',
        );
        return;
      }
    }

    // Salvar
    final success = await _repository.updateMembership(
      membershipId: member.uid,
      role: selectedRole,
      isActive: isActive,
      removedBy: !isActive ? SessionManager.instance.currentUser!.uid : null,
    );

    if (success) {
      await DSAlertDialog.showSuccess(
        context: context,
        title: 'Membro Atualizado',
        message: 'As alterações foram salvas.',
      );
      await loadMembers();
    } else {
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro',
        message: 'Não foi possível atualizar o membro.',
      );
    }
  }

  // MARK: - Remover membro

  Future<void> removeMember(
    BuildContext context,
    MembershipModel member,
  ) async {
    // Não pode remover a si mesmo
    if (member.userId == SessionManager.instance.currentUser!.uid) {
      await DSAlertDialog.showWarning(
        context: context,
        title: 'Ação Não Permitida',
        message:
            'Você não pode remover seu próprio acesso. Peça a outro administrador.',
      );
      return;
    }

    // Não pode remover último admin
    if (member.role == UserRole.tenantAdmin) {
      final tenantId = SessionManager.instance.currentTenant!.uid;
      final adminCount = await _repository.countActiveAdmins(tenantId);
      if (adminCount <= 1) {
        await DSAlertDialog.showWarning(
          context: context,
          title: 'Ação Não Permitida',
          message: 'Deve haver pelo menos 1 Administrador na equipe.',
        );
        return;
      }
    }

    // Confirmar
    final confirmed = await DSAlertDialog.showDelete(
      context: context,
      title: 'Confirmar Remoção',
      message: 'Tem certeza que deseja remover este membro da equipe?',
      content: DSAlertContentCard(
        icon: Icons.person_outline,
        color: DSColors().red,
        title: member.userName ?? member.userEmail ?? '',
        subtitle: member.userEmail,
      ),
    );

    if (confirmed != true) return;

    final success = await _repository.removeMember(
      membershipId: member.uid,
      removedBy: SessionManager.instance.currentUser!.uid,
    );

    if (success) {
      await DSAlertDialog.showSuccess(
        context: context,
        title: 'Membro Removido',
        message:
            'O acesso foi removido. O usuário não conseguirá mais logar neste tenant.',
      );
      await loadMembers();
    } else {
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro',
        message: 'Não foi possível remover o membro.',
      );
    }
  }

  // MARK: - Navegar para adicionar membro

  void navigateToAddMember(BuildContext context) {
    Navigator.pushNamed(context, '/team/add').then((result) {
      if (result == true) {
        loadMembers();
      }
    });
  }
}
