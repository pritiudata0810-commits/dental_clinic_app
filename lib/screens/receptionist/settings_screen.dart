import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/toast_notification.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Theme & Appearance
  String _themeMode = 'Light';
  String _uiDensity = 'Comfortable';
  Color _accentColor = AppColors.primary;

  // Regional & Date/Time
  String _timeFormat = '12-Hour';
  String _dateFormat = 'DD/MM/YYYY';

  // Notifications & Sound
  bool _arrivalChime = true;
  bool _longWaitAlert = true;
  bool _doctorStatusNotification = true;
  double _soundVolume = 0.8;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('Application & Workstation Settings', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            'Configure display theme, regional date/time formats, audio notifications, and active front-desk session',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 24),

          // 1. Theme & Appearance
          AppCard(
            title: 'Appearance & Display',
            subtitle: 'Visual theme, interface layout density, and accent styling',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThemeSelector(),
                const Divider(color: AppColors.borderLight, height: 28),
                _buildDensitySelector(),
                const Divider(color: AppColors.borderLight, height: 28),
                _buildAccentColorSelector(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Date, Time & Regional Preferences
          AppCard(
            title: 'Regional & Date / Time Formats',
            subtitle: 'Configure how dates, appointment slots, and clock times are displayed',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeFormatSelector(),
                const Divider(color: AppColors.borderLight, height: 28),
                _buildDateFormatSelector(),
                const Divider(color: AppColors.borderLight, height: 28),
                _buildCurrencyRow(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Audio & Workstation Alerts
          AppCard(
            title: 'Audio & Real-time Alerts',
            subtitle: 'Front-desk notifications when patients arrive or waiting times exceed threshold',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Patient Arrival Chime', style: AppTextStyles.bodyMedium),
                  subtitle: const Text('Play gentle workstation chime when a patient checks in at reception', style: AppTextStyles.caption),
                  value: _arrivalChime,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _arrivalChime = v),
                ),
                const Divider(color: AppColors.borderLight),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Extended Waiting Time Warning', style: AppTextStyles.bodyMedium),
                  subtitle: const Text('Highlight patient badge when waiting time in queue exceeds 20 minutes', style: AppTextStyles.caption),
                  value: _longWaitAlert,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _longWaitAlert = v),
                ),
                const Divider(color: AppColors.borderLight),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Doctor Operatory Status Alerts', style: AppTextStyles.bodyMedium),
                  subtitle: const Text('Instant notification banner when doctor marks chair ready for next patient', style: AppTextStyles.caption),
                  value: _doctorStatusNotification,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _doctorStatusNotification = v),
                ),
                if (_arrivalChime) ...[
                  const Divider(color: AppColors.borderLight),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_up, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        const Text('Alert Volume', style: AppTextStyles.bodyMedium),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _soundVolume,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _soundVolume = v),
                          ),
                        ),
                        Text('${(_soundVolume * 100).toInt()}%', style: AppTextStyles.label),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Receptionist Account & Workstation Session
          AppCard(
            title: 'Receptionist Session & Workstation Info',
            subtitle: 'Logged-in front-desk account credentials and station network status',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 620;
                return Column(
                  children: [
                    if (isNarrow) ...[
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primaryLight,
                            child: Text('SD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sunita Deshmukh', style: AppTextStyles.h4),
                                Text('Staff ID: REC-102 • Workstation: DESK-01', style: AppTextStyles.caption),
                                const Text('receptionist@smilecare.com', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primaryLight,
                            child: Text('SD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sunita Deshmukh', style: AppTextStyles.h4),
                                Text('Staff ID: REC-102 • Workstation: DESK-01 (Front Desk Primary)', style: AppTextStyles.caption),
                                const Text('Email: receptionist@smilecare.com', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                                SizedBox(width: 6),
                                Text('LAN Connected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(color: AppColors.borderLight, height: 28),
                    _buildWorkstationDetailRow('Active Session Since', 'Today, 08:45 AM (4h 32m elapsed)'),
                    _buildWorkstationDetailRow('Terminal IP Address', '192.168.1.45 (Dental Intra-LAN)'),
                    _buildWorkstationDetailRow('Software Build', 'v2.4.1 (Stable Clinic Release)'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        AppButton.outline(
                          text: 'Clear Cache',
                          icon: Icons.cleaning_services_outlined,
                          onPressed: () => AppFeedback.showInfo(context, 'Local cache cleared successfully.'),
                        ),
                        AppButton.outline(
                          text: 'Reset Defaults',
                          icon: Icons.restart_alt_outlined,
                          onPressed: () {
                            setState(() {
                              _themeMode = 'Light';
                              _uiDensity = 'Comfortable';
                              _timeFormat = '12-Hour';
                              _dateFormat = 'DD/MM/YYYY';
                              _arrivalChime = true;
                              _longWaitAlert = true;
                              _doctorStatusNotification = true;
                              _soundVolume = 0.8;
                            });
                            AppFeedback.showSuccess(context, 'Preferences reset to clinic defaults.');
                          },
                        ),
                        AppButton.danger(
                          text: 'Sign Out Workstation',
                          icon: Icons.logout,
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/login');
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Save Button Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                text: 'Apply Settings',
                icon: Icons.check,
                onPressed: () {
                  AppFeedback.showSuccess(context, 'Application settings applied and saved successfully!');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color Theme', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: ['Light', 'Dark', 'System'].map((mode) {
            final isSelected = _themeMode == mode;
            return ChoiceChip(
              label: Text(mode),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _themeMode = mode),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDensitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Display Density', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            {'name': 'Comfortable', 'desc': 'Larger touch targets and relaxed padding'},
            {'name': 'Compact', 'desc': 'Higher information density for fast front desk entry'},
          ].map((item) {
            final name = item['name']!;
            final isSelected = _uiDensity == name;
            return ChoiceChip(
              label: Text(name),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _uiDensity = name),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccentColorSelector() {
    final colors = [
      {'name': 'Dental Blue', 'color': AppColors.primary},
      {'name': 'Soft Teal', 'color': AppColors.accent},
      {'name': 'Clinical Indigo', 'color': const Color(0xFF4F46E5)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Accent Color', style: AppTextStyles.label),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: colors.map((item) {
            final col = item['color'] as Color;
            final isSelected = _accentColor == col;
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _accentColor = col),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? col : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? col.withValues(alpha: 0.1) : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 7, backgroundColor: col),
                    const SizedBox(width: 8),
                    Text(item['name'] as String, style: AppTextStyles.bodySmall.copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time Display Format', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            {'format': '12-Hour', 'example': '02:30 PM'},
            {'format': '24-Hour', 'example': '14:30'},
          ].map((item) {
            final isSelected = _timeFormat == item['format'];
            return ChoiceChip(
              label: Text('${item['format']} (${item['example']})'),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _timeFormat = item['format']!),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Calendar Date Format', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            {'format': 'DD/MM/YYYY', 'example': '20/09/2026'},
            {'format': 'MM/DD/YYYY', 'example': '09/20/2026'},
            {'format': 'YYYY-MM-DD', 'example': '2026-09-20'},
          ].map((item) {
            final isSelected = _dateFormat == item['format'];
            return ChoiceChip(
              label: Text('${item['format']} (${item['example']})'),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _dateFormat = item['format']!),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCurrencyRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Currency Symbol & Locale', style: AppTextStyles.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('₹ INR (Indian Rupee)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkstationDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
