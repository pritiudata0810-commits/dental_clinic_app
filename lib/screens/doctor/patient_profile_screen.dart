import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';
import 'edit_patient_screen.dart';
import 'visit_notes_screen.dart';

class PatientProfileScreen extends StatelessWidget {
  final String patientName;
  final String initials;
  final String age;
  final String gender;
  final String phone;

  const PatientProfileScreen({
    super.key,
    this.patientName = 'Aarav Mehta',
    this.initials = 'AM',
    this.age = '28',
    this.gender = 'Male',
    this.phone = '+91 98765 43210',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clinical Patient Profile'),
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
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    patientName,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Patient ID: PT-00124 • Registered Clinic Patient',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _headerStat('Age', '$age yrs'),
                      _verticalDivider(),
                      _headerStat('Gender', gender),
                      _verticalDivider(),
                      _headerStat('Total Visits', '12'),
                      _verticalDivider(),
                      _headerStat('Status', 'Active'),
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
                      builder: (_) => VisitNotesScreen(patientName: patientName),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            // Contact Information
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact Information', style: AppTextStyles.h4),
                  const SizedBox(height: 14),
                  _infoRow(Icons.phone_outlined, 'Mobile Number', phone),
                  const SizedBox(height: 12),
                  _infoRow(Icons.email_outlined, 'Email Address', 'aarav.mehta@email.com'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on_outlined, 'Residential Address', 'B-402, Green Park Avenue, Pune, MH'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.contact_phone_outlined, 'Emergency Contact', 'Priya Mehta (Spouse) • +91 98765 12345'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Medical Information
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Medical History & Alerts', style: AppTextStyles.h4),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Allergy Alert',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _medicalItem('Known Allergies', 'Penicillin (Mild Rash) • No Local Anesthesia sensitivity reported'),
                  const SizedBox(height: 10),
                  _medicalItem('Chronic Conditions', 'Mild Hypertension (Managed with Amlodipine 5mg)'),
                  const SizedBox(height: 10),
                  _medicalItem('Current Medications', 'Tab Amlodipine 5mg OD • Multivitamin supplement'),
                  const SizedBox(height: 10),
                  _medicalItem('Blood Group', 'O Positive (O+)'),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Recent Visits History
            const Text('Recent Clinical Visits', style: AppTextStyles.h4),
            const SizedBox(height: 10),

            _visitHistoryCard(
              date: '04 Sep 2026',
              reason: 'Scaling & Root Planing',
              doctor: 'Dr. Sharma',
              notes: 'Full mouth ultrasonic scaling completed. Chlorhexidine mouthwash prescribed.',
            ),
            const SizedBox(height: 10),
            _visitHistoryCard(
              date: '12 May 2026',
              reason: 'Composite Restoration (Teeth #24, #25)',
              doctor: 'Dr. Sharma',
              notes: 'Caries excavated. Class II composite restorations placed and polished.',
            ),
            const SizedBox(height: 10),
            _visitHistoryCard(
              date: '15 Jan 2026',
              reason: 'Routine Preventive Examination',
              doctor: 'Dr. Patel',
              notes: 'OPG X-Ray taken. Mild supragingival plaque detected. Advised flossing.',
            ),
          ],
        ),
      ),
    );
  }

  static Widget _headerStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
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
              Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              Text(doctor, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 4),
          Text(reason, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(notes, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}