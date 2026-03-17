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

    isAdding = true;
    _notify();

    try {
      final provision = await _repository.provisionMember(
        email: email,
        name: name,
        tenantId: tenantId,
        role: selectedRole,
      );
      final success = provision?['ok'] == true;
      final isNewUser = provision?['isNewUser'] == true;
      final temporaryPassword = provision?['temporaryPassword'] as String?;

      isAdding = false;
      _notify();

      if (success) {
        await DSAlertDialog.showSuccess(
          context: context,
          title: 'Membro Adicionado!',
          message: isNewUser
              ? temporaryPassword != null && temporaryPassword.isNotEmpty
                    ? 'Usuário criado com senha temporária: $temporaryPassword'
                    : 'Usuário criado com sucesso e provisionado no backend.'
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
