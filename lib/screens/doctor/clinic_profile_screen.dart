import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';

class ClinicProfileScreen extends StatelessWidget {
  const ClinicProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dental Clinic Profile'),
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
            // Clinic Header Card
            AppCard(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      size: 32,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Sharma Dental Clinic & Implant Centre', style: AppTextStyles.h3),
                        SizedBox(height: 3),
                        Text('Govt Reg No: MH/PUN/CLN/2018/0942', style: AppTextStyles.caption),
                        SizedBox(height: 2),
                        Text('ISO 9001:2015 Certified Dental Healthcare Center', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Infrastructure Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Infrastructure & Operatories', style: AppTextStyles.h4),
                  const SizedBox(height: 14),
                  _clinicItem(Icons.chair_outlined, 'Dental Operatories', '3 Fully Equipped Modern Dental Operatory Units (Chairs 01, 02, 03)'),
                  const SizedBox(height: 12),
                  _clinicItem(Icons.camera_indoor_outlined, 'Diagnostic Imaging', 'In-house Digital OPG, RVG Sensor (Intraoral Radiography), Intraoral Camera HD'),
                  const SizedBox(height: 12),
                  _clinicItem(Icons.cleaning_services_outlined, 'Sterilization Facility', 'Class B Autoclave, Ultrasonic Instrument Cleaner, UV Sterilization Cabinets'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Timings & Location Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Working Hours & Practice Location', style: AppTextStyles.h4),
                  const SizedBox(height: 14),
                  _clinicItem(Icons.location_on_outlined, 'Clinic Address', 'Suite 102, Fortune Plaza, Shivaji Nagar, Pune, Maharashtra 411005'),
                  const SizedBox(height: 12),
                  _clinicItem(Icons.access_time_rounded, 'OPD Operating Hours', 'Mon – Sat: 09:00 AM – 09:00 PM\nSunday: 10:00 AM – 02:00 PM (Emergency & Prior Booking Only)'),
                  const SizedBox(height: 12),
                  _clinicItem(Icons.phone_outlined, 'Reception & Emergency Helpdesk', '+91 20 2553 4567 • Emergency: +91 98230 11223'),
                  const SizedBox(height: 12),
                  _clinicItem(Icons.language_outlined, 'Official Web Portal', 'https://sharmadentalclinic.com'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _clinicItem(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
