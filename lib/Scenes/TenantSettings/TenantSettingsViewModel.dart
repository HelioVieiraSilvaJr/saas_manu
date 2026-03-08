/// ViewModel para Configurações do Tenant — Módulo 8.
class TenantSettingsViewModel {
  final bool isLoading;
  final bool isSavingCompany;
  final bool isSavingWhatsApp;
  final bool isTestingConnection;
  final String? errorMessage;
  final String? successMessage;

  // Dados da empresa
  final String companyName;
  final String companyEmail;
  final String companyPhone;

  // WhatsApp / Evolution API
  final String evolutionApiUrl;
  final String evolutionApiKey;
  final String evolutionInstanceName;
  final bool isWhatsAppConnected;

  // Webhook
  final String webhookUrl;
  final String webhookToken;

  // Plano
  final String currentPlan;
  final DateTime? trialEndDate;
  final DateTime? nextPaymentDate;
  final int trialDaysRemaining;
  final bool isTrialExpired;

  const TenantSettingsViewModel({
    this.isLoading = false,
    this.isSavingCompany = false,
    this.isSavingWhatsApp = false,
    this.isTestingConnection = false,
    this.errorMessage,
    this.successMessage,
    this.companyName = '',
    this.companyEmail = '',
    this.companyPhone = '',
    this.evolutionApiUrl = '',
    this.evolutionApiKey = '',
    this.evolutionInstanceName = '',
    this.isWhatsAppConnected = false,
    this.webhookUrl = '',
    this.webhookToken = '',
    this.currentPlan = 'trial',
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
    String? errorMessage,
    String? successMessage,
    String? companyName,
    String? companyEmail,
    String? companyPhone,
    String? evolutionApiUrl,
    String? evolutionApiKey,
    String? evolutionInstanceName,
    bool? isWhatsAppConnected,
    String? webhookUrl,
    String? webhookToken,
    String? currentPlan,
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
      errorMessage: errorMessage,
      successMessage: successMessage,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      evolutionApiUrl: evolutionApiUrl ?? this.evolutionApiUrl,
      evolutionApiKey: evolutionApiKey ?? this.evolutionApiKey,
      evolutionInstanceName:
          evolutionInstanceName ?? this.evolutionInstanceName,
      isWhatsAppConnected: isWhatsAppConnected ?? this.isWhatsAppConnected,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      webhookToken: webhookToken ?? this.webhookToken,
      currentPlan: currentPlan ?? this.currentPlan,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      isTrialExpired: isTrialExpired ?? this.isTrialExpired,
    );
  }

  // Helpers

  bool get isTrial => currentPlan == 'trial';

  String get planLabel {
    switch (currentPlan) {
      case 'trial':
        return 'Trial';
      case 'basic':
        return 'Basic';
      case 'full':
        return 'Full';
      default:
        return currentPlan;
    }
  }

  bool get hasEvolutionConfig =>
      evolutionApiUrl.isNotEmpty &&
      evolutionApiKey.isNotEmpty &&
      evolutionInstanceName.isNotEmpty;
}
