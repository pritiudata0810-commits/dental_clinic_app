import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/patient.dart';
import '../../state/clinic_scope.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';
import '../../widgets/billing/invoice_preview_dialog.dart';
import '../../widgets/billing/create_invoice_dialog.dart';
import '../../widgets/communication/quick_comm_dialogs.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  final VoidCallback onBack;

  const PatientDetailScreen({
    super.key,
    required this.patient,
    required this.onBack,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  int _activeTab = 0; // 0: Appointments, 1: Billing

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Filter appointments for this patient
    final patientApts = clinic.appointments.where((a) => a.patientId == widget.patient.id).toList();
    // Filter invoices for this patient
    final patientInvoices = clinic.invoices.where((inv) => inv.patientId == widget.patient.id).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button & Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                splashRadius: 20,
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Patient Profile & Dental Intelligence', style: AppTextStyles.h2),
                  Text('Clinic File #${widget.patient.id}', style: AppTextStyles.caption),
                ],
              ),
              const Spacer(),
              AppButton.outline(
                text: 'Schedule Visit',
                icon: Icons.calendar_today_outlined,
                onPressed: () => AddAppointmentDialog.show(context, initialPatientId: widget.patient.id),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Profile Card
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    widget.patient.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 20),

                // Name & Profile Basics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.patient.name, style: AppTextStyles.h2),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.patient.crNumber.isNotEmpty
                                  ? 'CR: ${widget.patient.crNumber}'
                                  : 'CR: ${widget.patient.id}',
                              style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _badgeText('Age: ${widget.patient.age.isNotEmpty ? widget.patient.age : "32"} yrs'),
                          _badgeText('Gender: ${widget.patient.gender}'),
                          _badgeText('Blood: ${widget.patient.bloodGroup}'),
                          _badgeText('Registered: ${DateFormat('dd MMM yyyy').format(widget.patient.registrationDate)}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(widget.patient.phone, style: AppTextStyles.bodySmall),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => QuickCommDialogs.showCallDialog(
                              context,
                              patientId: widget.patient.id,
                              patientName: widget.patient.name,
                              phoneNumber: widget.patient.phone,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.callGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone, size: 11, color: AppColors.callGreen),
                                  SizedBox(width: 4),
                                  Text(
                                    'Call',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.callGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(widget.patient.email, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3 Metric Cards for this patient
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ASSIGNED DOCTOR', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Text(widget.patient.assignedDoctorName, style: AppTextStyles.h4),
                      const SizedBox(height: 4),
                      Text('Phone: ${widget.patient.phone}', style: AppTextStyles.caption),
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
                      Text('VISIT ACTIVITY', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Text('${widget.patient.totalVisits} Total Visits', style: AppTextStyles.h4),
                      const SizedBox(height: 4),
                      Text('Last: ${widget.patient.lastVisit} • Next: ${widget.patient.nextAppointment ?? 'None scheduled'}',
                          style: AppTextStyles.caption),
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
                      Text('BILLING SUMMARY', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Text(
                        widget.patient.balanceDue > 0 ? currency.format(widget.patient.balanceDue) : 'All Paid (₹0)',
                        style: AppTextStyles.h4.copyWith(
                          color: widget.patient.balanceDue > 0 ? const Color(0xFFDC2626) : const Color(0xFF047857),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${patientInvoices.length} total invoices generated', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (widget.patient.allergies.isNotEmpty || widget.patient.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              title: 'Reception & Medical Alerts',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.patient.allergies.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Text('Allergies & Sensitivities: ',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        ...widget.patient.allergies.map((alg) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(alg, style: AppTextStyles.label.copyWith(color: const Color(0xFF9F1239))),
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.patient.notes.isNotEmpty)
                    Text('Notes: ${widget.patient.notes}', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Navigation Section Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _tabButton(0, 'Appointments (${patientApts.length})', Icons.calendar_today_outlined),
                _tabButton(1, 'Billing & Receipts (${patientInvoices.length})', Icons.receipt_long_outlined),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TAB 0: APPOINTMENTS
          if (_activeTab == 0) ...[
            AppCard(
              title: 'Appointment History',
              subtitle: 'Past and upcoming bookings for this patient',
              trailing: AppButton(
                text: 'Book Appointment',
                icon: Icons.add,
                height: 36,
                onPressed: () => AddAppointmentDialog.show(context, initialPatientId: widget.patient.id),
              ),
              child: patientApts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No appointments recorded yet.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: patientApts.length,
                      separatorBuilder: (c, i) => const Divider(height: 16, color: AppColors.borderLight),
                      itemBuilder: (context, index) {
                        final apt = patientApts[index];
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(apt.timeString,
                                  style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${apt.appointmentType} with ${apt.doctorName}',
                                      style: AppTextStyles.h4.copyWith(fontSize: 14)),
                                  Text('Token: ${apt.tokenNumber} • Notes: ${apt.notes.isEmpty ? 'None' : apt.notes}',
                                      style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            StatusBadge.fromAppointmentStatus(apt.status),
                          ],
                        );
                      },
                    ),
            ),
          ],

          // TAB 1: BILLING & RECEIPTS
          if (_activeTab == 1) ...[
            AppCard(
              title: 'Billing & Invoices',
              subtitle: 'Payment records and receipts',
              trailing: AppButton(
                text: 'Create Bill',
                icon: Icons.add,
                height: 36,
                onPressed: () => CreateInvoiceDialog.show(context, patient: widget.patient),
              ),
              child: patientInvoices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No invoices issued yet.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: patientInvoices.length,
                      separatorBuilder: (c, i) => const Divider(height: 16, color: AppColors.borderLight),
                      itemBuilder: (context, index) {
                        final inv = patientInvoices[index];
                        return Row(
                          children: [
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(inv.invoiceNumber, style: AppTextStyles.h4.copyWith(fontSize: 14)),
                                  Text(inv.items.map((e) => e.description).join(", "),
                                      style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currency.format(inv.totalAmount),
                                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                                StatusBadge.fromPaymentStatus(inv.status),
                              ],
                            ),
                            const SizedBox(width: 12),
                            AppButton.outline(
                              text: 'View Receipt',
                              icon: Icons.visibility_outlined,
                              height: 36,
                              onPressed: () => InvoicePreviewDialog.show(context, inv),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              text: 'Print Bill',
                              icon: Icons.print_outlined,
                              height: 36,
                              onPressed: () => InvoicePreviewDialog.show(context, inv),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _badgeText(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    );
  }
}
