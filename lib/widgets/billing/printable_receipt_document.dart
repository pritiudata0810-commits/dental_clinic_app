import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/billing.dart';
import '../../models/patient.dart';

enum ReceiptPaperFormat {
  a4,
  thermal80mm,
}

class PrintableReceiptDocument extends StatelessWidget {
  final Invoice invoice;
  final Patient? patient;
  final ReceiptPaperFormat format;

  const PrintableReceiptDocument({
    super.key,
    required this.invoice,
    this.patient,
    this.format = ReceiptPaperFormat.a4,
  });

  @override
  Widget build(BuildContext context) {
    if (format == ReceiptPaperFormat.thermal80mm) {
      return _buildThermal80mmLayout();
    }
    return _buildA4Layout();
  }

  // ==========================================================
  // 1. STANDARD A4 CLINICAL INVOICE / RECEIPT DOCUMENT
  // ==========================================================
  Widget _buildA4Layout() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final printTimeFormat = DateFormat('dd/MM/yyyy hh:mma');
    final formattedDate = dateFormat.format(invoice.date);

    final crNumber = (patient?.crNumber != null && patient!.crNumber.isNotEmpty)
        ? patient!.crNumber
        : '20230212937';

    final ageStr = (patient?.age != null && patient!.age.isNotEmpty)
        ? patient!.age
        : (patient?.dateOfBirth != null && patient!.dateOfBirth.isNotEmpty)
            ? patient!.dateOfBirth
            : '51 yrs';

    final genderStr = patient?.gender != null && patient!.gender.isNotEmpty
        ? (patient!.gender.toLowerCase().startsWith('m') ? 'M' : 'F')
        : 'F';

    final receiptNo = invoice.receiptNumber.isNotEmpty
        ? invoice.receiptNumber
        : '2023021350079';

    final preparedBy = invoice.receivedBy.isNotEmpty
        ? invoice.receivedBy
        : 'Mr. Ajay Dhanger';

    return Container(
      constraints: const BoxConstraints(maxWidth: 794), // Standard A4 width at 96 DPI
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ----------------------------------------------------
          // CLINIC HEADER (Instituion, Address, Phone, Website)
          // ----------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black87, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.medical_services_outlined,
                    size: 26,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'SmileCare Dental College and Hospital',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Virbhadra Road, Post Office: Pashulok, Rishikesh, Uttarakhand\nTel: 0135-2453465, 2453725  •  Website: www.smilecaredental.org',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Printed On : ${printTimeFormat.format(DateTime.now())} By : $preparedBy',
              style: const TextStyle(fontSize: 9.5, color: Colors.black87),
            ),
          ),

          const SizedBox(height: 6),
          const Divider(color: Colors.black87, thickness: 1),
          const SizedBox(height: 8),

          // ----------------------------------------------------
          // BARCODE & RECEIPT DETAIL TITLE
          // ----------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Receipt Detail',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              // Barcode visual simulation
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 28),
                    painter: _BarcodePainter(),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // "Original Receipt" badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87),
              ),
              child: const Text(
                'Original Receipt',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ----------------------------------------------------
          // PATIENT INFORMATION
          // ----------------------------------------------------
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2.8),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.8),
            },
            children: [
              TableRow(
                children: [
                  _infoLabel('Invoice Number'),
                  _infoValue(invoice.invoiceNumber),
                  _infoLabel('CR Number'),
                  _infoValue(crNumber),
                ],
              ),
              TableRow(
                children: [
                  _infoLabel('Patient Name'),
                  _infoValue(invoice.patientName, isBold: true),
                  _infoLabel('Sex / Age'),
                  _infoValue('$genderStr / $ageStr'),
                ],
              ),
              TableRow(
                children: [
                  _infoLabel('Father / Relative'),
                  _infoValue(patient?.fatherOrGuardian.isNotEmpty == true ? patient!.fatherOrGuardian : '—'),
                  _infoLabel('Doctor'),
                  _infoValue(invoice.doctorName),
                ],
              ),
              TableRow(
                children: [
                  _infoLabel('Address'),
                  _infoValue(
                    patient?.address.isNotEmpty == true ? patient!.address : 'Tapovan, Rishikesh, Dehradun, Uttarakhand',
                    span: 3,
                  ),
                  const SizedBox.shrink(),
                  const SizedBox.shrink(),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ----------------------------------------------------
          // SERVICE / PROCEDURES TABLE
          // ----------------------------------------------------
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black87, width: 1),
                bottom: BorderSide(color: Colors.black87, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _tableColHeader('Date', flex: 2),
                _tableColHeader('Particulars', flex: 5),
                _tableColHeader('Rate (Rs.)', flex: 2, align: TextAlign.right),
                _tableColHeader('Unit', flex: 1, align: TextAlign.center),
                _tableColHeader('Gross Amt (Rs)', flex: 2, align: TextAlign.right),
                _tableColHeader('Disc Amt (Rs)', flex: 2, align: TextAlign.right),
                _tableColHeader('Net Amt (Rs)', flex: 2, align: TextAlign.right),
              ],
            ),
          ),

          // Service Category Header
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Billable Services',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),

          // Service Items
          ...invoice.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final code = '202302134007${idx + 1}-';
            final gross = item.unitPrice * item.quantity;
            final disc = invoice.discount > 0 ? (invoice.discount / invoice.items.length) : 0.0;
            final net = gross - disc;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(formattedDate, style: const TextStyle(fontSize: 10.5)),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text('$code${item.description}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(item.unitPrice.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(gross.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(disc.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(net.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(color: Colors.black54, thickness: 0.8),

          // ----------------------------------------------------
          // TOTALS SUMMARY
          // ----------------------------------------------------
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 300,
              child: Column(
                children: [
                  _summaryRow('Total Bill Amount', invoice.subtotal.toStringAsFixed(2)),
                  _summaryRow('Total Discount', invoice.discount.toStringAsFixed(2)),
                  _summaryRow('Net Bill Amount', invoice.totalAmount.toStringAsFixed(2), isBold: true),
                  _summaryRow('Balance Amount', invoice.balanceAmount.toStringAsFixed(2)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // PAYMENT DETAIL SECTION
          // ----------------------------------------------------
          const Text(
            'Payment Detail',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),

          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black87, width: 1),
                bottom: BorderSide(color: Colors.black87, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _tableColHeader('Date', flex: 2),
                _tableColHeader('Receipt No.', flex: 3),
                _tableColHeader('Mode', flex: 2),
                _tableColHeader('Type', flex: 2),
                _tableColHeader('Status: Settled', flex: 2),
                _tableColHeader('Amount', flex: 2, align: TextAlign.right),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(formattedDate, style: const TextStyle(fontSize: 10.5))),
                Expanded(flex: 3, child: Text(receiptNo, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text(invoice.paymentMethod, style: const TextStyle(fontSize: 10.5))),
                const Expanded(flex: 2, child: Text('Receive', style: TextStyle(fontSize: 10.5))),
                Expanded(
                  flex: 2,
                  child: Text(
                    invoice.status == PaymentStatus.paid ? 'Received Yes' : 'Pending',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    invoice.paidAmount.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Payment Subtotals
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 300,
              child: Column(
                children: [
                  _summaryRow('Total Received Amount', invoice.paidAmount.toStringAsFixed(2), isBold: true),
                  _summaryRow('Total Refunded Amount(-)', '0.00'),
                  _summaryRow('Net Payment', invoice.paidAmount.toStringAsFixed(2), isBold: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 36),

          // ----------------------------------------------------
          // SIGNATURE FOOTER
          // ----------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preparedBy,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Prepared By',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 140,
                    child: Divider(color: Colors.black87, thickness: 1),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Authorized Signatory',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 2. THERMAL 80MM RECEIPT LAYOUT
  // ==========================================================
  Widget _buildThermal80mmLayout() {
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');
    final crNumber = (patient?.crNumber != null && patient!.crNumber.isNotEmpty)
        ? patient!.crNumber
        : 'CR-${patient?.id ?? invoice.patientId}';

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SmileCare Dental Clinic',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          const Text(
            'Tel: 0135-2453465  •  Rishikesh',
            style: TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text('--------------------------------------------', textAlign: TextAlign.center),
          const Text(
            'CASH RECEIPT / INVOICE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const Text('--------------------------------------------', textAlign: TextAlign.center),

          _thermalRow('Invoice #:', invoice.invoiceNumber),
          _thermalRow('Date:', dateFormat.format(invoice.date)),
          _thermalRow('CR Number:', crNumber),
          _thermalRow('Patient:', invoice.patientName),
          _thermalRow('Doctor:', invoice.doctorName),
          const Text('--------------------------------------------', textAlign: TextAlign.center),

          ...invoice.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.description}',
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('₹${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10)),
                ],
              ),
            );
          }),

          const Text('--------------------------------------------', textAlign: TextAlign.center),
          _thermalRow('Total Amount:', '₹${invoice.totalAmount.toStringAsFixed(2)}', isBold: true),
          _thermalRow('Paid Amount:', '₹${invoice.paidAmount.toStringAsFixed(2)}', isBold: true),
          _thermalRow('Balance Due:', '₹${invoice.balanceAmount.toStringAsFixed(2)}', isBold: true),
          _thermalRow('Mode:', invoice.paymentMethod),
          const SizedBox(height: 12),
          const Text(
            'Thank you for visiting SmileCare!\nGet well soon.',
            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  static Widget _infoLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
    );
  }

  static Widget _infoValue(String text, {bool isBold = false, int span = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Text(
        ':  $text',
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  static Widget _tableColHeader(String title, {required int flex, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: align,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  static Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _thermalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;

    final widths = [
      1.5, 3.0, 1.5, 4.0, 1.5, 2.0, 1.5, 3.5, 2.0, 1.5, 4.0, 1.5, 2.5, 1.5,
      3.0, 1.5, 2.0, 4.0, 1.5, 2.5, 1.5, 3.5, 1.5, 2.0, 1.5, 4.0, 1.5, 3.0,
      1.5, 2.0, 3.5, 1.5, 2.5, 4.0, 1.5, 2.0, 1.5, 3.0, 2.0, 1.5, 3.5, 1.5
    ];

    double x = 0;
    for (int i = 0; i < widths.length && x < size.width; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, widths[i], size.height),
          paint,
        );
      }
      x += widths[i] + 1.2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
