import 'package:flutter/material.dart';
import '../../Commons/Enums/UserRole.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Widgets/DesignSystem/DSAlertDialog.dart';
import '../../Sources/SessionManager.dart';
import 'TeamManagementRepository.dart';

/// Presenter para Adicionar Membro — Módulo 9.
class AddMemberPresenter {
  final TeamManagementRepository _repository = TeamManagementRepository();

  final emailController = TextEditingController();
  final nameController = TextEditingController();
  UserRole selectedRole = UserRole.user;
  bool isAdding = false;

  void Function()? onUpdate;

  void _notify() {
    onUpdate?.call();
  }

  // Validações

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-mail é obrigatório';
    }
    final pattern = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Nome deve ter ao menos 3 caracteres';
    }
    return null;
  }

  // Alterar role

  void setRole(UserRole role) {
    selectedRole = role;
    _notify();
  }

  // Adicionar membro

  Future<void> addMember(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) async {
    if (!formKey.currentState!.validate()) return;

    final email = emailController.text.trim().toLowerCase();
    final name = nameController.text.trim();
    final tenantId = SessionManager.instance.currentTenant!.uid;
    final addedBy = SessionManager.instance.currentUser!.uid;

    isAdding = true;
    _notify();

    try {
      // 1. Verificar se usuário já existe na plataforma
      final existingUser = await _repository.findUserByEmail(email);

      String userId;
      bool isNewUser = false;

      if (existingUser == null) {
        // CASO 1: Usuário não existe — criar novo
        isNewUser = true;
        final createdUid = await _repository.createUser(
          email: email,
          name: name,
        );

        if (createdUid == null) {
          isAdding = false;
          _notify();
          await DSAlertDialog.showError(
            context: context,
            title: 'Erro ao Criar Usuário',
            message:
                'Não foi possível criar o usuário. Verifique se o e-mail já está em uso.',
          );
          return;
        }

        userId = createdUid;
      } else {
        // CASO 2: Usuário já existe
        userId = existingUser['uid'] as String;

        // Verificar se já é membro ativo deste tenant
        final existingMembership = await _repository.findMembership(
          userId,
          tenantId,
        );
        if (existingMembership != null) {
          isAdding = false;
          _notify();
          await DSAlertDialog.showWarning(
            context: context,
            title: 'Usuário Já é Membro',
            message:
                '${existingUser['name'] ?? email} já faz parte desta equipe.',
          );
          return;
        }
      }

      // 2. Criar membership
      final success = await _repository.createMembership(
        userId: userId,
        tenantId: tenantId,
        role: selectedRole,
        userName: name,
        userEmail: email,
        addedBy: addedBy,
      );

      isAdding = false;
      _notify();

      if (success) {
        await DSAlertDialog.showSuccess(
          context: context,
          title: 'Membro Adicionado!',
          message: isNewUser
              ? 'Usuário criado com senha padrão (1234567).'
              : '$name foi adicionado à equipe.',
        );

        if (context.mounted) {
          Navigator.pop(context, true);
        }
      } else {
        await DSAlertDialog.showError(
          context: context,
          title: 'Erro ao Adicionar',
          message: 'Não foi possível adicionar o membro.',
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao adicionar membro', error: e);
      isAdding = false;
      _notify();
      await DSAlertDialog.showError(
        context: context,
        title: 'Erro ao Adicionar',
        message: 'Não foi possível adicionar o membro.',
      );
    }
  }

  void dispose() {
    emailController.dispose();
    nameController.dispose();
  }
}
