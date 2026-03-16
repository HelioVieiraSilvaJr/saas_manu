import 'package:cloud_firestore/cloud_firestore.dart';
import '../Enums/EscalationStatus.dart';

/// Modelo de atendimento escalado.
///
/// Subcoleção: `tenants/{tenant_id}/escalations/{escalation_id}`
/// Criado pelo Agente IA (n8n) quando um atendimento é escalado para humano.
///
/// Ciclo de vida:
/// 1. Agente IA cria com status `pending`
/// 2. Atendente assume → `in_progress` (assigned_to preenchido)
/// 3. Atendente finaliza → `completed` (customer.agent_off = false)
class EscalationModel {
  String uid;
  String customerId;
  String customerName;
  String customerWhatsapp;
  String? reason;
  String? agentConversationSummary;
  EscalationStatus status;
  String? assignedTo;
  String? assignedToName;
  String? notes;
  DateTime createdAt;
  DateTime? updatedAt;
  DateTime? completedAt;

  EscalationModel({
    required this.uid,
    required this.customerId,
    required this.customerName,
    required this.customerWhatsapp,
    this.reason,
    this.agentConversationSummary,
    required this.status,
    this.assignedTo,
    this.assignedToName,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  // MARK: - Factory

  static EscalationModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EscalationModel(
      uid: doc.id,
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      customerWhatsapp: data['customer_whatsapp'] ?? '',
      reason: data['reason'],
      agentConversationSummary: data['agent_conversation_summary'],
      status: EscalationStatus.fromString(data['status'] ?? 'pending'),
      assignedTo: data['assigned_to'],
      assignedToName: data['assigned_to_name'],
      notes: data['notes'],
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_whatsapp': customerWhatsapp,
      'reason': reason,
      'agent_conversation_summary': agentConversationSummary,
      'status': status.name,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'notes': notes,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completed_at': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  // MARK: - CopyWith

  EscalationModel copyWith({
    String? uid,
    String? customerId,
    String? customerName,
    String? customerWhatsapp,
    String? reason,
    String? agentConversationSummary,
    EscalationStatus? status,
    String? assignedTo,
    String? assignedToName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return EscalationModel(
      uid: uid ?? this.uid,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerWhatsapp: customerWhatsapp ?? this.customerWhatsapp,
      reason: reason ?? this.reason,
      agentConversationSummary:
          agentConversationSummary ?? this.agentConversationSummary,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // MARK: - Helpers

  /// Verifica se está pendente.
  bool get isPending => status == EscalationStatus.pending;

  /// Verifica se está em atendimento.
  bool get isInProgress => status == EscalationStatus.in_progress;

  /// Verifica se foi finalizado.
  bool get isCompleted => status == EscalationStatus.completed;

  /// Minutos desde a criação.
  int get minutesSinceCreation =>
      DateTime.now().difference(createdAt).inMinutes;

  /// Tempo de espera formatado.
  String get waitTimeFormatted {
    final minutes = minutesSinceCreation;
    if (minutes < 1) return 'Agora';
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h ${minutes % 60}min';
    final days = hours ~/ 24;
    return '${days}d ${hours % 24}h';
  }
}
