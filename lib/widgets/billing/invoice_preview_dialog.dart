import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/billing.dart';
import '../../state/clinic_scope.dart';
import '../common/app_button.dart';
import '../common/status_badge.dart';
import '../common/toast_notification.dart';

class InvoicePreviewDialog extends StatelessWidget {
  final Invoice invoice;

  const InvoicePreviewDialog({super.key, required this.invoice});

  static void show(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) => InvoicePreviewDialog(invoice: invoice),
    );
  }

  void _showRecordPaymentModal(BuildContext context) {
    final controller = TextEditingController(
      text: invoice.balanceAmount.toStringAsFixed(0),
    );
    String selectedMethod = 'UPI (Google Pay / PhonePe)';

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
                    Text('Record Payment', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice: ${invoice.invoiceNumber} • ${invoice.patientName}',
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
                        DropdownMenuItem(value: 'UPI (Google Pay / PhonePe)', child: Text('UPI (GPay / PhonePe)')),
                        DropdownMenuItem(value: 'Cash', child: Text('Cash at Counter')),
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
                          text: 'Confirm & Collect',
                          icon: Icons.check,
                          onPressed: () {
                            final amt = double.tryParse(controller.text) ?? 0.0;
                            if (amt > 0) {
                              context.clinic.recordPayment(invoice.id, amt, selectedMethod);
                              Navigator.of(ctx).pop();
                              Navigator.of(context).pop();
                              AppFeedback.showSuccess(
                                context,
                                'Collected ₹${NumberFormat('#,##0').format(amt)} via $selectedMethod',
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

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Clinic Brand & Invoice details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SmileCare Dental Clinic',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Cosmetic Dentistry & Implant Center',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              '100 Feet Road, Indiranagar, Bengaluru • +91 80 2520 0000',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TAX INVOICE',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          invoice.invoiceNumber,
                          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                        ),
                        Text(
                          'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(invoice.date)}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                // Patient & Doctor Information row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BILLED TO', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(invoice.patientName, style: AppTextStyles.h4),
                        Text('Patient ID: ${invoice.patientId}', style: AppTextStyles.bodySmall),
                        Text(invoice.patientPhone, style: AppTextStyles.bodySmall),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('TREATING DOCTOR', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(invoice.doctorName, style: AppTextStyles.h4),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Status: ', style: AppTextStyles.bodySmall),
                            StatusBadge.fromPaymentStatus(invoice.status),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Items Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 5, child: Text('Service / Treatment Description', style: AppTextStyles.label)),
                      Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: AppTextStyles.label)),
                      Expanded(flex: 2, child: Text('Rate', textAlign: TextAlign.right, style: AppTextStyles.label)),
                      Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.right, style: AppTextStyles.label)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Items List
                ...invoice.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(item.description, style: AppTextStyles.bodyMedium),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('${item.quantity}', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(currency.format(item.unitPrice), textAlign: TextAlign.right, style: AppTextStyles.bodyMedium),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(currency.format(item.amount), textAlign: TextAlign.right, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),

                // Summary Calculation Block
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Mode: ${invoice.paymentMethod}', style: AppTextStyles.bodySmall),
                          if (invoice.transactionRef != null)
                            Text('Reference: ${invoice.transactionRef}', style: AppTextStyles.caption),
                          if (invoice.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Note: ${invoice.notes}', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal:', currency.format(invoice.subtotal)),
                          if (invoice.discount > 0)
                            _buildSummaryRow('Discount:', '- ${currency.format(invoice.discount)}', color: const Color(0xFF16A34A)),
                          const Divider(height: 16, color: AppColors.borderLight),
                          _buildSummaryRow('Total Amount:', currency.format(invoice.totalAmount), isBold: true),
                          _buildSummaryRow('Amount Paid:', currency.format(invoice.paidAmount), color: const Color(0xFF047857)),
                          if (invoice.balanceAmount > 0)
                            _buildSummaryRow(
                              'Balance Due:',
                              currency.format(invoice.balanceAmount),
                              color: const Color(0xFFDC2626),
                              isBold: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                // Bottom Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thank you for trusting SmileCare Dental Clinic!',
                      style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                    ),
                    Row(
                      children: [
                        AppButton.ghost(
                          text: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        AppButton.outline(
                          text: 'Print Bill',
                          icon: Icons.print_outlined,
                          onPressed: () {
                            AppFeedback.showInfo(context, 'Sent invoice to clinic thermal printer...');
                          },
                        ),
                        const SizedBox(width: 8),
                        AppButton.outline(
                          text: 'Download PDF',
                          icon: Icons.download_outlined,
                          onPressed: () {
                            AppFeedback.showSuccess(context, 'Downloaded ${invoice.invoiceNumber}.pdf');
                          },
                        ),
                        if (invoice.balanceAmount > 0) ...[
                          const SizedBox(width: 8),
                          AppButton.success(
                            text: 'Record Payment',
                            icon: Icons.payments_outlined,
                            onPressed: () => _showRecordPaymentModal(context),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)
                : AppTextStyles.bodySmall,
          ),
          Text(
            value,
            style: isBold
                ? AppTextStyles.h4.copyWith(color: color ?? AppColors.textPrimary)
                : AppTextStyles.bodyMedium.copyWith(color: color ?? AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
