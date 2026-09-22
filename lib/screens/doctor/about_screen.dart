import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About Dental Application'),
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
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      size: 36,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('SmileCare OS', style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  const Text('Doctor Clinical Edition • v2.4.0', style: AppTextStyles.caption),
                ],
              ),
            ),

            const SizedBox(height: 24),

            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Application Overview', style: AppTextStyles.h4),
                  SizedBox(height: 10),
                  Text(
                    'SmileCare OS is a comprehensive dental clinic operating system designed for streamlined clinical consultations, multi-operatory queue management, treatment planning, digital prescription generation, and electronic health records management.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('System Information & License', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _infoRow('Version', '2.4.0-stable'),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _infoRow('Framework', 'Flutter 3.47 / Dart 3.10'),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _infoRow('Data Store', 'ClinicState In-Memory Cache'),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _infoRow('Commercial License', 'Sharma Dental Clinic (Single Practice Enterprise)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
