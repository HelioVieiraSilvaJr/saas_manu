import 'package:flutter/material.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/SessionManager.dart';
import 'TenantSettingsRepository.dart';
import 'TenantSettingsViewModel.dart';

/// Presenter para Configurações do Tenant — Módulo 8.
class TenantSettingsPresenter {
  final TenantSettingsRepository _repository = TenantSettingsRepository();
  TenantSettingsViewModel viewModel = const TenantSettingsViewModel();
  void Function()? onUpdate;

  // Controllers — Dados da Empresa
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  // Controllers — WhatsApp
  final evolutionUrlController = TextEditingController();
  final apiKeyController = TextEditingController();
  final instanceNameController = TextEditingController();

  void _notify() {
    onUpdate?.call();
  }

  // MARK: - Load

  Future<void> loadSettings() async {
    viewModel = viewModel.copyWith(isLoading: true);
    _notify();

    try {
      final tenant = SessionManager.instance.currentTenant;
      if (tenant == null) {
        viewModel = viewModel.copyWith(
          isLoading: false,
          errorMessage: 'Tenant não encontrado na sessão.',
        );
        _notify();
        return;
      }

      // Recarregar do Firestore
      final reloaded = await _repository.reloadTenant(tenant.uid);
      final t = reloaded ?? tenant;

      // Preencher controllers
      nameController.text = t.name;
      emailController.text = t.contactEmail;
      phoneController.text = t.contactPhone;
      evolutionUrlController.text = t.evolutionApiUrl ?? '';
      apiKeyController.text = t.evolutionApiKey ?? '';
      instanceNameController.text = t.evolutionInstanceName ?? '';

      // Webhook URL
      final webhookToken = t.webhookToken ?? '';
      final webhookUrl = webhookToken.isNotEmpty
          ? 'https://us-central1-PROJECT_ID.cloudfunctions.net/receiveN8nSale?tenantId=${t.uid}&token=$webhookToken'
          : '';

      viewModel = viewModel.copyWith(
        isLoading: false,
        companyName: t.name,
        companyEmail: t.contactEmail,
        companyPhone: t.contactPhone,
        evolutionApiUrl: t.evolutionApiUrl ?? '',
        evolutionApiKey: t.evolutionApiKey ?? '',
        evolutionInstanceName: t.evolutionInstanceName ?? '',
        isWhatsAppConnected: (t.evolutionApiUrl ?? '').isNotEmpty,
        webhookUrl: webhookUrl,
        webhookToken: webhookToken,
        currentPlan: t.plan,
        trialEndDate: t.trialEndDate,
        nextPaymentDate: t.nextPaymentDate,
        trialDaysRemaining: t.trialDaysRemaining,
        isTrialExpired: t.isTrialExpired,
      );
      _notify();
    } catch (e) {
      AppLogger.error('Erro ao carregar configurações', error: e);
      viewModel = viewModel.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar configurações.',
      );
      _notify();
    }
  }

  // MARK: - Salvar Dados da Empresa

  String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Nome deve ter ao menos 3 caracteres';
    }
    return null;
  }

  String? validateCompanyEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-mail é obrigatório';
    }
    final pattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? validateCompanyPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }
    return null;
  }

  Future<bool> saveCompanyData(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return false;

    final tenantId = SessionManager.instance.currentTenant?.uid;
    if (tenantId == null) return false;

    viewModel = viewModel.copyWith(isSavingCompany: true);
    _notify();

    final success = await _repository.updateCompanyData(
      tenantId: tenantId,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
    );

    viewModel = viewModel.copyWith(
      isSavingCompany: false,
      successMessage: success ? 'Dados da empresa atualizados.' : null,
      errorMessage: success ? null : 'Erro ao salvar dados.',
    );
    _notify();

    // Recarregar tenant na sessão
    if (success) {
      final reloaded = await _repository.reloadTenant(tenantId);
      if (reloaded != null) {
        SessionManager.instance.currentTenant = reloaded;
      }
    }

    return success;
  }

  // MARK: - WhatsApp

  Future<bool> saveWhatsAppConfig() async {
    final tenantId = SessionManager.instance.currentTenant?.uid;
    if (tenantId == null) return false;

    final url = evolutionUrlController.text.trim();
    final key = apiKeyController.text.trim();
    final instance = instanceNameController.text.trim();

    if (url.isEmpty || key.isEmpty || instance.isEmpty) {
      viewModel = viewModel.copyWith(
        errorMessage: 'Preencha todos os campos do WhatsApp.',
      );
      _notify();
      return false;
    }

    viewModel = viewModel.copyWith(isSavingWhatsApp: true);
    _notify();

    final success = await _repository.saveWhatsAppConfig(
      tenantId: tenantId,
      evolutionApiUrl: url,
      apiKey: key,
      instanceName: instance,
    );

    viewModel = viewModel.copyWith(
      isSavingWhatsApp: false,
      successMessage: success ? 'Configurações do WhatsApp salvas.' : null,
      errorMessage: success ? null : 'Erro ao salvar configurações.',
    );
    _notify();

    if (success) {
      final reloaded = await _repository.reloadTenant(tenantId);
      if (reloaded != null) {
        SessionManager.instance.currentTenant = reloaded;
      }
    }

    return success;
  }

  Future<void> testWhatsAppConnection() async {
    final url = evolutionUrlController.text.trim();
    final key = apiKeyController.text.trim();
    final instance = instanceNameController.text.trim();

    if (url.isEmpty || key.isEmpty || instance.isEmpty) {
      viewModel = viewModel.copyWith(
        errorMessage: 'Preencha todos os campos antes de testar.',
      );
      _notify();
      return;
    }

    viewModel = viewModel.copyWith(isTestingConnection: true);
    _notify();

    final result = await _repository.testWhatsAppConnection(
      evolutionApiUrl: url,
      apiKey: key,
      instanceName: instance,
    );

    viewModel = viewModel.copyWith(
      isTestingConnection: false,
      isWhatsAppConnected: result['success'] == true,
      successMessage: result['success'] == true ? result['message'] : null,
      errorMessage: result['success'] != true ? result['message'] : null,
    );
    _notify();
  }

  // MARK: - Webhook

  Future<String> generateWebhookUrl() async {
    final tenantId = SessionManager.instance.currentTenant?.uid;
    if (tenantId == null) return '';

    final token = await _repository.generateWebhookToken(tenantId);
    if (token == null) return '';

    final url =
        'https://us-central1-PROJECT_ID.cloudfunctions.net/receiveN8nSale?tenantId=$tenantId&token=$token';

    viewModel = viewModel.copyWith(webhookUrl: url, webhookToken: token);
    _notify();

    return url;
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    evolutionUrlController.dispose();
    apiKeyController.dispose();
    instanceNameController.dispose();
  }
}
