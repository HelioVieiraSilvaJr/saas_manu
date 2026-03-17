import 'package:cloud_firestore/cloud_firestore.dart';

/// Status de um pagamento.
enum PaymentStatus {
  pending,
  paid,
  expired,
  cancelled;

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.paid:
        return 'Pago';
      case PaymentStatus.expired:
        return 'Expirado';
      case PaymentStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get icon {
    switch (this) {
      case PaymentStatus.pending:
        return '⏳';
      case PaymentStatus.paid:
        return '✅';
      case PaymentStatus.expired:
        return '⚠️';
      case PaymentStatus.cancelled:
        return '❌';
    }
  }

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Modelo de pagamento.
///
/// Subcollection: `tenants/{tenant_id}/payments/{payment_id}`
class PaymentModel {
  String uid;
  String plan; // 'monthly' | 'quarterly'
  String planTier; // 'standard' | 'pro'
  double amount;
  PaymentStatus status;
  DateTime createdAt;
  DateTime? paidAt;
  DateTime planExpirationDate; // Data de expiração gerada por este pagamento
  String? transactionId; // ID da transação no banco (EFI)
  String? pixCode; // Código copia-e-cola do PIX
  String? qrCodeBase64; // QR Code em base64

  PaymentModel({
    required this.uid,
    required this.plan,
    required this.planTier,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paidAt,
    required this.planExpirationDate,
    this.transactionId,
    this.pixCode,
    this.qrCodeBase64,
  });

  // MARK: - Factory

  static PaymentModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      uid: doc.id,
      plan: data['plan'] ?? 'monthly',
      planTier: data['plan_tier'] ?? 'standard',
      amount: (data['amount'] ?? 0).toDouble(),
      status: PaymentStatus.fromString(data['status'] ?? 'pending'),
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      paidAt: data['paid_at'] != null
          ? (data['paid_at'] as Timestamp).toDate()
          : null,
      planExpirationDate: data['plan_expiration_date'] != null
          ? (data['plan_expiration_date'] as Timestamp).toDate()
          : DateTime.now(),
      transactionId: data['transaction_id'],
      pixCode: data['pix_code'],
      qrCodeBase64: data['qr_code_base64'],
    );
  }

  // MARK: - Serialization

  Map<String, dynamic> toMap() {
    return {
      'plan': plan,
      'plan_tier': planTier,
      'amount': amount,
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      'paid_at': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'plan_expiration_date': Timestamp.fromDate(planExpirationDate),
      'transaction_id': transactionId,
      'pix_code': pixCode,
      'qr_code_base64': qrCodeBase64,
    };
  }

  /// Label combinado do plano: "Mensal Pro", "Trimestral Standard", etc.
  String get planLabel {
    final periodLabel = plan == 'monthly' ? 'Mensal' : 'Trimestral';
    final tierLabel = planTier == 'pro' ? 'Pro' : 'Standard';
    return '$periodLabel $tierLabel';
  }

  bool get isPaid => status == PaymentStatus.paid;
  bool get isPending => status == PaymentStatus.pending;
}
