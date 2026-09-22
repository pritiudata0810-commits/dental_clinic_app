import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';

class DoctorIntegrationScreen extends StatelessWidget {
  const DoctorIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Doctor Portal — Integration Point', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppButton.outline(
              text: 'Open Receptionist Dashboard',
              icon: Icons.meeting_room_outlined,
              onPressed: () => Navigator.of(context).pushReplacementNamed('/receptionist'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    size: 40,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Doctor Dashboard Integration Route',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Text(
                    'Your existing Doctor Dashboard repository will be merged at this exact route. All domain models, patient records, and appointment contracts built in this project are 100% interoperable.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Integration Features Checklist
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hub_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text('Shared Schema & Integration Contracts', style: AppTextStyles.h4),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildContractItem(
                        icon: Icons.person_outline,
                        title: 'Patient Model & Profiles',
                        desc: 'Shared patient IDs (P-1001), medical notes, allergy flags, and contact info.',
                      ),
                      _buildContractItem(
                        icon: Icons.calendar_month_outlined,
                        title: 'Appointment Status Lifecycle',
                        desc: 'Scheduled ➔ Arrived ➔ Checked In ➔ Waiting ➔ With Doctor ➔ Completed.',
                      ),
                      _buildContractItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'Billing & Invoice Generation',
                        desc: 'Treatments entered by doctor flow directly to receptionist billing in ₹ (INR).',
                      ),
                      _buildContractItem(
                        icon: Icons.mark_chat_unread_outlined,
                        title: 'Doctor Availability Sync',
                        desc: 'Real-time toggle for Operatories 1, 2, and 3 (Available, In Consultation, Break).',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      text: 'Switch to Receptionist Dashboard',
                      icon: Icons.dashboard_customize_outlined,
                      height: 44,
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/receptionist'),
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

  Widget _buildContractItem({required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(desc, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF10B981)),
        ],
      ),
    );
  }
}
