import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/billing.dart';
import '../../models/patient.dart';

/// Professional Medical/Dental Clinic Bill & Printable Document Generator.
///
/// Uses pure vector PDF rendering (`pdf` package) to produce authentic clinical
/// receipts suitable for native printing, archiving, or patient download.
class BillPdfGenerator {
  BillPdfGenerator._();

  /// Generates a professional clinical PDF invoice / receipt document.
  static Future<Uint8List> generateBillPdf({
    required Invoice invoice,
    Patient? patient,
    String clinicName = 'SmileCare Dental Clinic',
    String? clinicAddress,
    String? clinicContact,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('dd/MM/yyyy hh:mm a');
    final formattedDate = dateFormat.format(invoice.date);
    final formattedPrintedTime = timeFormat.format(DateTime.now());

    final String patientAge = (patient?.age.isNotEmpty == true)
        ? patient!.age
        : (patient?.dateOfBirth.isNotEmpty == true ? patient!.dateOfBirth : 'N/A');
    final String patientGender = (patient?.gender.isNotEmpty == true) ? patient!.gender : 'N/A';

    final double discount = invoice.discount;
    final double subtotal = invoice.subtotal;
    final double totalAmount = invoice.totalAmount;
    final double paidAmount = invoice.paidAmount;
    final double balanceDue = invoice.balanceAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. CLINIC HEADER
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clinicName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        clinicAddress ?? 'Operatory & Dental Care Center',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      if (clinicContact != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          clinicContact,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: invoice.status == PaymentStatus.paid
                              ? PdfColors.green50
                              : (invoice.status == PaymentStatus.partial ? PdfColors.orange50 : PdfColors.amber50),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          border: pw.Border.all(
                            color: invoice.status == PaymentStatus.paid
                                ? PdfColors.green700
                                : (invoice.status == PaymentStatus.partial ? PdfColors.orange700 : PdfColors.amber700),
                            width: 1,
                          ),
                        ),
                        child: pw.Text(
                          invoice.status == PaymentStatus.paid
                              ? 'PAID / SETTLED'
                              : (invoice.status == PaymentStatus.partial ? 'PARTIALLY SETTLED' : 'PAYMENT PENDING'),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: invoice.status == PaymentStatus.paid
                                ? PdfColors.green800
                                : (invoice.status == PaymentStatus.partial ? PdfColors.orange900 : PdfColors.amber900),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Invoice: ${invoice.invoiceNumber}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                      pw.Text(
                        'Date: $formattedDate',
                        style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 8),

              // 2. PATIENT & CLINICAL ATTENDING METADATA
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PATIENT INFORMATION',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            invoice.patientName,
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Patient ID: ${invoice.patientId}  |  Phone: ${invoice.patientPhone}',
                            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                          ),
                          pw.Text(
                            'Age / Gender: $patientAge / $patientGender',
                            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(width: 1, height: 50, color: PdfColors.grey300),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CLINICAL DETAILS',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Attending Doctor: ${invoice.doctorName}',
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                          ),
                          if (invoice.doctorId.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Doctor ID: ${invoice.doctorId}',
                              style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                            ),
                          ],
                          pw.Text(
                            'Receipt Ref: ${invoice.receiptNumber.isNotEmpty ? invoice.receiptNumber : 'Counter Pending'}',
                            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // 3. ITEMIZED PROCEDURES TABLE
              pw.Text(
                'ITEMIZED PROCEDURES & SERVICES',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(6),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(2.5),
                  4: pw.FlexColumnWidth(2.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _tableCell('#', isHeader: true, align: pw.TextAlign.center),
                      _tableCell('Procedure / Treatment Description', isHeader: true),
                      _tableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                      _tableCell('Unit Price', isHeader: true, align: pw.TextAlign.right),
                      _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Items
                  ...invoice.items.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index.isEven ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _tableCell('$index', align: pw.TextAlign.center),
                        _tableCell(item.description),
                        _tableCell('${item.quantity}', align: pw.TextAlign.center),
                        _tableCell('Rs. ${item.unitPrice.toStringAsFixed(2)}', align: pw.TextAlign.right),
                        _tableCell('Rs. ${item.amount.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 14),

              // 4. FINANCIAL SUMMARY & PAYMENT SECTION
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Notes & Payment Method Box
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (invoice.notes.isNotEmpty) ...[
                          pw.Text(
                            'Clinical / Billing Notes:',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            invoice.notes,
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                          ),
                          pw.SizedBox(height: 8),
                        ],
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Payment Mode: ${invoice.paymentMethod}',
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                              ),
                              if (invoice.transactionRef != null && invoice.transactionRef!.isNotEmpty)
                                pw.Text(
                                  'Transaction Ref: ${invoice.transactionRef}',
                                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                                ),
                              if (invoice.receivedBy.isNotEmpty)
                                pw.Text(
                                  'Received / Processed By: ${invoice.receivedBy}',
                                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 24),

                  // Financial Totals Table
                  pw.Expanded(
                    flex: 5,
                    child: pw.Table(
                      columnWidths: const {
                        0: pw.FlexColumnWidth(5),
                        1: pw.FlexColumnWidth(5),
                      },
                      children: [
                        _totalRow('Subtotal:', 'Rs. ${subtotal.toStringAsFixed(2)}'),
                        if (discount > 0)
                          _totalRow('Discount:', '- Rs. ${discount.toStringAsFixed(2)}', isDiscount: true),
                        _totalRow(
                          'Total Payable:',
                          'Rs. ${totalAmount.toStringAsFixed(2)}',
                          isBold: true,
                          fontSize: 12,
                        ),
                        _totalRow(
                          'Amount Paid:',
                          'Rs. ${paidAmount.toStringAsFixed(2)}',
                          color: PdfColors.green800,
                        ),
                        _totalRow(
                          'Balance Due:',
                          'Rs. ${balanceDue.toStringAsFixed(2)}',
                          isBold: true,
                          color: balanceDue > 0 ? PdfColors.red800 : PdfColors.green800,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // 5. OFFICIAL FOOTER & SIGN-OFF
              pw.Divider(color: PdfColors.grey300, thickness: 0.8),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'This is an official computer-generated clinical tax invoice / receipt.',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'Generated on $formattedPrintedTime',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 140,
                        height: 35,
                        alignment: pw.Alignment.bottomCenter,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                        ),
                        child: pw.Text(
                          invoice.receivedBy.isNotEmpty ? invoice.receivedBy : 'Authorized Signature',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Authorized Signatory',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.grey900,
        ),
      ),
    );
  }

  static pw.TableRow _totalRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
    double fontSize = 10,
    PdfColor? color,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDiscount ? PdfColors.red700 : (color ?? PdfColors.grey800),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDiscount ? PdfColors.red700 : (color ?? PdfColors.black),
            ),
          ),
        ),
      ],
    );
  }
}
