import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/billing.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/search_bar_field.dart';
import '../../widgets/billing/invoice_preview_dialog.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String _statusFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final allInvoices = clinic.invoices;

    final filtered = allInvoices.where((inv) {
      if (_statusFilter != 'All') {
        if (inv.status.label.toLowerCase() != _statusFilter.toLowerCase()) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return inv.invoiceNumber.toLowerCase().contains(q) ||
            inv.patientName.toLowerCase().contains(q) ||
            inv.doctorName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final totalBilled = allInvoices.fold(0.0, (s, i) => s + i.totalAmount);
    final totalCollected = allInvoices.fold(0.0, (s, i) => s + i.paidAmount);
    final totalPending = allInvoices.fold(0.0, (s, i) => s + i.balanceAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Billing & Invoices', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Track counter collections, outstanding balances, and issue professional GST invoices',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Billing Summary KPI Row
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL INVOICED', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Text(currency.format(totalBilled), style: AppTextStyles.statValue),
                      const SizedBox(height: 4),
                      Text('${allInvoices.length} invoices generated', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL COLLECTED', style: AppTextStyles.label.copyWith(color: const Color(0xFF047857))),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(totalCollected),
                        style: AppTextStyles.statValue.copyWith(color: const Color(0xFF047857)),
                      ),
                      const SizedBox(height: 4),
                      Text('Via UPI, Cards & Cash', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OUTSTANDING BALANCE', style: AppTextStyles.label.copyWith(color: const Color(0xFFDC2626))),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(totalPending),
                        style: AppTextStyles.statValue.copyWith(color: const Color(0xFFDC2626)),
                      ),
                      const SizedBox(height: 4),
                      Text('Pending patient dues', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Filter & Search Toolbar
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: SearchBarField(
                    hintText: 'Search by Invoice #, Patient name or Doctor...',
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
                const SizedBox(width: 20),
                _buildStatusTab('All (${allInvoices.length})', 'All'),
                const SizedBox(width: 8),
                _buildStatusTab('Paid', 'Paid'),
                const SizedBox(width: 8),
                _buildStatusTab('Partial', 'Partial'),
                const SizedBox(width: 8),
                _buildStatusTab('Pending', 'Pending'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Invoices Table
          AppCard(
            padding: EdgeInsets.zero,
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No invoices match the selected criteria.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (c, i) => const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final inv = filtered[index];
                      return _InvoiceRow(invoice: inv);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String label, String value) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceRow({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return InkWell(
      onTap: () => InvoicePreviewDialog.show(context, invoice),
      hoverColor: AppColors.surfaceHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Invoice Icon & Number
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_outlined, size: 18, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.invoiceNumber, style: AppTextStyles.h4),
                  Text(DateFormat('dd MMM yyyy, hh:mm a').format(invoice.date), style: AppTextStyles.caption),
                ],
              ),
            ),

            // Patient
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.patientName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text('ID: ${invoice.patientId} • ${invoice.patientPhone}', style: AppTextStyles.caption),
                ],
              ),
            ),

            // Doctor & Treatment
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.items.map((i) => i.description).join(', '),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(invoice.doctorName, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ],
              ),
            ),

            // Total & Paid
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(currency.format(invoice.totalAmount), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  if (invoice.balanceAmount > 0)
                    Text('Due: ${currency.format(invoice.balanceAmount)}', style: AppTextStyles.caption.copyWith(color: const Color(0xFFDC2626), fontWeight: FontWeight.w600))
                  else
                    Text('Fully Paid', style: AppTextStyles.caption.copyWith(color: const Color(0xFF047857))),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Status Badge
            StatusBadge.fromPaymentStatus(invoice.status),
            const SizedBox(width: 12),

            // Action Button
            AppButton.outline(
              text: 'View Bill',
              icon: Icons.visibility_outlined,
              onPressed: () => InvoicePreviewDialog.show(context, invoice),
            ),
          ],
        ),
      ),
    );
  }
}
