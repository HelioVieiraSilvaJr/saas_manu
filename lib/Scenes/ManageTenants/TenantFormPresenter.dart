import 'package:flutter/material.dart';
import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import 'TenantsRepository.dart';

/// Presenter para formulário de criação/edição de Tenant.
class TenantFormPresenter {
  final TenantsRepository _repository = TenantsRepository();

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  // State
  String selectedPlan = 'trial';
  String selectedPlanTier = 'standard';
  bool isActive = true;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  /// Tenant em edição (null = criação).
  TenantModel? editingTenant;

  /// Indica se é edição.
  bool get isEditing => editingTenant != null;

  void Function()? onUpdate;

  void _notify() {
    onUpdate?.call();
  }

  // MARK: - Init

  /// Inicializa para edição com dados do tenant.
  Future<void> initWithTenant(String tenantId) async {
    isLoading = true;
    _notify();

    try {
      final tenant = await _repository.getById(tenantId);
      if (tenant != null) {
        editingTenant = tenant;
        nameController.text = tenant.name;
        emailController.text = tenant.contactEmail;
        phoneController.text = tenant.contactPhone;
        selectedPlan = tenant.plan;
        selectedPlanTier = tenant.planTier;
        isActive = tenant.isActive;
      } else {
        errorMessage = 'Tenant não encontrado.';
      }
    } catch (e) {
      AppLogger.error('Erro ao carregar tenant', error: e);
      errorMessage = 'Erro ao carregar tenant.';
    }

    isLoading = false;
    _notify();
  }

  // MARK: - Setters

  void setPlan(String plan) {
    selectedPlan = plan;
    // Trial não tem tier
    if (plan == 'trial') selectedPlanTier = 'standard';
    _notify();
  }

  void setPlanTier(String tier) {
    selectedPlanTier = tier;
    _notify();
  }

  void setActive(bool value) {
    isActive = value;
    _notify();
  }

  // MARK: - Validation

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Nome deve ter ao menos 3 caracteres';
    }
    if (value.trim().length > 100) {
      return 'Nome deve ter no máximo 100 caracteres';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-mail é obrigatório';
    }
    final pattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }
    return null;
  }

  // MARK: - Save

  /// Salva (cria ou atualiza).
  /// Retorna true se sucesso.
  Future<bool> save(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return false;

    isSaving = true;
    errorMessage = null;
    _notify();

    try {
      if (isEditing) {
        return await _update();
      } else {
        return await _create();
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar tenant', error: e);
      errorMessage = 'Erro ao salvar tenant.';
      isSaving = false;
      _notify();
      return false;
    }
  }

  Future<bool> _create() async {
    final tenantId = await _repository.createTenantWithUser(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      plan: selectedPlan,
      planTier: selectedPlanTier,
      isActive: isActive,
    );

    isSaving = false;
    _notify();

    if (tenantId != null) {
      AppLogger.info('Tenant criado com sucesso: $tenantId');
      return true;
    }

    errorMessage = 'Erro ao criar tenant.';
    _notify();
    return false;
  }

  Future<bool> _update() async {
    final tenant = editingTenant!;
    final updated = TenantModel(
      uid: tenant.uid,
      name: nameController.text.trim(),
      contactEmail: emailController.text.trim(),
      contactPhone: phoneController.text.trim(),
      plan: selectedPlan,
      planTier: selectedPlanTier,
      isActive: isActive,
      isExpired: tenant.isExpired,
      createdAt: tenant.createdAt,
      expirationDate: tenant.expirationDate,
      trialEndDate: tenant.trialEndDate,
      nextPaymentDate: tenant.nextPaymentDate,
      lastPaymentId: tenant.lastPaymentId,
      evolutionApiUrl: tenant.evolutionApiUrl,
      evolutionApiKey: tenant.evolutionApiKey,
      evolutionInstanceName: tenant.evolutionInstanceName,
      webhookToken: tenant.webhookToken,
    );

    final success = await _repository.update(updated);

    isSaving = false;
    _notify();

    if (success) {
      AppLogger.info('Tenant atualizado com sucesso: ${tenant.uid}');
      return true;
    }

    errorMessage = 'Erro ao atualizar tenant.';
    _notify();
    return false;
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }
}
