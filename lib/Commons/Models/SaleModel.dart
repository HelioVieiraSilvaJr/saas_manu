import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Enums/SaleStatus.dart';
import '../../Commons/Enums/SaleSource.dart';
import 'SaleItemModel.dart';

/// Modelo de venda.
///
/// Subcoleção: `tenants/{tenant_id}/sales/{sale_id}`
/// NÃO contém campo tenant_id (path NESTED).
class SaleModel {
  String uid;
  String customerId;
  String customerName;
  String customerWhatsapp;
  List<SaleItemModel> items;
  double total;
  SaleStatus status;
  SaleSource source;
  String? notes;
  String? conversationId;
  DateTime createdAt;
  DateTime? updatedAt;

  SaleModel({
    required this.uid,
    required this.customerId,
    required this.customerName,
    required this.customerWhatsapp,
    required this.items,
    required this.total,
    required this.status,
    required this.source,
    this.notes,
    this.conversationId,
    required this.createdAt,
    this.updatedAt,
  });

  // MARK: - Factory

  static SaleModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final itemsList =
        (data['items'] as List<dynamic>?)
            ?.map((item) => SaleItemModel.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return SaleModel(
      uid: doc.id,
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      customerWhatsapp: data['customer_whatsapp'] ?? '',
      items: itemsList,
      total: (data['total'] ?? 0).toDouble(),
      status: SaleStatus.fromString(data['status'] ?? 'pending'),
      source: SaleSource.fromString(data['source'] ?? 'manual'),
      notes: data['notes'],
      conversationId: data['conversation_id'],
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_whatsapp': customerWhatsapp,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status.name,
      'source': source.name,
      'notes': notes,
      'conversation_id': conversationId,
      'item_product_ids': items.map((item) => item.productId).toList(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // MARK: - Helpers

  static SaleModel newModel() {
    return SaleModel(
      uid: '',
      customerId: '',
      customerName: '',
      customerWhatsapp: '',
      items: [],
      total: 0,
      status: SaleStatus.pending,
      source: SaleSource.manual,
      createdAt: DateTime.now(),
    );
  }

  SaleModel copyWith({
    String? uid,
    String? customerId,
    String? customerName,
    String? customerWhatsapp,
    List<SaleItemModel>? items,
    double? total,
    SaleStatus? status,
    SaleSource? source,
    String? notes,
    String? conversationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleModel(
      uid: uid ?? this.uid,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerWhatsapp: customerWhatsapp ?? this.customerWhatsapp,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Quantidade total de itens.
  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Número formatado (5 dígitos).
  String get number => uid.isNotEmpty
      ? uid.hashCode.abs().toString().padLeft(5, '0').substring(0, 5)
      : '00000';

  /// Verifica se é venda automática.
  bool get isAutomated => source == SaleSource.whatsapp_automation;

  /// Verifica se pode ser cancelada (não está cancelada).
  bool get canCancel => status != SaleStatus.cancelled;

  /// Verifica se está confirmada.
  bool get isConfirmed => status == SaleStatus.confirmed;

  /// Verifica se está pendente.
  bool get isPending => status == SaleStatus.pending;

  /// Verifica se está cancelada.
  bool get isCancelled => status == SaleStatus.cancelled;
}
