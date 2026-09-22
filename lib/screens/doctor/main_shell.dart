import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';
import 'dashboard_screen.dart';
import 'appointments_screen.dart';
import 'patients_screen.dart';
import 'visit_notes_screen.dart';
import 'doctor_profile_screen.dart';
import 'clinic_profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex;
  bool _isCollapsed = false;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AppointmentsScreen(),
    PatientsScreen(),
    VisitNotesScreen(),
    DoctorProfileScreen(),
    ClinicProfileScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final autoCollapse = screenWidth < 1024;
    final effectiveCollapsed = _isCollapsed || autoCollapse;

    final navItems = [
      {'title': 'Clinical Dashboard', 'icon': Icons.dashboard_outlined, 'index': 0},
      {'title': 'Appointments', 'icon': Icons.calendar_month_outlined, 'index': 1},
      {'title': 'My Patients', 'icon': Icons.people_alt_outlined, 'index': 2},
      {'title': 'Clinical Consultation', 'icon': Icons.note_alt_outlined, 'index': 3},
      {'title': 'Doctor Profile', 'icon': Icons.badge_outlined, 'index': 4},
      {'title': 'Clinic Profile', 'icon': Icons.local_hospital_outlined, 'index': 5},
      {'title': 'Notifications', 'icon': Icons.notifications_outlined, 'index': 6},
      {'title': 'Settings', 'icon': Icons.settings_outlined, 'index': 7},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Doctor Dedicated Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: effectiveCollapsed ? 76 : 260,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Brand Header
                Container(
                  height: 70,
                  padding: EdgeInsets.symmetric(horizontal: effectiveCollapsed ? 12 : 18),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: Row(
                    mainAxisAlignment: effectiveCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (!effectiveCollapsed) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SmileCare OS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                'Doctor Clinical Portal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Navigation Items
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    itemCount: navItems.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      final itemIdx = item['index'] as int;
                      final isSelected = _selectedIndex == itemIdx;

                      return Tooltip(
                        message: effectiveCollapsed ? (item['title'] as String) : '',
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = itemIdx),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 44,
                            padding: EdgeInsets.symmetric(horizontal: effectiveCollapsed ? 0 : 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: effectiveCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  size: 20,
                                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                                ),
                                if (!effectiveCollapsed) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Doctor Session Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: effectiveCollapsed
                      ? IconButton(
                          icon: const Icon(Icons.logout, size: 20, color: AppColors.textMuted),
                          tooltip: 'Sign Out',
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                        )
                      : Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryLight,
                              child: Text('DS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dr. Sharma', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                                  Text('Chair 01 • Active', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, size: 18, color: AppColors.textMuted),
                              tooltip: 'Sign Out',
                              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // Main Doctor Console Workspace
          Expanded(
            child: Column(
              children: [
                // Doctor Top Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(effectiveCollapsed ? Icons.menu : Icons.menu_open, size: 20),
                        tooltip: effectiveCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                        onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              navItems[_selectedIndex]['title'] as String,
                              style: AppTextStyles.h3.copyWith(fontSize: 17),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Operatory 01 • Dr. Sharma Consultation Console',
                              style: AppTextStyles.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Responsive Action: Book Appointment
                      if (screenWidth >= 880) ...[
                        AppButton.outline(
                          text: '+ New Appointment',
                          height: 36,
                          icon: Icons.calendar_today,
                          onPressed: () => AddAppointmentDialog.show(context),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                          tooltip: 'New Appointment',
                          onPressed: () => AddAppointmentDialog.show(context),
                        ),
                      ],

                      // Responsive Action: Start Consultation
                      if (screenWidth >= 720) ...[
                        AppButton(
                          text: 'Start Consultation',
                          height: 36,
                          icon: Icons.play_arrow_rounded,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VisitNotesScreen()),
                            );
                          },
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill, size: 22, color: AppColors.primary),
                          tooltip: 'Start Consultation',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VisitNotesScreen()),
                            );
                          },
                        ),
                      ],

                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.textPrimary),
                        tooltip: 'Doctor Alerts',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Active Doctor Screen Body
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
