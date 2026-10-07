import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/models/billing.dart';
import 'package:dental_clinic_app/models/patient.dart';
import 'package:dental_clinic_app/models/payment_record.dart';
import 'package:dental_clinic_app/services/billing/bill_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Doctor-to-Receptionist Billing Workflow Tests', () {
    final testDate = DateTime(2026, 10, 4, 11, 30);
    final testPatient = Patient(
      id: 'P-1001',
      name: 'Aarav Mehta',
      phone: '+91 98765 43210',
      email: 'aarav.mehta@email.com',
      dateOfBirth: '1995-04-12',
      gender: 'Male',
      address: 'Tapovan, Rishikesh, Uttarakhand',
      emergencyContact: 'Priya Mehta • +91 98765 12345',
      assignedDoctorId: 'DOC-01',
      assignedDoctorName: 'Dr. Rahul Sharma',
      lastVisit: '13 Feb 2026',
      totalVisits: 4,
      balanceDue: 0.0,
      bloodGroup: 'O+',
      allergies: ['Penicillin (Mild Rash)'],
      registrationDate: DateTime(2026, 1, 15),
      crNumber: 'CR-2026-937',
      age: '30 yrs',
    );

    test('1. Invoice Model: Calculations for Subtotal, Discount, and Net Payable', () {
      final items = [
        const InvoiceItem(
          description: 'Doctor Consultation Fee',
          quantity: 1,
          unitPrice: 500.0,
          amount: 500.0,
        ),
        const InvoiceItem(
          description: 'Composite Tooth Restoration / Filling',
          quantity: 2,
          unitPrice: 1200.0,
          amount: 2400.0,
        ),
      ];

      final subtotal = items.fold(0.0, (sum, i) => sum + i.amount);
      const discount = 200.0;
      final totalAmount = subtotal - discount;

      final invoice = Invoice(
        id: 'INV-TEST-001',
        invoiceNumber: 'INV-2026-0001',
        patientId: testPatient.id,
        patientName: testPatient.name,
        patientPhone: testPatient.phone,
        doctorId: 'DOC-01',
        doctorName: 'Dr. Rahul Sharma',
        date: testDate,
        items: items,
        subtotal: subtotal,
        discount: discount,
        tax: 0.0,
        totalAmount: totalAmount,
        paidAmount: 0.0,
        balanceAmount: totalAmount,
        status: PaymentStatus.pending,
        paymentMethod: 'Pending Counter Settlement',
        notes: 'Clinical restoration on tooth 16 & 17',
        receiptNumber: '',
        receivedBy: '',
        paymentStatusText: 'Pending',
      );

      expect(invoice.subtotal, 2900.0);
      expect(invoice.discount, 200.0);
      expect(invoice.totalAmount, 2700.0);
      expect(invoice.balanceAmount, 2700.0);
      expect(invoice.paidAmount, 0.0);
      expect(invoice.status, PaymentStatus.pending);
      expect(invoice.items.length, 2);
    });

    test('2. BillPdfGenerator: Generates valid vector PDF bytes with magic header %PDF-', () async {
      final invoice = Invoice(
        id: 'INV-TEST-002',
        invoiceNumber: 'INV-2026-0042',
        patientId: testPatient.id,
        patientName: testPatient.name,
        patientPhone: testPatient.phone,
        doctorId: 'DOC-01',
        doctorName: 'Dr. Rahul Sharma',
        date: testDate,
        items: const [
          InvoiceItem(
            description: 'Full Mouth Scaling & Polishing',
            quantity: 1,
            unitPrice: 1000.0,
            amount: 1000.0,
          ),
          InvoiceItem(
            description: 'Dental X-Ray (IOPA)',
            quantity: 2,
            unitPrice: 300.0,
            amount: 600.0,
          ),
        ],
        subtotal: 1600.0,
        discount: 100.0,
        tax: 0.0,
        totalAmount: 1500.0,
        paidAmount: 1500.0,
        balanceAmount: 0.0,
        status: PaymentStatus.paid,
        paymentMethod: 'UPI',
        receiptNumber: 'RCP-2026-9821',
        receivedBy: 'Priya Sharma (Receptionist)',
        paymentStatusText: 'Paid',
      );

      final pdfBytes = await BillPdfGenerator.generateBillPdf(
        invoice: invoice,
        patient: testPatient,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));

      // Validate PDF Magic Number (%PDF-)
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });

    test('3. Receptionist Counter Payment: Settlement and Ledger Record Creation', () {
      final initialInvoice = Invoice(
        id: 'INV-TEST-003',
        invoiceNumber: 'INV-2026-0099',
        patientId: testPatient.id,
        patientName: testPatient.name,
        patientPhone: testPatient.phone,
        doctorId: 'DOC-01',
        doctorName: 'Dr. Rahul Sharma',
        date: testDate,
        items: const [
          InvoiceItem(
            description: 'Root Canal Treatment (RCT)',
            quantity: 1,
            unitPrice: 3500.0,
            amount: 3500.0,
          ),
        ],
        subtotal: 3500.0,
        discount: 0.0,
        tax: 0.0,
        totalAmount: 3500.0,
        paidAmount: 0.0,
        balanceAmount: 3500.0,
        status: PaymentStatus.pending,
        paymentMethod: 'Pending Counter Settlement',
        receiptNumber: '',
        receivedBy: '',
        paymentStatusText: 'Pending',
      );

      // Simulate partial payment of 2000
      const paymentAmount = 2000.0;
      final newPaid = initialInvoice.paidAmount + paymentAmount;
      final newBalance = initialInvoice.totalAmount - newPaid;
      final newStatus = newBalance <= 0 ? PaymentStatus.paid : PaymentStatus.partial;

      final updatedInvoice = initialInvoice.copyWith(
        paidAmount: newPaid,
        balanceAmount: newBalance,
        status: newStatus,
        paymentMethod: 'UPI',
        receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        receivedBy: 'Reception Staff',
        paymentStatusText: newStatus.label,
      );

      expect(updatedInvoice.paidAmount, 2000.0);
      expect(updatedInvoice.balanceAmount, 1500.0);
      expect(updatedInvoice.status, PaymentStatus.partial);

      // Create PaymentRecord for public.payments ledger
      final ledgerEntry = PaymentRecord(
        id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        invoiceId: updatedInvoice.id,
        patientId: updatedInvoice.patientId,
        patientName: updatedInvoice.patientName,
        amount: paymentAmount,
        paymentMethod: 'UPI',
        transactionRef: 'UPI/20261004/99182',
        receiptNumber: updatedInvoice.receiptNumber,
        receivedByUserId: 'STAFF-REC-01',
        receivedByName: 'Priya Sharma',
        clinicId: 'CLINIC-MAIN',
        notes: 'Counter payment partial settlement',
        paymentDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(ledgerEntry.amount, 2000.0);
      expect(ledgerEntry.paymentMethod, 'UPI');
      expect(ledgerEntry.transactionRef, 'UPI/20261004/99182');
      expect(ledgerEntry.receivedByName, 'Priya Sharma');

      final ledgerMap = ledgerEntry.toMap();
      expect(ledgerMap['invoice_id'], updatedInvoice.id);
      expect(ledgerMap['patient_name'], 'Aarav Mehta');
      expect(ledgerMap['amount'], 2000.0);
    });

    test('4. Full Counter Settlement sets balance to 0 and status to Paid', () {
      final initialInvoice = Invoice(
        id: 'INV-TEST-004',
        invoiceNumber: 'INV-2026-0100',
        patientId: testPatient.id,
        patientName: testPatient.name,
        patientPhone: testPatient.phone,
        doctorId: 'DOC-01',
        doctorName: 'Dr. Rahul Sharma',
        date: testDate,
        items: const [
          InvoiceItem(
            description: 'Ceramic Crown / Cap',
            quantity: 1,
            unitPrice: 4500.0,
            amount: 4500.0,
          ),
        ],
        subtotal: 4500.0,
        discount: 500.0,
        tax: 0.0,
        totalAmount: 4000.0,
        paidAmount: 0.0,
        balanceAmount: 4000.0,
        status: PaymentStatus.pending,
        paymentMethod: 'Pending Counter Settlement',
        receiptNumber: '',
        receivedBy: '',
        paymentStatusText: 'Pending',
      );

      final settledInvoice = initialInvoice.copyWith(
        paidAmount: 4000.0,
        balanceAmount: 0.0,
        status: PaymentStatus.paid,
        paymentMethod: 'POS Card Machine',
        receiptNumber: 'RCP-2026-7788',
        receivedBy: 'Reception Desk',
        paymentStatusText: 'Paid',
      );

      expect(settledInvoice.balanceAmount, 0.0);
      expect(settledInvoice.paidAmount, 4000.0);
      expect(settledInvoice.status, PaymentStatus.paid);
      expect(settledInvoice.paymentMethod, 'POS Card Machine');
      expect(settledInvoice.receiptNumber, 'RCP-2026-7788');
    });
  });
}
