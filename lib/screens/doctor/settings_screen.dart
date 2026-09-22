import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _appointmentReminders = true;
  bool _visitAlerts = true;
  bool _arrivalChime = true;
  String _themeMode = 'Light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doctor Workstation Settings', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            const Text('Clinical notifications, preferences and display settings', style: AppTextStyles.caption),
            const SizedBox(height: 20),

            // Notification Preferences
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Alerts & Reminders', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Real-time alerts for incoming schedule changes', style: AppTextStyles.caption),
                    value: _pushNotifications,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  const Divider(color: AppColors.borderLight),
                  SwitchListTile(
                    title: const Text('Appointment Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Alert 10 minutes prior to scheduled patient arrival', style: AppTextStyles.caption),
                    value: _appointmentReminders,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _appointmentReminders = v),
                  ),
                  const Divider(color: AppColors.borderLight),
                  SwitchListTile(
                    title: const Text('Waiting Room Arrival Chime', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Play gentle notification chime when patient checks in', style: AppTextStyles.caption),
                    value: _arrivalChime,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _arrivalChime = v),
                  ),
                  const Divider(color: AppColors.borderLight),
                  SwitchListTile(
                    title: const Text('Visit Record Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Notification when a completed visit is saved', style: AppTextStyles.caption),
                    value: _visitAlerts,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _visitAlerts = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Display & Theme Preferences
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Display & Interface Appearance', style: AppTextStyles.h4),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Theme Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      DropdownButton<String>(
                        value: _themeMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'Light', child: Text('Light Clean')),
                          DropdownMenuItem(value: 'Dark', child: Text('Dark Mode')),
                          DropdownMenuItem(value: 'System', child: Text('System Default')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _themeMode = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // App Info & Security
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('System & Security', style: AppTextStyles.h4),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline, color: AppColors.primary),
                    title: const Text('About SmileCare OS (Doctor Edition)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Version 2.4.0 (Commercial Build)', style: AppTextStyles.caption),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                  const Divider(color: AppColors.borderLight),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                    title: const Text('Doctor Session Authentication', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Dr. Sharma • Chair 01 Console Session Active', style: AppTextStyles.caption),
                    trailing: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Sign Out', style: TextStyle(color: Color(0xFFDC2626))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
