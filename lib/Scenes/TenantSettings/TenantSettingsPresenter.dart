import 'package:flutter/material.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Commons/Enums/BusinessSegment.dart';
import '../../Commons/Enums/WhatsAppConnectionStatus.dart';
import '../../Commons/Models/TenantModel.dart';
import '../../Sources/SessionManager.dart';
import '../../Sources/BackendApi.dart';
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
  final businessSubsegmentController = TextEditingController();
  final businessDescriptionController = TextEditingController();
  final salesPlaybookController = TextEditingController();
  final toneOfVoiceController = TextEditingController();
  final targetAudienceController = TextEditingController();
  final businessHoursController = TextEditingController();
  final deliveryPoliciesController = TextEditingController();
  final paymentPoliciesController = TextEditingController();
  final exchangePoliciesController = TextEditingController();

  // Controllers — WhatsApp
  final evolutionUrlController = TextEditingController();
  final apiKeyController = TextEditingController();
  final instanceNameController = TextEditingController();

  void _notify() {
    onUpdate?.call();
  }

  String _buildWebhookUrl(TenantModel tenant) {
    final webhookToken = tenant.webhookToken ?? '';
    if (webhookToken.isEmpty) return '';
    return BackendApi.instance.n8nSaleWebhookUrl(
      tenantId: tenant.uid,
      token: webhookToken,
    );
  }

  void _applyTenantToState(
    TenantModel tenant, {
    bool isLoading = false,
    String? managedWhatsAppQrCodeBase64,
  }) {
    final isManagedConnected =
        tenant.whatsappConnectionStatusEnum ==
        WhatsAppConnectionStatus.connected;
    final hasManualConnectionFallback =
        !tenant.hasManagedWhatsAppSetup &&
        (tenant.evolutionApiUrl ?? '').isNotEmpty;

    nameController.text = tenant.name;
    emailController.text = tenant.contactEmail;
    phoneController.text = tenant.contactPhone;
    businessSubsegmentController.text = tenant.businessSubsegment ?? '';
    businessDescriptionController.text = tenant.businessDescription ?? '';
    salesPlaybookController.text = tenant.salesPlaybook ?? '';
    toneOfVoiceController.text = tenant.toneOfVoice ?? '';
    targetAudienceController.text = tenant.targetAudience ?? '';
    businessHoursController.text = tenant.businessHours ?? '';
    deliveryPoliciesController.text = tenant.deliveryPolicies ?? '';
    paymentPoliciesController.text = tenant.paymentPolicies ?? '';
    exchangePoliciesController.text = tenant.exchangePolicies ?? '';
    evolutionUrlController.text = tenant.evolutionApiUrl ?? '';
    apiKeyController.text = tenant.evolutionApiKey ?? '';
    instanceNameController.text = tenant.evolutionInstanceName ?? '';

    viewModel = viewModel.copyWith(
      isLoading: isLoading,
      companyName: tenant.name,
      companyEmail: tenant.contactEmail,
      companyPhone: tenant.contactPhone,
      businessSegment: tenant.businessSegment ?? '',
      businessSubsegment: tenant.businessSubsegment ?? '',
      businessDescription: tenant.businessDescription ?? '',
      salesPlaybook: tenant.salesPlaybook ?? '',
      toneOfVoice: tenant.toneOfVoice ?? '',
      targetAudience: tenant.targetAudience ?? '',
      businessHours: tenant.businessHours ?? '',
      deliveryPolicies: tenant.deliveryPolicies ?? '',
      paymentPolicies: tenant.paymentPolicies ?? '',
      exchangePolicies: tenant.exchangePolicies ?? '',
      evolutionApiUrl: tenant.evolutionApiUrl ?? '',
      evolutionApiKey: tenant.evolutionApiKey ?? '',
      evolutionInstanceName: tenant.evolutionInstanceName ?? '',
      isWhatsAppConnected: isManagedConnected || hasManualConnectionFallback,
      hasManagedWhatsAppSetup: tenant.hasManagedWhatsAppSetup,
      whatsappProvider: tenant.whatsappProviderEnum.label,
      whatsappConnectionStatus: tenant.whatsappConnectionStatusEnum.label,
      whatsappConnectedNumber: tenant.whatsappConnectedNumber ?? '',
      webhookUrl: _buildWebhookUrl(tenant),
      webhookToken: tenant.webhookToken ?? '',
      currentPlan: tenant.plan,
      currentPlanTier: tenant.planTier,
      trialEndDate: tenant.trialEndDate,
      nextPaymentDate: tenant.nextPaymentDate,
      trialDaysRemaining: tenant.trialDaysRemaining,
      isTrialExpired: tenant.isTrialExpired,
      managedWhatsAppQrCodeBase64:
          managedWhatsAppQrCodeBase64 ??
          (tenant.whatsappConnectionStatusEnum ==
                  WhatsAppConnectionStatus.connected
              ? ''
              : viewModel.managedWhatsAppQrCodeBase64),
    );
  }

  Future<TenantModel?> _reloadTenantIntoSession(String tenantId) async {
    final reloaded = await _repository.reloadTenant(tenantId);
    if (reloaded != null) {
      SessionManager.instance.currentTenant = reloaded;
    }
    return reloaded;
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
      _applyTenantToState(t, isLoading: false);
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

  void updateBusinessSegment(BusinessSegment? segment) {
    viewModel = viewModel.copyWith(
      businessSegment: (segment ?? BusinessSegment.unassigned).name,
    );
    _notify();
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
      businessSegment: viewModel.businessSegment.trim(),
      businessSubsegment: businessSubsegmentController.text.trim(),
      businessDescription: businessDescriptionController.text.trim(),
      salesPlaybook: salesPlaybookController.text.trim(),
      toneOfVoice: toneOfVoiceController.text.trim(),
      targetAudience: targetAudienceController.text.trim(),
      businessHours: businessHoursController.text.trim(),
      deliveryPolicies: deliveryPoliciesController.text.trim(),
      paymentPolicies: paymentPoliciesController.text.trim(),
      exchangePolicies: exchangePoliciesController.text.trim(),
    );

    viewModel = viewModel.copyWith(
      isSavingCompany: false,
      successMessage: success ? 'Dados da empresa atualizados.' : null,
      errorMessage: success ? null : 'Erro ao salvar dados.',
    );
    _notify();

    // Recarregar tenant na sessão
    if (success) {
      final reloaded = await _reloadTenantIntoSession(tenantId);
      if (reloaded != null) {
        _applyTenantToState(reloaded);
        _notify();
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
      final reloaded = await _reloadTenantIntoSession(tenantId);
      if (reloaded != null) {
        _applyTenantToState(reloaded);
        _notify();
      }
    }

    return success;
  }

  Future<void> testWhatsAppConnection() async {
    final tenantId = SessionManager.instance.currentTenant?.uid;
    final url = evolutionUrlController.text.trim();
    final key = apiKeyController.text.trim();
    final instance = instanceNameController.text.trim();

    if (tenantId == null || url.isEmpty || key.isEmpty || instance.isEmpty) {
      viewModel = viewModel.copyWith(
        errorMessage: 'Preencha todos os campos antes de testar.',
      );
      _notify();
      return;
    }

    viewModel = viewModel.copyWith(isTestingConnection: true);
    _notify();

    final result = await _repository.testWhatsAppConnection(
      tenantId: tenantId,
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

  Future<void> provisionManagedWhatsApp() async {
    final tenant = SessionManager.instance.currentTenant;
    if (tenant == null) return;

    viewModel = viewModel.copyWith(
      isProvisioningManagedWhatsApp: true,
      errorMessage: null,
      successMessage: null,
    );
    _notify();

    final result = await _repository.provisionManagedWhatsApp(
      tenantId: tenant.uid,
    );

    final qrCodeBase64 = (result['qrCodeBase64'] ?? '').toString().trim();
    final reloaded = await _reloadTenantIntoSession(tenant.uid);
    if (reloaded != null) {
      _applyTenantToState(reloaded, managedWhatsAppQrCodeBase64: qrCodeBase64);
    }

    viewModel = viewModel.copyWith(
      isProvisioningManagedWhatsApp: false,
      hasManagedWhatsAppSetup:
          result['ok'] == true || viewModel.hasManagedWhatsAppSetup,
      successMessage: result['ok'] == true
          ? (viewModel.isWhatsAppConnected
                ? 'WhatsApp conectado com sucesso.'
                : 'QR Code gerado. Escaneie com o WhatsApp para conectar.')
          : null,
      errorMessage: result['ok'] == true
          ? null
          : (result['message'] ??
                    result['error'] ??
                    'Não foi possível iniciar a conexão.')
                .toString(),
    );
    _notify();
  }

  Future<void> refreshManagedWhatsAppStatus({
    bool includeQrCode = false,
    bool silent = false,
  }) async {
    final tenant = SessionManager.instance.currentTenant;
    if (tenant == null) return;

    viewModel = viewModel.copyWith(
      isRefreshingManagedWhatsApp: true,
      errorMessage: silent ? viewModel.errorMessage : null,
      successMessage: silent ? viewModel.successMessage : null,
    );
    _notify();

    final result = await _repository.getManagedWhatsAppStatus(
      tenantId: tenant.uid,
      includeQrCode: includeQrCode,
    );

    final qrCodeBase64 = (result['qrCodeBase64'] ?? '').toString().trim();
    final reloaded = await _reloadTenantIntoSession(tenant.uid);
    if (reloaded != null) {
      _applyTenantToState(reloaded, managedWhatsAppQrCodeBase64: qrCodeBase64);
    }

    final isOk = result['ok'] == true;
    viewModel = viewModel.copyWith(
      isRefreshingManagedWhatsApp: false,
      successMessage: !silent && isOk
          ? (viewModel.isWhatsAppConnected
                ? 'WhatsApp conectado e pronto para atendimento.'
                : 'Status do WhatsApp atualizado.')
          : null,
      errorMessage: !silent && !isOk
          ? (result['message'] ??
                    result['error'] ??
                    'Não foi possível atualizar o status.')
                .toString()
          : null,
    );
    _notify();
  }

  Future<void> disconnectManagedWhatsApp() async {
    final tenant = SessionManager.instance.currentTenant;
    if (tenant == null) return;

    viewModel = viewModel.copyWith(
      isDisconnectingManagedWhatsApp: true,
      errorMessage: null,
      successMessage: null,
    );
    _notify();

    final result = await _repository.disconnectManagedWhatsApp(
      tenantId: tenant.uid,
    );

    final reloaded = await _reloadTenantIntoSession(tenant.uid);
    if (reloaded != null) {
      _applyTenantToState(reloaded, managedWhatsAppQrCodeBase64: '');
    }

    viewModel = viewModel.copyWith(
      isDisconnectingManagedWhatsApp: false,
      managedWhatsAppQrCodeBase64: '',
      successMessage: result['ok'] == true
          ? 'Numero desconectado. Voce ja pode conectar outro WhatsApp.'
          : null,
      errorMessage: result['ok'] == true
          ? null
          : (result['message'] ??
                    result['error'] ??
                    'Nao foi possivel desconectar o WhatsApp.')
                .toString(),
    );
    _notify();
  }

  // MARK: - Webhook

  Future<String> generateWebhookUrl() async {
    final tenantId = SessionManager.instance.currentTenant?.uid;
    if (tenantId == null) return '';

    final token = await _repository.generateWebhookToken(tenantId);
    if (token == null) return '';

    final url = BackendApi.instance.n8nSaleWebhookUrl(
      tenantId: tenantId,
      token: token,
    );

    viewModel = viewModel.copyWith(webhookUrl: url, webhookToken: token);
    _notify();

    final reloaded = await _reloadTenantIntoSession(tenantId);
    if (reloaded != null) {
      _applyTenantToState(reloaded);
      _notify();
    }

    return url;
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    businessSubsegmentController.dispose();
    businessDescriptionController.dispose();
    salesPlaybookController.dispose();
    toneOfVoiceController.dispose();
    targetAudienceController.dispose();
    businessHoursController.dispose();
    deliveryPoliciesController.dispose();
    paymentPoliciesController.dispose();
    exchangePoliciesController.dispose();
    evolutionUrlController.dispose();
    apiKeyController.dispose();
    instanceNameController.dispose();
  }
}
