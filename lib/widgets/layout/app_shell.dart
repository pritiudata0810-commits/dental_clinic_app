import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../state/clinic_scope.dart';
import 'sidebar.dart';
import 'top_bar.dart';
import '../../screens/receptionist/receptionist_dashboard_screen.dart';
import '../../screens/receptionist/waiting_room_screen.dart';
import '../../screens/receptionist/patients_screen.dart';
import '../../screens/receptionist/appointments_screen.dart';
import '../../screens/receptionist/doctor_availability_screen.dart';
import '../../screens/receptionist/billing_screen.dart';
import '../../screens/receptionist/call_reminders_screen.dart';
import '../../screens/receptionist/reports_screen.dart';
import '../../screens/receptionist/settings_screen.dart';
import '../patients/add_patient_dialog.dart';
import '../appointments/add_appointment_dialog.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCollapsed = false;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const ReceptionistDashboardScreen();
      case 1:
        return const WaitingRoomScreen();
      case 2:
        return const PatientsScreen();
      case 3:
        return const AppointmentsScreen();
      case 4:
        return const DoctorAvailabilityScreen();
      case 5:
        return const BillingScreen();
      case 6:
        return const CallRemindersScreen();
      case 7:
        return const ReportsScreen();
      case 8:
        return const SettingsScreen();
      default:
        return const ReceptionistDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
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
                child: AppSidebar(
                  isCollapsed: false,
                  onToggleCollapse: () => _scaffoldKey.currentState?.closeDrawer(),
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar Navigation (Desktop / Tablet)
          if (!isMobile)
            AppSidebar(
              isCollapsed: effectiveCollapsed,
              onToggleCollapse: () => setState(() => _isCollapsed = !_isCollapsed),
            ),

          // Main Screen Area (TopBar + Dynamic Screen View)
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  onToggleSidebar: () {
                    if (isMobile) {
                      _scaffoldKey.currentState?.openDrawer();
                    } else {
                      setState(() => _isCollapsed = !_isCollapsed);
                    }
                  },
                  onOpenAddPatient: () => AddPatientDialog.show(context),
                  onOpenAddAppointment: () => AddAppointmentDialog.show(context),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(clinic.currentNavIndex),
                      child: _buildScreen(clinic.currentNavIndex),
                    ),
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
