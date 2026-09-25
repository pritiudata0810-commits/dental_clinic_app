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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

  static const List<Map<String, dynamic>> _navItems = [
    {'title': 'Clinical Dashboard', 'icon': Icons.dashboard_outlined, 'index': 0},
    {'title': 'Appointments', 'icon': Icons.calendar_month_outlined, 'index': 1},
    {'title': 'My Patients', 'icon': Icons.people_alt_outlined, 'index': 2},
    {'title': 'Clinical Consultation', 'icon': Icons.note_alt_outlined, 'index': 3},
    {'title': 'Doctor Profile', 'icon': Icons.badge_outlined, 'index': 4},
    {'title': 'Clinic Profile', 'icon': Icons.local_hospital_outlined, 'index': 5},
    {'title': 'Notifications', 'icon': Icons.notifications_outlined, 'index': 6},
    {'title': 'Settings', 'icon': Icons.settings_outlined, 'index': 7},
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Widget _buildDoctorSidebar(bool effectiveCollapsed, {bool inDrawer = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: effectiveCollapsed ? 80 : 250,
      decoration: const BoxDecoration(
        color: Color(0xFF5856D6),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Brand Header
          Container(
            height: 74,
            padding: EdgeInsets.symmetric(horizontal: effectiveCollapsed ? 14 : 18),
            child: Row(
              mainAxisAlignment: effectiveCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Color(0xFF5856D6),
                    size: 22,
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
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
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
                            color: Color(0xFFD6D5F7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Navigation Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _navItems.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final itemIdx = item['index'] as int;
                final isSelected = _selectedIndex == itemIdx;

                return Tooltip(
                  message: effectiveCollapsed ? (item['title'] as String) : '',
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedIndex = itemIdx);
                      if (inDrawer) {
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      height: 44,
                      padding: EdgeInsets.symmetric(horizontal: effectiveCollapsed ? 0 : 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: effectiveCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 20,
                            color: isSelected ? const Color(0xFF5856D6) : Colors.white,
                          ),
                          if (!effectiveCollapsed) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF5856D6) : Colors.white,
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
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            child: effectiveCollapsed
                ? IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.white70),
                    tooltip: 'Sign Out',
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                  )
                : Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'DS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5856D6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dr. Sharma', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
                            Text('Chair 01 • Active', style: TextStyle(fontSize: 11, color: Color(0xFFD1FAE5), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                        tooltip: 'Sign Out',
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final autoCollapse = screenWidth < 1024;
    final effectiveCollapsed = _isCollapsed || autoCollapse;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: _buildDoctorSidebar(false, inDrawer: true),
              ),
            )
          : null,
      body: Row(
        children: [
          // Doctor Dedicated Sidebar (Desktop / Tablet)
          if (!isMobile)
            _buildDoctorSidebar(effectiveCollapsed, inDrawer: false),

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
                        icon: Icon(isMobile ? Icons.menu : (effectiveCollapsed ? Icons.menu : Icons.menu_open), size: 20),
                        tooltip: isMobile ? 'Open Menu' : (effectiveCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar'),
                        onPressed: () {
                          if (isMobile) {
                            _scaffoldKey.currentState?.openDrawer();
                          } else {
                            setState(() => _isCollapsed = !_isCollapsed);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _navItems[_selectedIndex]['title'] as String,
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
