import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';
import 'visit_notes_screen.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String patientName;
  final String initials;
  final String time;
  final String reason;
  final String status;

  const AppointmentDetailsScreen({
    super.key,
    this.patientName = 'Aarav Mehta',
    this.initials = 'AM',
    this.time = '09:30 AM',
    this.reason = 'Regular Check-up & Scaling',
    this.status = 'Confirmed',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointment Details'),
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Patient ID: PT-00124 • Male, 28 yrs',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '+91 98765 43210',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == 'In Chair'
                          ? const Color(0xFFEDE9FE)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: status == 'In Chair'
                            ? const Color(0xFF6D28D9)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Visit Details Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consultation Information', style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  _detailRow(Icons.calendar_month_outlined, 'Scheduled Date & Time', 'Today, 11 Sep 2026 • $time'),
                  const SizedBox(height: 14),
                  _detailRow(Icons.medical_services_outlined, 'Consulting Specialist', 'Dr. Sharma (Orthodontics)'),
                  const SizedBox(height: 14),
                  _detailRow(Icons.chair_outlined, 'Operatory & Room', 'Operatory 01 • Dental Unit A'),
                  const SizedBox(height: 14),
                  _detailRow(Icons.healing_outlined, 'Procedure / Reason', reason),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Clinical Notes
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Pre-Consultation Notes', style: AppTextStyles.h4),
                  SizedBox(height: 10),
                  Text(
                    'Patient reported mild sensitivity in upper left molar during cold drinks. No known drug allergies. Last visit completed 6 months ago for routine scaling.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: AppButton(
                text: 'Start Clinical Consultation',
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VisitNotesScreen(
                        patientName: patientName,
                        appointmentReason: reason,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: 'Reschedule',
                    icon: Icons.edit_calendar_outlined,
                    onPressed: () => AddAppointmentDialog.show(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.danger(
                    text: 'Cancel Appointment',
                    icon: Icons.close_rounded,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Appointment?'),
                          content: const Text('Are you sure you want to cancel this scheduled appointment?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('No, Keep'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Appointment has been cancelled')),
                                );
                              },
                              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}