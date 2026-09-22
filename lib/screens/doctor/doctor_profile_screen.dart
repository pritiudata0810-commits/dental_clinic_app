import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Banner Card
            AppCard(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'DS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dr. Sharma', style: AppTextStyles.h2),
                        const SizedBox(height: 3),
                        const Text('BDS, MDS (Orthodontics & Dentofacial Orthopedics)', style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('12+ Years Experience', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                            ),
                            const SizedBox(width: 8),
                            const Text('Reg No: DCI-MH-45892', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Professional Credentials Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Professional Credentials & Specialization', style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  _profileItem(Icons.school_outlined, 'Academic Qualifications', 'BDS - Nair Hospital Dental College, Mumbai (2012)\nMDS - Government Dental College & Hospital, Mumbai (2015)'),
                  const SizedBox(height: 14),
                  _profileItem(Icons.verified_outlined, 'Clinical Focus Areas', 'Fixed Orthodontics, Clear Aligners (Invisalign Certified), Adult Orthodontics, Lingual Braces, Growth Modulation'),
                  const SizedBox(height: 14),
                  _profileItem(Icons.access_time_rounded, 'Consultation Hours', 'Monday – Saturday: 09:30 AM – 01:30 PM & 04:30 PM – 08:30 PM\nSunday: Operatory by Prior Appointment Only'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Operatory & Contact Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinic Operatory & Contact Information', style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  _profileItem(Icons.chair_outlined, 'Assigned Clinical Operatory', 'Operatory 01 • Advanced Dental Chair Unit A (High Speed Suction & Intraoral Scanner equipped)'),
                  const SizedBox(height: 14),
                  _profileItem(Icons.phone_outlined, 'Direct Consultation Line', '+91 98230 87654 (Ext. 101)'),
                  const SizedBox(height: 14),
                  _profileItem(Icons.email_outlined, 'Official Professional Email', 'dr.sharma@sharmadentalclinic.com'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _profileItem(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.caption),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
