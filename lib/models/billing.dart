enum PaymentStatus {
  paid,
  pending,
  partial,
  refunded,
}

extension PaymentStatusExt on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double amount;

  const InvoiceItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber; // e.g. "INV-2026-0042"
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final PaymentStatus status;
  final String paymentMethod; // "UPI", "Cash", "Card", "Insurance"
  final String? transactionRef;
  final String notes;
  final String receiptNumber;
  final String receivedBy;
  final String paymentStatusText;
  final DateTime? paymentDate;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
    required this.paymentMethod,
    this.transactionRef,
    this.notes = '',
    this.receiptNumber = '',
    this.receivedBy = 'Mr. Ajay Dhanger',
    this.paymentStatusText = 'Settled',
    this.paymentDate,
  });

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? doctorId,
    String? doctorName,
    DateTime? date,
    List<InvoiceItem>? items,
    double? subtotal,
    double? discount,
    double? tax,
    double? totalAmount,
    double? paidAmount,
    double? balanceAmount,
    PaymentStatus? status,
    String? paymentMethod,
    String? transactionRef,
    String? notes,
    String? receiptNumber,
    String? receivedBy,
    String? paymentStatusText,
    DateTime? paymentDate,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionRef: transactionRef ?? this.transactionRef,
      notes: notes ?? this.notes,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receivedBy: receivedBy ?? this.receivedBy,
      paymentStatusText: paymentStatusText ?? this.paymentStatusText,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'patient_id': patientId,
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'date': date.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'status': status.name,
      'payment_method': paymentMethod,
      'transaction_ref': transactionRef,
      'notes': notes,
      'receipt_number': receiptNumber,
      'received_by': receivedBy,
      'payment_status_text': paymentStatusText,
      'payment_date': paymentDate?.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, {List<InvoiceItem>? items}) {
    PaymentStatus parseStatus(String? val) {
      if (val == null) return PaymentStatus.pending;
      for (final s in PaymentStatus.values) {
        if (s.name.toLowerCase() == val.toLowerCase()) return s;
      }
      return PaymentStatus.pending;
    }

    return Invoice(
      id: map['id']?.toString() ?? '',
      invoiceNumber: map['invoice_number']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      patientName: map['patient_name']?.toString() ?? '',
      patientPhone: map['patient_phone']?.toString() ?? '',
      doctorId: map['doctor_id']?.toString() ?? '',
      doctorName: map['doctor_name']?.toString() ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: items ?? [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (map['balance_amount'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(map['status']?.toString()),
      paymentMethod: map['payment_method']?.toString() ?? 'Cash',
      transactionRef: map['transaction_ref']?.toString(),
      notes: map['notes']?.toString() ?? '',
      receiptNumber: map['receipt_number']?.toString() ?? '',
      receivedBy: map['received_by']?.toString() ?? 'Mr. Ajay Dhanger',
      paymentStatusText: map['payment_status_text']?.toString() ?? 'Settled',
      paymentDate: map['payment_date'] != null
          ? DateTime.tryParse(map['payment_date'].toString())
          : null,
    );
  }
}
