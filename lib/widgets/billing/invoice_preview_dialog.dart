import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/billing.dart';
import '../../models/patient.dart';
import '../../state/clinic_scope.dart';
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

  void _showRecordPaymentModal(BuildContext context) {
    final controller = TextEditingController(
      text: widget.invoice.balanceAmount.toStringAsFixed(0),
    );
    String selectedMethod = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Record Counter Payment', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice: ${widget.invoice.invoiceNumber} • ${widget.invoice.patientName}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (₹)',
                        prefixText: '₹ ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: const InputDecoration(labelText: 'Payment Mode'),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash at Counter')),
                        DropdownMenuItem(value: 'UPI (GPay / PhonePe)', child: Text('UPI (GPay / PhonePe)')),
                        DropdownMenuItem(value: 'Credit / Debit Card', child: Text('POS Card Machine')),
                        DropdownMenuItem(value: 'Net Banking', child: Text('Direct Bank Transfer')),
                      ],
                      onChanged: (val) {
                        if (val != null) setStateModal(() => selectedMethod = val);
                      },
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
                          onPressed: () {
                            final amt = double.tryParse(controller.text) ?? 0.0;
                            if (amt > 0) {
                              context.clinic.recordPayment(widget.invoice.id, amt, selectedMethod);
                              Navigator.of(ctx).pop();
                              Navigator.of(context).pop();
                              AppFeedback.showSuccess(
                                context,
                                'Payment of ₹${NumberFormat('#,##0').format(amt)} settled via $selectedMethod',
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

  void _triggerPrintView(BuildContext context, Patient? patient) {
    // Open dedicated print preview screen where only the printable document is displayed
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            title: Text(
              'Print Receipt - ${widget.invoice.invoiceNumber}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Send to Printer',
                onPressed: () {
                  AppFeedback.showSuccess(ctx, 'Print job sent to clinic thermal / laser printer');
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: PrintableReceiptDocument(
                invoice: widget.invoice,
                patient: patient,
                format: _selectedFormat,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final patient = clinic.patients.cast<Patient?>().firstWhere(
      (p) => p?.id == widget.invoice.patientId,
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
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // ----------------------------------------------------
              // TOP ACTION TOOLBAR (DOCUMENT VIEWER CONTROLS)
              // ----------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Printable Clinic Invoice / Receipt',
                            style: AppTextStyles.h4.copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.invoice.invoiceNumber} • ${widget.invoice.patientName}',
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Paper Format Toggle
                    if (!isNarrow) ...[
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
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

                    // Print Button
                    AppButton(
                      text: 'Print Bill',
                      icon: Icons.print_outlined,
                      height: 38,
                      onPressed: () => _triggerPrintView(context, patient),
                    ),

                    if (widget.invoice.balanceAmount > 0) ...[
                      const SizedBox(width: 8),
                      AppButton.success(
                        text: 'Record Payment',
                        icon: Icons.payments_outlined,
                        height: 38,
                        onPressed: () => _showRecordPaymentModal(context),
                      ),
                    ],

                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
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
                      invoice: widget.invoice,
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
