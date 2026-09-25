import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';
import '../../widgets/billing/invoice_preview_dialog.dart';
import '../../state/clinic_scope.dart';
import '../../models/patient.dart';
import 'edit_patient_screen.dart';
import 'visit_notes_screen.dart';

class PatientProfileScreen extends StatelessWidget {
  final String patientName;
  final String initials;
  final String age;
  final String gender;
  final String phone;
  final Patient? patient;

  const PatientProfileScreen({
    super.key,
    this.patientName = 'Aarav Mehta',
    this.initials = 'AM',
    this.age = '28',
    this.gender = 'Male',
    this.phone = '+91 98765 43210',
    this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    // Look up real patient from clinic state if available
    final matchedPatient = patient ??
        clinic.patients.cast<Patient?>().firstWhere(
          (p) => p?.name.toLowerCase() == patientName.toLowerCase() || p?.phone == phone,
          orElse: () => null,
        );

    final effectiveName = matchedPatient?.name ?? patientName;
    final effectiveInitials = matchedPatient != null && matchedPatient.name.isNotEmpty
        ? matchedPatient.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : initials;
    final effectiveAge = matchedPatient?.age.isNotEmpty == true ? matchedPatient!.age : age;
    final effectiveGender = matchedPatient?.gender ?? gender;
    final effectivePhone = matchedPatient?.phone ?? phone;
    final effectiveEmail = matchedPatient?.email.isNotEmpty == true ? matchedPatient!.email : 'aarav.mehta@email.com';
    final effectiveAddress = matchedPatient?.address.isNotEmpty == true ? matchedPatient!.address : 'Tapovan, Rishikesh, Uttarakhand';
    final effectiveCR = matchedPatient?.crNumber.isNotEmpty == true ? matchedPatient!.crNumber : '20230212937';
    final effectiveBlood = matchedPatient?.bloodGroup ?? 'O+';
    final effectiveAllergies = matchedPatient?.allergies.isNotEmpty == true
        ? matchedPatient!.allergies
        : ['Penicillin (Mild Rash)'];

    // Invoices for this patient
    final patientInvoices = clinic.invoices.where(
      (inv) => inv.patientName.toLowerCase() == effectiveName.toLowerCase() || inv.patientId == matchedPatient?.id,
    ).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clinical Patient Profile & Medical Record'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          effectiveInitials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(effectiveName, style: AppTextStyles.h2),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'CR: $effectiveCR',
                                    style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient ID: ${matchedPatient?.id ?? 'P-1001'} • Central Clinic Registry',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _headerStat('Age', '$effectiveAge yrs'),
                      _verticalDivider(),
                      _headerStat('Gender', effectiveGender),
                      _verticalDivider(),
                      _headerStat('Blood Group', effectiveBlood),
                      _verticalDivider(),
                      _headerStat('Total Visits', '${matchedPatient?.totalVisits ?? 4}'),
                      _verticalDivider(),
                      _headerStat('Status', 'Active Treatment'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: 'Edit Patient',
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditPatientScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Book Visit',
                    icon: Icons.calendar_month_outlined,
                    onPressed: () => AddAppointmentDialog.show(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start New Clinical Consultation', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VisitNotesScreen(patientName: effectiveName),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // CLINICAL VITALS CARD (Matching the real medical slip reference)
            AppCard(
              title: 'Clinical Vitals (Latest Encounter)',
              subtitle: 'Recorded during preliminary screening',
              child: Row(
                children: [
                  _vitalItem('Temperature', '95.6 °F', Icons.thermostat_outlined, const Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  _vitalItem('SpO2', '96 %', Icons.air_outlined, const Color(0xFF0284C7)),
                  const SizedBox(width: 12),
                  _vitalItem('Pulse', '74 bpm', Icons.favorite_outline, const Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  _vitalItem('BP', '120/80', Icons.speed_outlined, const Color(0xFF10B981)),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Contact Information
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact Information', style: AppTextStyles.h4),
                  const SizedBox(height: 14),
                  _infoRow(Icons.phone_outlined, 'Mobile Number', effectivePhone),
                  const SizedBox(height: 12),
                  _infoRow(Icons.email_outlined, 'Email Address', effectiveEmail),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on_outlined, 'Residential Address', effectiveAddress),
                  const SizedBox(height: 12),
                  _infoRow(Icons.contact_phone_outlined, 'Emergency Contact / Guardian', matchedPatient?.emergencyContact ?? 'Priya Mehta (Spouse) • +91 98765 12345'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Medical Information & Alerts
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Medical History & Clinical Alerts', style: AppTextStyles.h4),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Alert Active',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _medicalItem('Known Allergies', effectiveAllergies.join(', ')),
                  const SizedBox(height: 10),
                  _medicalItem('Medical Alerts & Chronic Conditions', 'Mild Hypertension • Check BP before surgical extractions'),
                  const SizedBox(height: 10),
                  _medicalItem('Current Medications', 'Tab Amlodipine 5mg OD • Multivitamin supplement'),
                  const SizedBox(height: 10),
                  _medicalItem('Blood Group', effectiveBlood),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent Visits History
            const Text('Recent Clinical Visits & Operative History', style: AppTextStyles.h4),
            const SizedBox(height: 10),

            _visitHistoryCard(
              date: '13 Feb 2026',
              code: '2023021340074-RCT',
              reason: 'Root Canal Treatment (Step 2 Obturation) #46',
              doctor: 'Dr. Rahul Sharma',
              notes: 'Working length confirmed. Gutta-percha obturation completed. Temporary Cavit restoration placed.',
            ),
            const SizedBox(height: 10),
            _visitHistoryCard(
              date: '04 Sep 2026',
              code: '2023021340071-SCL',
              reason: 'Full Mouth Ultrasonic Scaling & Root Planing',
              doctor: 'Dr. Rahul Sharma',
              notes: 'Full mouth scaling completed. Subgingival irrigation with povidone-iodine. Chlorhexidine prescribed.',
            ),

            const SizedBox(height: 20),

            // Patient Billing & Printable Receipts
            AppCard(
              title: 'Billing & Printable Receipts',
              subtitle: 'Official financial records for this patient',
              child: patientInvoices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No invoices recorded yet for this patient.', style: TextStyle(color: AppColors.textSecondary)),
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
                              child: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primaryDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(
                                    inv.items.map((e) => e.description).join(', '),
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text('₹${inv.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(width: 12),
                            AppButton(
                              text: 'Print Bill',
                              icon: Icons.print_outlined,
                              height: 32,
                              onPressed: () => InvoicePreviewDialog.show(context, inv),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _vitalItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  static Widget _headerStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  static Widget _verticalDivider() {
    return Container(height: 28, width: 1, color: AppColors.borderLight);
  }

  static Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _medicalItem(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  static Widget _visitHistoryCard({
    required String date,
    required String code,
    required String reason,
    required String doctor,
    required String notes,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                  ),
                ],
              ),
              Text(doctor, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          Text(reason, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(notes, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
