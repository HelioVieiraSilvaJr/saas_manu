import 'package:cloud_firestore/cloud_firestore.dart';
import '../Enums/StockAlertStatus.dart';

/// Modelo de aviso de estoque.
///
/// Subcoleção: `tenants/{tenant_id}/stockAlerts/{alert_id}`
/// Criado pelo Agente IA quando o cliente deseja ser avisado
/// sobre a reposição de um produto sem estoque.
///
/// Ciclo de vida:
/// 1. Agente IA cria com status `pending`
/// 2. Estoque reposto → plataforma notifica cliente → `notified`
/// 3. Ou operador encerra manualmente → `dismissed`
class StockAlertModel {
  String uid;
  String customerId;
  String customerName;
  String customerWhatsapp;
  String productId;
  String productName;
  int desiredQuantity;
  StockAlertStatus status;
  String? notes;
  DateTime createdAt;
  DateTime? updatedAt;
  DateTime? resolvedAt;

  StockAlertModel({
    required this.uid,
    required this.customerId,
    required this.customerName,
    required this.customerWhatsapp,
    required this.productId,
    required this.productName,
    required this.desiredQuantity,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  // MARK: - Factory

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _parseInt(dynamic value, {int fallback = 1}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static StockAlertModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockAlertModel(
      uid: doc.id,
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      customerWhatsapp: data['customer_whatsapp'] ?? '',
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      desiredQuantity: _parseInt(data['desired_quantity']),
      status: StockAlertStatus.fromString(data['status'] ?? 'pending'),
      notes: data['notes'],
      createdAt: _parseDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updated_at']),
      resolvedAt: _parseDateTime(data['resolved_at']),
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_whatsapp': customerWhatsapp,
      'product_id': productId,
      'product_name': productName,
      'desired_quantity': desiredQuantity,
      'status': status.name,
      'notes': notes,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolved_at': resolvedAt != null
          ? Timestamp.fromDate(resolvedAt!)
          : null,
    };
  }

  // MARK: - CopyWith

  StockAlertModel copyWith({
    String? uid,
    String? customerId,
    String? customerName,
    String? customerWhatsapp,
    String? productId,
    String? productName,
    int? desiredQuantity,
    StockAlertStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return StockAlertModel(
      uid: uid ?? this.uid,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerWhatsapp: customerWhatsapp ?? this.customerWhatsapp,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      desiredQuantity: desiredQuantity ?? this.desiredQuantity,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  // MARK: - Helpers

  /// Verifica se está pendente (aguardando reposição).
  bool get isPending => status == StockAlertStatus.pending;

  /// Verifica se já foi notificado.
  bool get isNotified => status == StockAlertStatus.notified;

  /// Verifica se foi encerrado.
  bool get isDismissed => status == StockAlertStatus.dismissed;

  /// Dias desde a criação do aviso.
  int get daysSinceCreation => DateTime.now().difference(createdAt).inDays;

  /// Tempo de espera formatado em dias.
  String get waitTimeFormatted {
    final days = daysSinceCreation;
    if (days == 0) return 'Hoje';
    if (days == 1) return '1 dia';
    return '$days dias';
  }
}
