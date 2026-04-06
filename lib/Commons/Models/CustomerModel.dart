import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de cliente (CRM).
///
/// Subcoleção: `tenants/{tenant_id}/customers/{customer_id}`
/// NÃO contém campo tenant_id (path NESTED).
///
/// Campos denormalizados (last_purchase_at, total_spent, purchase_count)
/// são atualizados quando uma venda é criada/cancelada.
class CustomerModel {
  String uid;
  String name;
  String whatsapp; // Apenas números no padrão internacional: 5511966191991
  String? email;
  String? notes;
  bool isActive;
  DateTime createdAt;
  DateTime? updatedAt;
  DateTime? lastPurchaseAt; // Denormalizado
  double? totalSpent; // Denormalizado
  int? purchaseCount; // Denormalizado
  bool agentOff; // true = agente IA pausado para este cliente

  CustomerModel({
    required this.uid,
    required this.name,
    required this.whatsapp,
    this.email,
    this.notes,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.lastPurchaseAt,
    this.totalSpent,
    this.purchaseCount,
    this.agentOff = false,
  });

  // MARK: - Factory

  static CustomerModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      uid: doc.id,
      name: data['name'] ?? '',
      whatsapp: data['whatsapp'] ?? '',
      email: data['email'],
      notes: data['notes'],
      isActive: data['is_active'] ?? true,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
      lastPurchaseAt: data['last_purchase_at'] != null
          ? (data['last_purchase_at'] as Timestamp).toDate()
          : null,
      totalSpent: data['total_spent'] != null
          ? (data['total_spent'] as num).toDouble()
          : null,
      purchaseCount: data['purchase_count'] as int?,
      agentOff: data['agent_off'] ?? false,
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'whatsapp': whatsapp,
      'email': email,
      'notes': notes,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'last_purchase_at': lastPurchaseAt != null
          ? Timestamp.fromDate(lastPurchaseAt!)
          : null,
      'total_spent': totalSpent,
      'purchase_count': purchaseCount,
      'agent_off': agentOff,
    };
  }

  // MARK: - Factory Helpers

  /// Novo cliente para criação.
  static CustomerModel newModel() {
    return CustomerModel(
      uid: '',
      name: '',
      whatsapp: '',
      isActive: true,
      createdAt: DateTime.now(),
      agentOff: false,
    );
  }

  // MARK: - CopyWith

  CustomerModel copyWith({
    String? uid,
    String? name,
    String? whatsapp,
    String? email,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastPurchaseAt,
    double? totalSpent,
    int? purchaseCount,
    bool? agentOff,
  }) {
    return CustomerModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      totalSpent: totalSpent ?? this.totalSpent,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      agentOff: agentOff ?? this.agentOff,
    );
  }

  // MARK: - Helpers

  /// Verifica se o cliente já realizou compras.
  bool get hasPurchases => purchaseCount != null && purchaseCount! > 0;

  /// Ticket médio.
  double get ticketMedio {
    if (!hasPurchases) return 0.0;
    return (totalSpent ?? 0.0) / purchaseCount!;
  }

  /// Dias desde o cadastro.
  int get diasDesdeCadastro => DateTime.now().difference(createdAt).inDays;
}
