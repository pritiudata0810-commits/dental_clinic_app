import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/billing.dart';
import '../../models/patient.dart';
import '../../state/clinic_scope.dart';
import '../../services/billing/bill_pdf_generator.dart';
import '../common/app_button.dart';
import '../common/toast_notification.dart';
import 'printable_receipt_document.dart';

class InvoicePreviewDialog extends StatefulWidget {
  final Invoice invoice;

  const InvoicePreviewDialog({super.key, required this.invoice});

  static void show(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) => InvoicePreviewDialog(invoice: invoice),
    );
  }

  @override
  State<InvoicePreviewDialog> createState() => _InvoicePreviewDialogState();
}

class _InvoicePreviewDialogState extends State<InvoicePreviewDialog> {
  ReceiptPaperFormat _selectedFormat = ReceiptPaperFormat.a4;
  late Invoice _currentInvoice;
  bool _isProcessingDocument = false;

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
  }

  void _showRecordPaymentModal() {
    final controller = TextEditingController(
      text: _currentInvoice.balanceAmount.toStringAsFixed(0),
    );
    final refController = TextEditingController();
    String selectedMethod = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Record Counter Payment', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice: ${_currentInvoice.invoiceNumber} • ${_currentInvoice.patientName}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (₹) *',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash at Counter')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI (GPay / PhonePe / Paytm)')),
                        DropdownMenuItem(value: 'POS Card', child: Text('POS Card Machine (Debit / Credit)')),
                        DropdownMenuItem(value: 'Net Banking', child: Text('Direct Bank Transfer')),
                      ],
                      onChanged: (val) {
                        if (val != null) setStateModal(() => selectedMethod = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: refController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction / UTR Ref (Optional)',
                        hintText: 'e.g. UPI Ref / Card Last 4 Digits',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton.ghost(
                          text: 'Cancel',
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        const SizedBox(width: 12),
                        AppButton.success(
                          text: 'Confirm & Settle',
                          icon: Icons.check,
                          onPressed: () async {
                            final amt = double.tryParse(controller.text) ?? 0.0;
                            if (amt <= 0) {
                              AppFeedback.showError(ctx, 'Please enter a valid payment amount greater than zero.');
                              return;
                            }
                            if (selectedMethod.trim().isEmpty) {
                              AppFeedback.showError(ctx, 'Please select a payment method.');
                              return;
                            }

                            final clinic = context.clinic;
                            final txRef = refController.text.trim();
                            final success = await clinic.recordPayment(
                              _currentInvoice.id,
                              amt,
                              selectedMethod,
                              transactionRef: txRef.isNotEmpty ? txRef : null,
                            );

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (!mounted) return;
                            if (success) {
                              final updated = clinic.invoices.firstWhere(
                                (inv) => inv.id == _currentInvoice.id,
                                orElse: () => _currentInvoice,
                              );
                              setState(() {
                                _currentInvoice = updated;
                              });
                              AppFeedback.showSuccess(
                                context,
                                'Payment of ₹${NumberFormat('#,##0').format(amt)} recorded in ledger via $selectedMethod',
                              );
                            } else {
                              AppFeedback.showError(
                                context,
                                'Failed to record payment in Supabase database. Please try again.',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePrint(Patient? patient) async {
    setState(() => _isProcessingDocument = true);
    try {
      final pdfBytes = await BillPdfGenerator.generateBillPdf(
        invoice: _currentInvoice,
        patient: patient,
      );

      final printed = await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'clinic_bill_${_currentInvoice.invoiceNumber}.pdf',
      );

      if (!mounted) return;
      setState(() => _isProcessingDocument = false);

      if (printed) {
        AppFeedback.showSuccess(context, 'Print document dispatched for ${_currentInvoice.invoiceNumber}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingDocument = false);
      AppFeedback.showError(context, 'Printing failed: $e');
    }
  }

  Future<void> _handleDownload(Patient? patient) async {
    setState(() => _isProcessingDocument = true);
    try {
      final pdfBytes = await BillPdfGenerator.generateBillPdf(
        invoice: _currentInvoice,
        patient: patient,
      );

      final safeInvId = _currentInvoice.invoiceNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
      final fileName = 'clinic_bill_$safeInvId.pdf';

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

      if (!mounted) return;
      setState(() => _isProcessingDocument = false);

      AppFeedback.showSuccess(context, 'Bill downloaded / ready: $fileName');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingDocument = false);
      AppFeedback.showError(context, 'Bill download failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final patient = clinic.patients.cast<Patient?>().firstWhere(
      (p) => p?.id == _currentInvoice.patientId,
      orElse: () => null,
    );

    final isNarrow = MediaQuery.of(context).size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 920),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Dark slate surrounding workbench backdrop
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // ----------------------------------------------------
              // TOP BAR: Metadata, Format Switcher & Print Actions
              // ----------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF334155), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon & Title
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Clinic Receipt - ${_currentInvoice.invoiceNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_currentInvoice.patientName} (${_currentInvoice.patientPhone})  •  Status: ${_currentInvoice.status.label}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    // Paper Format Switcher (A4 vs 80mm Thermal)
                    if (!isNarrow) ...[
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _formatButton(
                              label: 'A4 Sheet',
                              icon: Icons.description_outlined,
                              isSelected: _selectedFormat == ReceiptPaperFormat.a4,
                              onTap: () => setState(() => _selectedFormat = ReceiptPaperFormat.a4),
                            ),
                            _formatButton(
                              label: '80mm Thermal',
                              icon: Icons.receipt_outlined,
                              isSelected: _selectedFormat == ReceiptPaperFormat.thermal80mm,
                              onTap: () => setState(() => _selectedFormat = ReceiptPaperFormat.thermal80mm),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Download PDF Button
                    AppButton.ghost(
                      text: 'Download PDF',
                      icon: Icons.download_rounded,
                      height: 38,
                      onPressed: _isProcessingDocument ? null : () => _handleDownload(patient),
                    ),
                    const SizedBox(width: 8),

                    // Native Print Button
                    AppButton(
                      text: _isProcessingDocument ? 'Processing...' : 'Print Bill',
                      icon: _isProcessingDocument ? null : Icons.print_outlined,
                      height: 38,
                      onPressed: _isProcessingDocument ? null : () => _handlePrint(patient),
                    ),

                    if (_currentInvoice.balanceAmount > 0) ...[
                      const SizedBox(width: 8),
                      AppButton.success(
                        text: 'Record Payment',
                        icon: Icons.payments_outlined,
                        height: 38,
                        onPressed: () => _showRecordPaymentModal(),
                      ),
                    ],

                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                      tooltip: 'Close Preview',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // ----------------------------------------------------
              // SCROLLABLE DOCUMENT PREVIEW AREA (CLEAN WHITE SHEET)
              // ----------------------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Center(
                    child: PrintableReceiptDocument(
                      invoice: _currentInvoice,
                      patient: patient,
                      format: _selectedFormat,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
