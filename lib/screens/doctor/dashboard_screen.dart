import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';
import '../../models/appointment.dart';
import '../../state/clinic_scope.dart';
import '../receptionist/reports_screen.dart';
import 'add_patient_screen.dart';
import 'appointment_details_screen.dart';
import 'appointments_screen.dart';
import 'patients_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read live clinic state from tree
    final clinic = context.clinic;
    final todayAppointments = clinic.todayAppointments;
    final totalPatients = clinic.patients.length;
    final waitingCount = clinic.waitingRoomCount;
    final queuePatients = clinic.waitingRoomPatients;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── DOCTOR HERO BANNER ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Good morning 👋',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Text(
                              'Operatory 01 • Chair Active',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dr. Sharma',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sharma Dental Clinic • Senior Orthodontist',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'DS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── 3 SUMMARY STAT CARDS ──────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 680;
                final cardWidth = isNarrow
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 20) / 3;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _statCard(
                        icon: Icons.calendar_today_outlined,
                        number: '${todayAppointments.length}',
                        label: "Today's Appointments",
                        iconColor: AppColors.primary,
                        backgroundColor: AppColors.primaryLight,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _statCard(
                        icon: Icons.people_alt_outlined,
                        number: '$totalPatients',
                        label: 'Registered Patients',
                        iconColor: const Color(0xFF16A34A),
                        backgroundColor: const Color(0xFFDCFCE7),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _statCard(
                        icon: Icons.access_time_rounded,
                        number: '$waitingCount',
                        label: 'Waiting in Queue',
                        iconColor: const Color(0xFFD97706),
                        backgroundColor: const Color(0xFFFEF3C7),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ─── CLINIC QUEUE & TOKEN MONITOR ──────────────────────────
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Live Clinic Queue & Token Monitor',
                          style: AppTextStyles.h4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Text(
                              'Moving Normally',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Token Highlight Boxes
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 500;
                      final boxWidth = isCompact
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          // Current Token
                          Container(
                            width: boxWidth,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CURRENT TOKEN IN CHAIR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '18',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Rohan Deshmukh • Root Canal Consult',
                                  style: TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),

                          // Next Token
                          Container(
                            width: boxWidth,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NEXT TOKEN IN WAITING ROOM',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '19',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ananya Patil • Checked In',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Queue Metrics Strip
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      final metricWidth = isNarrow
                          ? (constraints.maxWidth - 8) / 2
                          : (constraints.maxWidth - 16) / 3;

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: metricWidth,
                            child: _queueMetricCard(
                              icon: Icons.timer_outlined,
                              iconColor: AppColors.primary,
                              iconBg: AppColors.primaryLight,
                              label: 'Avg. Wait Time',
                              value: '14',
                              unit: 'minutes',
                            ),
                          ),
                          SizedBox(
                            width: metricWidth,
                            child: _queueMetricCard(
                              icon: Icons.airline_seat_recline_normal_outlined,
                              iconColor: const Color(0xFFD97706),
                              iconBg: const Color(0xFFFEF3C7),
                              label: 'Waiting in Room',
                              value: '${queuePatients.length}',
                              unit: 'patients',
                            ),
                          ),
                          SizedBox(
                            width: metricWidth,
                            child: _queueMetricCard(
                              icon: Icons.medical_services_outlined,
                              iconColor: const Color(0xFF16A34A),
                              iconBg: const Color(0xFFDCFCE7),
                              label: 'In Consultation',
                              value: '1',
                              unit: 'active chair',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── QUICK ACTIONS (ALL REAL WORKFLOWS) ─────────────────────
            const Text(
              'Quick Workstation Actions',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 680;
                final actionWidth = isNarrow
                    ? (constraints.maxWidth - 10) / 2
                    : (constraints.maxWidth - 30) / 4;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: actionWidth,
                      child: _quickAction(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'Add Patient',
                        color: AppColors.primaryLight,
                        iconColor: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddPatientScreen()),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: actionWidth,
                      child: _quickAction(
                        icon: Icons.calendar_month_outlined,
                        title: 'Book Appointment',
                        color: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        onTap: () => AddAppointmentDialog.show(context),
                      ),
                    ),
                    SizedBox(
                      width: actionWidth,
                      child: _quickAction(
                        icon: Icons.people_outline_rounded,
                        title: 'View Patients',
                        color: const Color(0xFFEDE9FE),
                        iconColor: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PatientsScreen()),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: actionWidth,
                      child: _quickAction(
                        icon: Icons.bar_chart_rounded,
                        title: 'Reports & Analytics',
                        color: const Color(0xFFFFEDD5),
                        iconColor: const Color(0xFFEA580C),
                        onTap: () {
                          // Real functional reports screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('Clinical Reports & Analytics'),
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.textPrimary,
                                  elevation: 0,
                                ),
                                body: const ReportsScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ─── TODAY'S APPOINTMENTS SCHEDULE ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Today's Clinical Schedule",
                    style: AppTextStyles.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
                    );
                  },
                  child: const Text('View All Schedule →'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (todayAppointments.isNotEmpty) ...[
              ...todayAppointments.take(5).map((apt) {
                final initials = apt.patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _appointmentCard(
                    time: apt.timeString,
                    name: apt.patientName,
                    reason: apt.appointmentType,
                    initials: initials.isNotEmpty ? initials : 'PT',
                    status: apt.status.label,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppointmentDetailsScreen(
                            patientName: apt.patientName,
                            initials: initials.isNotEmpty ? initials : 'PT',
                            time: apt.timeString,
                            reason: apt.appointmentType,
                            status: apt.status.label,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ] else ...[
              _appointmentCard(
                time: '09:30 AM',
                name: 'Aarav Mehta',
                reason: 'Regular Check-up & Scaling',
                initials: 'AM',
                status: 'Confirmed',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentDetailsScreen(
                        patientName: 'Aarav Mehta',
                        initials: 'AM',
                        time: '09:30 AM',
                        reason: 'Regular Check-up & Scaling',
                        status: 'Confirmed',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _appointmentCard(
                time: '10:30 AM',
                name: 'Ananya Patil',
                reason: 'Dental Cleaning & Polishing',
                initials: 'AP',
                status: 'Checked In',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentDetailsScreen(
                        patientName: 'Ananya Patil',
                        initials: 'AP',
                        time: '10:30 AM',
                        reason: 'Dental Cleaning & Polishing',
                        status: 'Checked In',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _appointmentCard(
                time: '11:30 AM',
                name: 'Rohan Deshmukh',
                reason: 'Tooth Pain & RCT Consultation',
                initials: 'RD',
                status: 'In Chair',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentDetailsScreen(
                        patientName: 'Rohan Deshmukh',
                        initials: 'RD',
                        time: '11:30 AM',
                        reason: 'Tooth Pain & RCT Consultation',
                        status: 'In Chair',
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 20),

            // ─── REMINDER BANNER ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinical Follow-Up Reminder',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '3 patients have post-treatment checkups due this week. Review notes before consultation.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
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

  static Widget _statCard({
    required IconData icon,
    required String number,
    required String label,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  static Widget _queueMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _appointmentCard({
    required String time,
    required String name,
    required String reason,
    required String initials,
    required String status,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 13,
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
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status == 'In Chair'
                        ? const Color(0xFFEDE9FE)
                        : (status == 'Checked In' ? const Color(0xFFFEF3C7) : AppColors.primaryLight),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: status == 'In Chair'
                          ? const Color(0xFF6D28D9)
                          : (status == 'Checked In' ? const Color(0xFFB45309) : AppColors.primaryDark),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  static Widget _quickAction({
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}