import 'package:intl/intl.dart';

/// Immutable domain model representing a single ledger transaction in `public.payments`.
/// Used for counter settlements, receipts, and audit trail.
class PaymentRecord {
  final String id;
  final String invoiceId;
  final String patientId;
  final String patientName;
  final double amount;
  final String paymentMethod; // 'Cash', 'UPI', 'POS Card', 'Net Banking'
  final String? transactionRef;
  final String receiptNumber;
  final String? receivedByUserId;
  final String receivedByName;
  final String clinicId;
  final String notes;
  final DateTime paymentDate;
  final DateTime createdAt;

  const PaymentRecord({
    required this.id,
    required this.invoiceId,
    required this.patientId,
    required this.patientName,
    required this.amount,
    required this.paymentMethod,
    this.transactionRef,
    required this.receiptNumber,
    this.receivedByUserId,
    this.receivedByName = 'Clinic Staff',
    this.clinicId = 'CLINIC-01',
    this.notes = '',
    required this.paymentDate,
    required this.createdAt,
  });

  String get formattedAmount => '₹${NumberFormat('#,##0.00').format(amount)}';
  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(paymentDate);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'patient_id': patientId,
      'patient_name': patientName,
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_ref': transactionRef ?? '',
      'receipt_number': receiptNumber,
      'received_by_user_id': receivedByUserId,
      'received_by_name': receivedByName,
      'clinic_id': clinicId,
      'notes': notes,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id']?.toString() ?? '',
      invoiceId: map['invoice_id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      patientName: map['patient_name']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method']?.toString() ?? 'Cash',
      transactionRef: map['transaction_ref']?.toString(),
      receiptNumber: map['receipt_number']?.toString() ?? '',
      receivedByUserId: map['received_by_user_id']?.toString(),
      receivedByName: map['received_by_name']?.toString() ?? 'Clinic Staff',
      clinicId: map['clinic_id']?.toString() ?? 'CLINIC-01',
      notes: map['notes']?.toString() ?? '',
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'].toString())
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  PaymentRecord copyWith({
    String? id,
    String? invoiceId,
    String? patientId,
    String? patientName,
    double? amount,
    String? paymentMethod,
    String? transactionRef,
    String? receiptNumber,
    String? receivedByUserId,
    String? receivedByName,
    String? clinicId,
    String? notes,
    DateTime? paymentDate,
    DateTime? createdAt,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionRef: transactionRef ?? this.transactionRef,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receivedByUserId: receivedByUserId ?? this.receivedByUserId,
      receivedByName: receivedByName ?? this.receivedByName,
      clinicId: clinicId ?? this.clinicId,
      notes: notes ?? this.notes,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
