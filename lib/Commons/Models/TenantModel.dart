import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de tenant (organização/empresa).
///
/// Coleção global: `tenants/{tenant_id}`
class TenantModel {
  String uid;
  String name;
  String contactEmail;
  String contactPhone;
  String plan; // 'trial' | 'basic' | 'full'
  bool isActive;
  DateTime createdAt;
  DateTime? trialEndDate;
  DateTime? nextPaymentDate;

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
    required this.isActive,
    required this.createdAt,
    this.trialEndDate,
    this.nextPaymentDate,
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
      isActive: data['is_active'] ?? true,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      trialEndDate: data['trial_end_date'] != null
          ? (data['trial_end_date'] as Timestamp).toDate()
          : null,
      nextPaymentDate: data['next_payment_date'] != null
          ? (data['next_payment_date'] as Timestamp).toDate()
          : null,
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
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'trial_end_date': trialEndDate != null
          ? Timestamp.fromDate(trialEndDate!)
          : null,
      'next_payment_date': nextPaymentDate != null
          ? Timestamp.fromDate(nextPaymentDate!)
          : null,
      'evolution_api_url': evolutionApiUrl,
      'evolution_api_key': evolutionApiKey,
      'evolution_instance_name': evolutionInstanceName,
      'webhook_token': webhookToken,
    };
  }

  // MARK: - Helpers

  static TenantModel newModel() {
    return TenantModel(
      uid: '',
      name: '',
      contactEmail: '',
      contactPhone: '',
      plan: 'trial',
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  TenantModel copyWith({
    String? uid,
    String? name,
    String? contactEmail,
    String? contactPhone,
    String? plan,
    bool? isActive,
    DateTime? createdAt,
    DateTime? trialEndDate,
    DateTime? nextPaymentDate,
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
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      evolutionApiUrl: evolutionApiUrl ?? this.evolutionApiUrl,
      evolutionApiKey: evolutionApiKey ?? this.evolutionApiKey,
      evolutionInstanceName:
          evolutionInstanceName ?? this.evolutionInstanceName,
      webhookToken: webhookToken ?? this.webhookToken,
    );
  }

  /// Verifica se o tenant está em período trial.
  bool get isTrial => plan == 'trial';

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
}
