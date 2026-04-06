import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Enums/SaleStatus.dart';
import '../../Commons/Enums/SaleSource.dart';
import '../../Commons/Enums/OrderStatus.dart';
import 'SaleItemModel.dart';

const _saleModelSentinel = Object();

/// Modelo de venda.
///
/// Subcoleção: `tenants/{tenant_id}/sales/{sale_id}`
/// NÃO contém campo tenant_id (path NESTED).
///
/// Ciclo de vida:
/// 1. Venda criada (pending) → ações: enviar cobrança, confirmar pgto, cancelar
/// 2. Cobrança enviada (payment_sent) → ações: confirmar pgto, cancelar
/// 3. Pagamento confirmado (confirmed) → entra no Kanban (orderStatus)
/// 4. Kanban: separating → packing → ready → completed
class SaleModel {
  String uid;
  String customerId;
  String customerName;
  String customerWhatsapp;
  String? publicOrderNumber;
  List<SaleItemModel> items;
  double total;
  SaleStatus status;
  SaleSource source;
  OrderStatus? orderStatus;
  String? notes;
  String? conversationId;
  DateTime createdAt;
  DateTime? updatedAt;
  DateTime? paymentRequestedAt;
  DateTime? paymentConfirmedAt;

  SaleModel({
    required this.uid,
    required this.customerId,
    required this.customerName,
    required this.customerWhatsapp,
    this.publicOrderNumber,
    required this.items,
    required this.total,
    required this.status,
    required this.source,
    this.orderStatus,
    this.notes,
    this.conversationId,
    required this.createdAt,
    this.updatedAt,
    this.paymentRequestedAt,
    this.paymentConfirmedAt,
  });

  // MARK: - Factory

  static SaleModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = SaleStatus.fromString(data['status'] ?? 'pending');
    final orderStatusValue = data['order_status'];

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
      publicOrderNumber: data['public_order_number'],
      items: itemsList,
      total: (data['total'] ?? 0).toDouble(),
      status: status,
      source: SaleSource.fromString(data['source'] ?? 'manual'),
      orderStatus: orderStatusValue != null
          ? OrderStatus.fromString(orderStatusValue)
          : status == SaleStatus.confirmed
          ? OrderStatus.awaiting_processing
          : null,
      notes: data['notes'],
      conversationId: data['conversation_id'],
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
      paymentRequestedAt: data['payment_requested_at'] != null
          ? (data['payment_requested_at'] as Timestamp).toDate()
          : null,
      paymentConfirmedAt: data['payment_confirmed_at'] != null
          ? (data['payment_confirmed_at'] as Timestamp).toDate()
          : null,
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_whatsapp': customerWhatsapp,
      'public_order_number': publicOrderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status.name,
      'source': source.name,
      'order_status': orderStatus?.name,
      'notes': notes,
      'conversation_id': conversationId,
      'item_product_ids': items.map((item) => item.productId).toList(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'payment_requested_at': paymentRequestedAt != null
          ? Timestamp.fromDate(paymentRequestedAt!)
          : null,
      'payment_confirmed_at': paymentConfirmedAt != null
          ? Timestamp.fromDate(paymentConfirmedAt!)
          : null,
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
    String? publicOrderNumber,
    List<SaleItemModel>? items,
    double? total,
    SaleStatus? status,
    SaleSource? source,
    Object? orderStatus = _saleModelSentinel,
    String? notes,
    String? conversationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paymentRequestedAt,
    DateTime? paymentConfirmedAt,
  }) {
    return SaleModel(
      uid: uid ?? this.uid,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerWhatsapp: customerWhatsapp ?? this.customerWhatsapp,
      publicOrderNumber: publicOrderNumber ?? this.publicOrderNumber,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      source: source ?? this.source,
      orderStatus: orderStatus == _saleModelSentinel
          ? this.orderStatus
          : orderStatus as OrderStatus?,
      notes: notes ?? this.notes,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentRequestedAt: paymentRequestedAt ?? this.paymentRequestedAt,
      paymentConfirmedAt: paymentConfirmedAt ?? this.paymentConfirmedAt,
    );
  }

  /// Quantidade total de itens.
  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Número formatado (5 dígitos).
  String get number => (publicOrderNumber?.isNotEmpty ?? false)
      ? publicOrderNumber!
      : uid.isNotEmpty
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

  /// Verifica se cobrança foi enviada.
  bool get isPaymentSent => status == SaleStatus.payment_sent;

  /// Verifica se está na esteira de pedidos (Kanban).
  bool get isInOrderPipeline =>
      status == SaleStatus.confirmed && orderStatus != null;

  /// Verifica se o pedido foi concluído.
  bool get isOrderCompleted => orderStatus == OrderStatus.completed;

  /// Verifica se pode enviar cobrança.
  bool get canSendPaymentRequest => status == SaleStatus.pending;

  /// Verifica se pode confirmar pagamento.
  bool get canConfirmPayment =>
      status == SaleStatus.pending || status == SaleStatus.payment_sent;
}
