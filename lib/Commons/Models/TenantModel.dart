import 'package:cloud_firestore/cloud_firestore.dart';
import '../Enums/PlanPeriod.dart';
import '../Enums/PlanTier.dart';

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

  // Integrações
  String? evolutionApiUrl;
  String? evolutionApiKey;
  String? evolutionInstanceName;
  String? webhookToken;

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
    this.evolutionApiUrl,
    this.evolutionApiKey,
    this.evolutionInstanceName,
    this.webhookToken,
  });

  // MARK: - Factory

  static TenantModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TenantModel(
      uid: doc.id,
      name: data['name'] ?? '',
      contactEmail: data['contact_email'] ?? '',
      contactPhone: data['contact_phone'] ?? '',
      plan: data['plan'] ?? 'trial',
      planTier: data['plan_tier'] ?? 'standard',
      isActive: data['is_active'] ?? true,
      isExpired: data['is_expired'] ?? false,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      expirationDate: data['expiration_date'] != null
          ? (data['expiration_date'] as Timestamp).toDate()
          : null,
      trialEndDate: data['trial_end_date'] != null
          ? (data['trial_end_date'] as Timestamp).toDate()
          : null,
      nextPaymentDate: data['next_payment_date'] != null
          ? (data['next_payment_date'] as Timestamp).toDate()
          : null,
      lastPaymentId: data['last_payment_id'],
      evolutionApiUrl: data['evolution_api_url'],
      evolutionApiKey: data['evolution_api_key'],
      evolutionInstanceName: data['evolution_instance_name'],
      webhookToken: data['webhook_token'],
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
      'evolution_api_url': evolutionApiUrl,
      'evolution_api_key': evolutionApiKey,
      'evolution_instance_name': evolutionInstanceName,
      'webhook_token': webhookToken,
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
    String? evolutionApiUrl,
    String? evolutionApiKey,
    String? evolutionInstanceName,
    String? webhookToken,
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
      evolutionApiUrl: evolutionApiUrl ?? this.evolutionApiUrl,
      evolutionApiKey: evolutionApiKey ?? this.evolutionApiKey,
      evolutionInstanceName:
          evolutionInstanceName ?? this.evolutionInstanceName,
      webhookToken: webhookToken ?? this.webhookToken,
    );
  }

  // MARK: - Plan Helpers

  /// Enum tipado do período.
  PlanPeriod get planPeriod => PlanPeriod.fromString(plan);

  /// Enum tipado do tier.
  PlanTier get planTierEnum => PlanTier.fromString(planTier);

  /// Verifica se o tenant está em período trial.
  bool get isTrial => plan == 'trial';

  /// Verifica se é plano pago.
  bool get isPaidPlan => plan == 'monthly' || plan == 'quarterly';

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
