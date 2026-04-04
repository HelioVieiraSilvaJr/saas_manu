import 'package:cloud_firestore/cloud_firestore.dart';
import '../Enums/BusinessSegment.dart';
import '../Enums/PlanPeriod.dart';
import '../Enums/PlanTier.dart';
import '../Enums/WhatsAppConnectionStatus.dart';
import '../Enums/WhatsAppProvider.dart';

/// Modelo de tenant (organização/empresa).
///
/// Coleção global: `tenants/{tenant_id}`
class TenantModel {
  String uid;
  String name;
  String contactEmail;
  String contactPhone;
  String plan; // 'trial' | 'monthly' | 'quarterly'
  String planTier; // 'standard' | 'pro'
  bool isActive;
  bool isExpired; // Flag para o agente n8n validar rapidamente
  DateTime createdAt;
  DateTime? expirationDate; // Data de expiração genérica (qualquer plano)
  DateTime? trialEndDate; // Mantido para compatibilidade
  DateTime? nextPaymentDate;
  String? lastPaymentId; // ID do último pagamento (subcollection payments/)

  // Contexto comercial
  String? businessSegment;
  String? businessSubsegment;
  String? businessDescription;
  String? salesPlaybook;
  String? toneOfVoice;
  String? targetAudience;
  String? businessHours;
  String? deliveryPolicies;
  String? paymentPolicies;
  String? exchangePolicies;

  // Integrações
  String? evolutionApiUrl;
  String? evolutionApiKey;
  String? evolutionInstanceName;
  String? webhookToken;
  String? whatsappProvider;
  String? whatsappInstanceId;
  String? whatsappConnectionStatus;
  String? whatsappConnectedNumber;
  String? whatsappWebhookUrl;
  DateTime? whatsappLastSeenAt;
  DateTime? whatsappQrExpiresAt;
  int aiSalesProfileVersion;

  TenantModel({
    required this.uid,
    required this.name,
    required this.contactEmail,
    required this.contactPhone,
    required this.plan,
    this.planTier = 'standard',
    required this.isActive,
    this.isExpired = false,
    required this.createdAt,
    this.expirationDate,
    this.trialEndDate,
    this.nextPaymentDate,
    this.lastPaymentId,
    this.businessSegment,
    this.businessSubsegment,
    this.businessDescription,
    this.salesPlaybook,
    this.toneOfVoice,
    this.targetAudience,
    this.businessHours,
    this.deliveryPolicies,
    this.paymentPolicies,
    this.exchangePolicies,
    this.evolutionApiUrl,
    this.evolutionApiKey,
    this.evolutionInstanceName,
    this.webhookToken,
    this.whatsappProvider,
    this.whatsappInstanceId,
    this.whatsappConnectionStatus,
    this.whatsappConnectedNumber,
    this.whatsappWebhookUrl,
    this.whatsappLastSeenAt,
    this.whatsappQrExpiresAt,
    this.aiSalesProfileVersion = 1,
  });

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  // MARK: - Factory

  static TenantModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TenantModel(
      uid: doc.id,
      name: _asString(data['name']),
      contactEmail: _asString(data['contact_email']),
      contactPhone: _asString(data['contact_phone']),
      plan: _asString(data['plan'], fallback: 'trial'),
      planTier: _asString(data['plan_tier'], fallback: 'standard'),
      isActive: data['is_active'] ?? true,
      isExpired: data['is_expired'] ?? false,
      createdAt: _asDateTime(data['created_at']) ?? DateTime.now(),
      expirationDate: _asDateTime(data['expiration_date']),
      trialEndDate: _asDateTime(data['trial_end_date']),
      nextPaymentDate: _asDateTime(data['next_payment_date']),
      lastPaymentId: _asNullableString(data['last_payment_id']),
      businessSegment: _asNullableString(data['business_segment']),
      businessSubsegment: _asNullableString(data['business_subsegment']),
      businessDescription: _asNullableString(data['business_description']),
      salesPlaybook: _asNullableString(data['sales_playbook']),
      toneOfVoice: _asNullableString(data['tone_of_voice']),
      targetAudience: _asNullableString(data['target_audience']),
      businessHours: _asNullableString(data['business_hours']),
      deliveryPolicies: _asNullableString(data['delivery_policies']),
      paymentPolicies: _asNullableString(data['payment_policies']),
      exchangePolicies: _asNullableString(data['exchange_policies']),
      evolutionApiUrl: _asNullableString(data['evolution_api_url']),
      evolutionApiKey: _asNullableString(data['evolution_api_key']),
      evolutionInstanceName: _asNullableString(data['evolution_instance_name']),
      webhookToken: _asNullableString(data['webhook_token']),
      whatsappProvider: _asNullableString(data['whatsapp_provider']),
      whatsappInstanceId: _asNullableString(data['whatsapp_instance_id']),
      whatsappConnectionStatus: _asNullableString(
        data['whatsapp_connection_status'],
      ),
      whatsappConnectedNumber: _asNullableString(
        data['whatsapp_connected_number'],
      ),
      whatsappWebhookUrl: _asNullableString(data['whatsapp_webhook_url']),
      whatsappLastSeenAt: _asDateTime(data['whatsapp_last_seen_at']),
      whatsappQrExpiresAt: _asDateTime(data['whatsapp_qr_expires_at']),
      aiSalesProfileVersion: _asInt(
        data['ai_sales_profile_version'],
        fallback: 1,
      ),
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'plan': plan,
      'plan_tier': planTier,
      'is_active': isActive,
      'is_expired': isExpired,
      'created_at': Timestamp.fromDate(createdAt),
      'expiration_date': expirationDate != null
          ? Timestamp.fromDate(expirationDate!)
          : null,
      'trial_end_date': trialEndDate != null
          ? Timestamp.fromDate(trialEndDate!)
          : null,
      'next_payment_date': nextPaymentDate != null
          ? Timestamp.fromDate(nextPaymentDate!)
          : null,
      'last_payment_id': lastPaymentId,
      'business_segment': businessSegment,
      'business_subsegment': businessSubsegment,
      'business_description': businessDescription,
      'sales_playbook': salesPlaybook,
      'tone_of_voice': toneOfVoice,
      'target_audience': targetAudience,
      'business_hours': businessHours,
      'delivery_policies': deliveryPolicies,
      'payment_policies': paymentPolicies,
      'exchange_policies': exchangePolicies,
      'evolution_api_url': evolutionApiUrl,
      'evolution_api_key': evolutionApiKey,
      'evolution_instance_name': evolutionInstanceName,
      'webhook_token': webhookToken,
      'whatsapp_provider': whatsappProvider,
      'whatsapp_instance_id': whatsappInstanceId,
      'whatsapp_connection_status': whatsappConnectionStatus,
      'whatsapp_connected_number': whatsappConnectedNumber,
      'whatsapp_webhook_url': whatsappWebhookUrl,
      'whatsapp_last_seen_at': whatsappLastSeenAt != null
          ? Timestamp.fromDate(whatsappLastSeenAt!)
          : null,
      'whatsapp_qr_expires_at': whatsappQrExpiresAt != null
          ? Timestamp.fromDate(whatsappQrExpiresAt!)
          : null,
      'ai_sales_profile_version': aiSalesProfileVersion,
    };
  }

  // MARK: - Helpers

  static TenantModel newModel() {
    final now = DateTime.now();
    return TenantModel(
      uid: '',
      name: '',
      contactEmail: '',
      contactPhone: '',
      plan: 'trial',
      planTier: 'standard',
      isActive: true,
      isExpired: false,
      createdAt: now,
      expirationDate: now.add(const Duration(days: 30)),
      trialEndDate: now.add(const Duration(days: 30)),
    );
  }

  TenantModel copyWith({
    String? uid,
    String? name,
    String? contactEmail,
    String? contactPhone,
    String? plan,
    String? planTier,
    bool? isActive,
    bool? isExpired,
    DateTime? createdAt,
    DateTime? expirationDate,
    DateTime? trialEndDate,
    DateTime? nextPaymentDate,
    String? lastPaymentId,
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
    String? webhookToken,
    String? whatsappProvider,
    String? whatsappInstanceId,
    String? whatsappConnectionStatus,
    String? whatsappConnectedNumber,
    String? whatsappWebhookUrl,
    DateTime? whatsappLastSeenAt,
    DateTime? whatsappQrExpiresAt,
    int? aiSalesProfileVersion,
  }) {
    return TenantModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      plan: plan ?? this.plan,
      planTier: planTier ?? this.planTier,
      isActive: isActive ?? this.isActive,
      isExpired: isExpired ?? this.isExpired,
      createdAt: createdAt ?? this.createdAt,
      expirationDate: expirationDate ?? this.expirationDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      lastPaymentId: lastPaymentId ?? this.lastPaymentId,
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
      webhookToken: webhookToken ?? this.webhookToken,
      whatsappProvider: whatsappProvider ?? this.whatsappProvider,
      whatsappInstanceId: whatsappInstanceId ?? this.whatsappInstanceId,
      whatsappConnectionStatus:
          whatsappConnectionStatus ?? this.whatsappConnectionStatus,
      whatsappConnectedNumber:
          whatsappConnectedNumber ?? this.whatsappConnectedNumber,
      whatsappWebhookUrl: whatsappWebhookUrl ?? this.whatsappWebhookUrl,
      whatsappLastSeenAt: whatsappLastSeenAt ?? this.whatsappLastSeenAt,
      whatsappQrExpiresAt: whatsappQrExpiresAt ?? this.whatsappQrExpiresAt,
      aiSalesProfileVersion:
          aiSalesProfileVersion ?? this.aiSalesProfileVersion,
    );
  }

  // MARK: - Plan Helpers

  /// Enum tipado do período.
  PlanPeriod get planPeriod => PlanPeriod.fromString(plan);

  /// Enum tipado do tier.
  PlanTier get planTierEnum => PlanTier.fromString(planTier);

  /// Segmento de negocio normalizado para uso da IA.
  BusinessSegment get businessSegmentEnum =>
      BusinessSegment.fromString(businessSegment);

  /// Provider do WhatsApp normalizado.
  WhatsAppProvider get whatsappProviderEnum =>
      WhatsAppProvider.fromString(whatsappProvider);

  /// Status atual da conexao do WhatsApp.
  WhatsAppConnectionStatus get whatsappConnectionStatusEnum =>
      WhatsAppConnectionStatus.fromString(whatsappConnectionStatus);

  /// Verifica se o tenant está em período trial.
  bool get isTrial => plan == 'trial';

  /// Verifica se é plano pago.
  bool get isPaidPlan => plan == 'monthly' || plan == 'quarterly';

  /// Indica se o tenant ja tem uma integracao gerenciada preparada.
  bool get hasManagedWhatsAppSetup =>
      whatsappProviderEnum != WhatsAppProvider.unknown ||
      (whatsappInstanceId?.isNotEmpty ?? false) ||
      (whatsappConnectionStatus?.isNotEmpty ?? false);

  /// Label combinado do plano. Ex: "Mensal Pro", "Trial", "Trimestral Standard"
  String get planLabel {
    if (isTrial) return 'Trial';
    final periodLabel = planPeriod.label;
    final tierLabel = planTierEnum.label;
    return '$periodLabel $tierLabel';
  }

  /// Dias restantes do trial (-1 se não for trial).
  int get trialDaysRemaining {
    if (!isTrial || trialEndDate == null) return -1;
    return trialEndDate!.difference(DateTime.now()).inDays;
  }

  /// Verifica se o trial está expirado.
  bool get isTrialExpired {
    if (!isTrial || trialEndDate == null) return false;
    return DateTime.now().isAfter(trialEndDate!);
  }

  // MARK: - Expiration Helpers

  /// Dias restantes até a expiração (qualquer plano).
  /// Retorna -1 se não há data de expiração.
  int get daysUntilExpiration {
    if (expirationDate == null) return -1;
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  /// Verifica se o plano está expirado dinamicamente.
  bool get isExpiredDynamic {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  /// Verifica se está no grace period (até 5 dias após expiração).
  bool get isInGracePeriod {
    if (expirationDate == null) return false;
    final now = DateTime.now();
    final graceEnd = expirationDate!.add(const Duration(days: 5));
    return now.isAfter(expirationDate!) && now.isBefore(graceEnd);
  }

  /// Verifica se o serviço foi interrompido (após grace period).
  bool get isServiceInterrupted {
    if (expirationDate == null) return false;
    final graceEnd = expirationDate!.add(const Duration(days: 5));
    return DateTime.now().isAfter(graceEnd);
  }

  /// Verifica se deve exibir aviso de expiração próxima (≤5 dias).
  bool get isExpirationWarning {
    final days = daysUntilExpiration;
    return days >= 0 && days <= 5;
  }

  /// Preço do plano atual.
  double get planPrice {
    if (isTrial) return 0;
    return planTierEnum.priceForPeriod(plan);
  }

  /// Limite de clientes do plano (0 = ilimitado).
  int get maxCustomers => isTrial ? 0 : planTierEnum.maxCustomers;

  /// Limite de produtos do plano.
  int get maxProducts => isTrial ? 500 : planTierEnum.maxProducts;
}
