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

class PatientDetailScreen extends StatelessWidget {
  final Patient patient;
  final VoidCallback onBack;

  const PatientDetailScreen({
    super.key,
    required this.patient,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Filter appointments for this patient
    final patientApts = clinic.appointments.where((a) => a.patientId == patient.id).toList();
    // Filter invoices for this patient
    final patientInvoices = clinic.invoices.where((inv) => inv.patientId == patient.id).toList();

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
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient Profile', style: AppTextStyles.h2),
                  Text('Clinic File #${patient.id}', style: AppTextStyles.caption),
                ],
              ),
              const Spacer(),
              AppButton.outline(
                text: 'Schedule Visit',
                icon: Icons.calendar_today_outlined,
                onPressed: () => AddAppointmentDialog.show(context, initialPatientId: patient.id),
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
                    patient.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
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
                          Text(patient.name, style: AppTextStyles.h2),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              patient.crNumber.isNotEmpty ? 'CR: ${patient.crNumber}' : 'CR: ${patient.id}',
                              style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Blood: ${patient.bloodGroup}',
                              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${patient.gender}${patient.age.isNotEmpty ? ' / ${patient.age} yrs' : ''} • DOB: ${patient.dateOfBirth} • Registered: ${DateFormat('dd MMM yyyy').format(patient.registrationDate)}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(patient.address, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),

                // Contact Details Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(patient.phone, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(patient.email, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

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
                      Text(patient.assignedDoctorName, style: AppTextStyles.h4),
                      const SizedBox(height: 4),
                      Text('Emergency: ${patient.emergencyContact}', style: AppTextStyles.caption),
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
                      Text('${patient.totalVisits} Total Visits', style: AppTextStyles.h4),
                      const SizedBox(height: 4),
                      Text('Last: ${patient.lastVisit} • Next: ${patient.nextAppointment ?? 'None scheduled'}', style: AppTextStyles.caption),
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
                        patient.balanceDue > 0 ? currency.format(patient.balanceDue) : 'All Paid (₹0)',
                        style: AppTextStyles.h4.copyWith(
                          color: patient.balanceDue > 0 ? const Color(0xFFDC2626) : const Color(0xFF047857),
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

          if (patient.allergies.isNotEmpty || patient.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            AppCard(
              title: 'Reception & Medical Alerts',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (patient.allergies.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Text('Allergies & Sensitivities: ', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        ...patient.allergies.map((alg) => Container(
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
                  if (patient.notes.isNotEmpty)
                    Text('Notes: ${patient.notes}', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Appointment History Table
          AppCard(
            title: 'Appointment History',
            subtitle: 'Past and upcoming bookings for this patient',
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
                            child: Text(apt.timeString, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${apt.appointmentType} with ${apt.doctorName}', style: AppTextStyles.h4.copyWith(fontSize: 14)),
                                Text('Token: ${apt.tokenNumber} • Notes: ${apt.notes.isEmpty ? 'None' : apt.notes}', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          StatusBadge.fromAppointmentStatus(apt.status),
                        ],
                      );
                    },
                  ),
          ),

          const SizedBox(height: 20),

          // Billing History Table
          AppCard(
            title: 'Billing & Invoices',
            subtitle: 'Payment records and receipts',
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
                              Text(currency.format(inv.totalAmount), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
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
      ),
    );
  }
}
