import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';
import '../../state/clinic_scope.dart';
import '../../models/appointment.dart';
import 'appointment_details_screen.dart';
import 'notifications_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _selectedDayIndex = 1; // Wednesday (Today)
  String _selectedFilter = 'All';

  final List<Map<String, String>> _dates = const [
    {'day': '10', 'weekday': 'Tue'},
    {'day': '11', 'weekday': 'Wed'},
    {'day': '12', 'weekday': 'Thu'},
    {'day': '13', 'weekday': 'Fri'},
    {'day': '14', 'weekday': 'Sat'},
    {'day': '15', 'weekday': 'Sun'},
    {'day': '16', 'weekday': 'Mon'},
  ];

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final liveApts = clinic.appointments;

    // Filter appointments
    final displayList = liveApts.isNotEmpty
        ? liveApts.map((a) {
            final initials = a.patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
            return {
              'time': a.timeString,
              'patient': a.patientName,
              'reason': a.appointmentType,
              'status': a.status == AppointmentStatus.scheduled || a.status == AppointmentStatus.confirmed
                  ? 'Confirmed'
                  : (a.status == AppointmentStatus.waiting || a.status == AppointmentStatus.arrived || a.status == AppointmentStatus.checkedIn
                      ? 'Pending'
                      : a.status.label),
              'initials': initials.isNotEmpty ? initials : 'PT',
            };
          }).toList()
        : [
            {
              'time': '09:30 AM',
              'patient': 'Aarav Mehta',
              'reason': 'Regular Check-up & Scaling',
              'status': 'Confirmed',
              'initials': 'AM',
            },
            {
              'time': '10:30 AM',
              'patient': 'Ananya Patil',
              'reason': 'Dental Cleaning & Polishing',
              'status': 'Confirmed',
              'initials': 'AP',
            },
            {
              'time': '11:30 AM',
              'patient': 'Rohan Deshmukh',
              'reason': 'Tooth Pain & RCT Consultation',
              'status': 'Pending',
              'initials': 'RD',
            },
            {
              'time': '01:00 PM',
              'patient': 'Sneha Kulkarni',
              'reason': 'Orthodontic Wire Adjustment',
              'status': 'Confirmed',
              'initials': 'SK',
            },
            {
              'time': '03:00 PM',
              'patient': 'Vedant Joshi',
              'reason': 'Tooth Sensitivity Assessment',
              'status': 'Pending',
              'initials': 'VJ',
            },
            {
              'time': '04:30 PM',
              'patient': 'Kavita Iyer',
              'reason': 'Crown Fitting & Check',
              'status': 'Confirmed',
              'initials': 'KI',
            },
          ];

    final filteredList = _selectedFilter == 'All'
        ? displayList
        : displayList.where((a) => a['status'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Appointments',
                        style: AppTextStyles.h3,
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Manage consultation schedule & operatory queue',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                  tooltip: 'Doctor Alerts',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => AddAppointmentDialog.show(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Book Appointment'),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Date Selector Strip
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = _dates[index];
                  final isSelected = _selectedDayIndex == index;

                  return InkWell(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryDark : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryDark : AppColors.border,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['weekday']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['day']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Filter Tabs & Summary Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Wed, 11 Sep • ${filteredList.length} Appointments',
                    style: AppTextStyles.h4,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: ['All', 'Confirmed', 'Pending'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = filter);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Appointments List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = filteredList[index];
                final isConfirmed = item['status'] == 'Confirmed';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailsScreen(
                          patientName: item['patient']!,
                          initials: item['initials']!,
                          time: item['time']!,
                          reason: item['reason']!,
                          status: item['status']!,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            item['initials']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['patient']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['reason']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: isConfirmed
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['status']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isConfirmed
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['time']!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}