/// ViewModel para Configurações do Tenant — Módulo 8.
class TenantSettingsViewModel {
  final bool isLoading;
  final bool isSavingCompany;
  final bool isSavingWhatsApp;
  final bool isTestingConnection;
  final bool isProvisioningManagedWhatsApp;
  final bool isRefreshingManagedWhatsApp;
  final bool isDisconnectingManagedWhatsApp;
  final String? errorMessage;
  final String? successMessage;

  // Dados da empresa
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String businessSegment;
  final String businessSubsegment;
  final String businessDescription;
  final String salesPlaybook;
  final String toneOfVoice;
  final String targetAudience;
  final String businessHours;
  final String deliveryPolicies;
  final String paymentPolicies;
  final String exchangePolicies;

  // WhatsApp / Evolution API
  final String evolutionApiUrl;
  final String evolutionApiKey;
  final String evolutionInstanceName;
  final bool isWhatsAppConnected;
  final bool hasManagedWhatsAppSetup;
  final String whatsappProvider;
  final String whatsappConnectionStatus;
  final String whatsappConnectedNumber;
  final String managedWhatsAppQrCodeBase64;

  // Webhook
  final String webhookUrl;
  final String webhookToken;

  // Plano
  final String currentPlan;
  final String currentPlanTier;
  final DateTime? trialEndDate;
  final DateTime? nextPaymentDate;
  final int trialDaysRemaining;
  final bool isTrialExpired;

  const TenantSettingsViewModel({
    this.isLoading = false,
    this.isSavingCompany = false,
    this.isSavingWhatsApp = false,
    this.isTestingConnection = false,
    this.isProvisioningManagedWhatsApp = false,
    this.isRefreshingManagedWhatsApp = false,
    this.isDisconnectingManagedWhatsApp = false,
    this.errorMessage,
    this.successMessage,
    this.companyName = '',
    this.companyEmail = '',
    this.companyPhone = '',
    this.businessSegment = '',
    this.businessSubsegment = '',
    this.businessDescription = '',
    this.salesPlaybook = '',
    this.toneOfVoice = '',
    this.targetAudience = '',
    this.businessHours = '',
    this.deliveryPolicies = '',
    this.paymentPolicies = '',
    this.exchangePolicies = '',
    this.evolutionApiUrl = '',
    this.evolutionApiKey = '',
    this.evolutionInstanceName = '',
    this.isWhatsAppConnected = false,
    this.hasManagedWhatsAppSetup = false,
    this.whatsappProvider = '',
    this.whatsappConnectionStatus = '',
    this.whatsappConnectedNumber = '',
    this.managedWhatsAppQrCodeBase64 = '',
    this.webhookUrl = '',
    this.webhookToken = '',
    this.currentPlan = 'trial',
    this.currentPlanTier = 'standard',
    this.trialEndDate,
    this.nextPaymentDate,
    this.trialDaysRemaining = 0,
    this.isTrialExpired = false,
  });

  TenantSettingsViewModel copyWith({
    bool? isLoading,
    bool? isSavingCompany,
    bool? isSavingWhatsApp,
    bool? isTestingConnection,
    bool? isProvisioningManagedWhatsApp,
    bool? isRefreshingManagedWhatsApp,
    bool? isDisconnectingManagedWhatsApp,
    String? errorMessage,
    String? successMessage,
    String? companyName,
    String? companyEmail,
    String? companyPhone,
    String? businessSegment,
    String? businessSubsegment,
    String? businessDescription,
    String? salesPlaybook,
    String? toneOfVoice,
    String? targetAudience,
    String? businessHours,
    String? deliveryPolicies,
    String? paymentPolicies,
    String? exchangePolicies,
    String? evolutionApiUrl,
    String? evolutionApiKey,
    String? evolutionInstanceName,
    bool? isWhatsAppConnected,
    bool? hasManagedWhatsAppSetup,
    String? whatsappProvider,
    String? whatsappConnectionStatus,
    String? whatsappConnectedNumber,
    String? managedWhatsAppQrCodeBase64,
    String? webhookUrl,
    String? webhookToken,
    String? currentPlan,
    String? currentPlanTier,
    DateTime? trialEndDate,
    DateTime? nextPaymentDate,
    int? trialDaysRemaining,
    bool? isTrialExpired,
  }) {
    return TenantSettingsViewModel(
      isLoading: isLoading ?? this.isLoading,
      isSavingCompany: isSavingCompany ?? this.isSavingCompany,
      isSavingWhatsApp: isSavingWhatsApp ?? this.isSavingWhatsApp,
      isTestingConnection: isTestingConnection ?? this.isTestingConnection,
      isProvisioningManagedWhatsApp:
          isProvisioningManagedWhatsApp ?? this.isProvisioningManagedWhatsApp,
      isRefreshingManagedWhatsApp:
          isRefreshingManagedWhatsApp ?? this.isRefreshingManagedWhatsApp,
      isDisconnectingManagedWhatsApp:
          isDisconnectingManagedWhatsApp ?? this.isDisconnectingManagedWhatsApp,
      errorMessage: errorMessage,
      successMessage: successMessage,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      businessSegment: businessSegment ?? this.businessSegment,
      businessSubsegment: businessSubsegment ?? this.businessSubsegment,
      businessDescription: businessDescription ?? this.businessDescription,
      salesPlaybook: salesPlaybook ?? this.salesPlaybook,
      toneOfVoice: toneOfVoice ?? this.toneOfVoice,
      targetAudience: targetAudience ?? this.targetAudience,
      businessHours: businessHours ?? this.businessHours,
      deliveryPolicies: deliveryPolicies ?? this.deliveryPolicies,
      paymentPolicies: paymentPolicies ?? this.paymentPolicies,
      exchangePolicies: exchangePolicies ?? this.exchangePolicies,
      evolutionApiUrl: evolutionApiUrl ?? this.evolutionApiUrl,
      evolutionApiKey: evolutionApiKey ?? this.evolutionApiKey,
      evolutionInstanceName:
          evolutionInstanceName ?? this.evolutionInstanceName,
      isWhatsAppConnected: isWhatsAppConnected ?? this.isWhatsAppConnected,
      hasManagedWhatsAppSetup:
          hasManagedWhatsAppSetup ?? this.hasManagedWhatsAppSetup,
      whatsappProvider: whatsappProvider ?? this.whatsappProvider,
      whatsappConnectionStatus:
          whatsappConnectionStatus ?? this.whatsappConnectionStatus,
      whatsappConnectedNumber:
          whatsappConnectedNumber ?? this.whatsappConnectedNumber,
      managedWhatsAppQrCodeBase64:
          managedWhatsAppQrCodeBase64 ?? this.managedWhatsAppQrCodeBase64,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      webhookToken: webhookToken ?? this.webhookToken,
      currentPlan: currentPlan ?? this.currentPlan,
      currentPlanTier: currentPlanTier ?? this.currentPlanTier,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      isTrialExpired: isTrialExpired ?? this.isTrialExpired,
    );
  }

  // Helpers

  bool get isTrial => currentPlan == 'trial';

  String get planLabel {
    if (isTrial) return 'Trial';
    final period = currentPlan == 'quarterly' ? 'Trimestral' : 'Mensal';
    final tier = currentPlanTier == 'pro' ? ' Pro' : '';
    return '$period$tier';
  }

  bool get hasEvolutionConfig =>
      evolutionApiUrl.isNotEmpty &&
      evolutionApiKey.isNotEmpty &&
      evolutionInstanceName.isNotEmpty;
}
