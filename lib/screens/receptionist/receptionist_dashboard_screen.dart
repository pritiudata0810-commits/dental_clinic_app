import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/appointment.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/toast_notification.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';

/// Complete Redesign of ReceptionistDashboardScreen
/// Following Reference Image 2:
/// - Purple Theme (#5856D6 + Soft Lavender #F4F5FC)
/// - Top Greeting + 3 Elevated Rounded Stat Cards
/// - Middle 3-column / responsive grid:
///     1. Notifications / Waiting Room Activity
///     2. Active Dental Treatments in Progress
///     3. Month Calendar with horizontal date row + timed appointments
/// - Bottom Row:
///     1. Today's Clinical Activity with percentage progress bars
///     2. Solid Purple Operatory Highlight Card
///     3. Circular Clinical Gauges + Next Consultation action card
class ReceptionistDashboardScreen extends StatefulWidget {
  const ReceptionistDashboardScreen({super.key});

  @override
  State<ReceptionistDashboardScreen> createState() => _ReceptionistDashboardScreenState();
}

class _ReceptionistDashboardScreenState extends State<ReceptionistDashboardScreen> {
  int _selectedDayOffset = 0; // 0 = Today, -1 = Yesterday, 1 = Tomorrow, etc.

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final todayApts = clinic.todayAppointments;
    final waitingApts = clinic.waitingRoomPatients;
    final completedCount = todayApts.where((a) => a.status == AppointmentStatus.completed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // 1. TOP HERO GREETING + 3 TOP ROUNDED STAT CARDS (REFERENCE 2)
          // ==========================================================
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1000;

              final greetingWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Hi, Sunita!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEDFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.health_and_safety_rounded, size: 14, color: Color(0xFF5856D6)),
                            SizedBox(width: 4),
                            Text(
                              'SmileCare',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5856D6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'What are your clinic plans for today?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E2A72),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SmileCare OS manages real-time appointments, patients, and chair operatory flow.',
                    style: AppTextStyles.caption.copyWith(color: const Color(0xFF64748B)),
                  ),
                ],
              );

              final statsWidget = Row(
                children: [
                  Expanded(
                    child: _buildTopFeatureCard(
                      title: "Appointments",
                      value: '${todayApts.length}',
                      subtitle: '$completedCount done',
                      icon: Icons.calendar_today_rounded,
                      color: const Color(0xFF5856D6),
                      bgColor: const Color(0xFFEEEDFC),
                      onTap: () => clinic.setNavIndex(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTopFeatureCard(
                      title: 'Waiting Queue',
                      value: '${waitingApts.length}',
                      subtitle: 'Active now',
                      icon: Icons.airline_seat_recline_normal_rounded,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                      onTap: () => clinic.setNavIndex(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTopFeatureCard(
                      title: 'Billing Total',
                      value: currency.format(clinic.todayBillingTotal),
                      subtitle: 'Today revenue',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF059669),
                      bgColor: const Color(0xFFD1FAE5),
                      onTap: () => clinic.setNavIndex(5),
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 45, child: greetingWidget),
                    const SizedBox(width: 20),
                    Expanded(flex: 55, child: statsWidget),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    greetingWidget,
                    const SizedBox(height: 16),
                    statsWidget,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // ==========================================================
          // 2. MIDDLE 3-COLUMN COMPOSITION (REFERENCE 2)
          // Column 1: Notifications / Live Patient Queue
          // Column 2: Treatments / Assignments in Progress
          // Column 3: Calendar & Timed Clinical Schedule
          // ==========================================================
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1060;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Notifications / Queue (32%)
                    Expanded(flex: 32, child: _buildNotificationsQueueCard(context)),
                    const SizedBox(width: 16),
                    // Center Column: Treatments in Progress (34%)
                    Expanded(flex: 34, child: _buildTreatmentsProgressCard(context)),
                    const SizedBox(width: 16),
                    // Right Column: Calendar Widget & Schedule (34%)
                    Expanded(flex: 34, child: _buildCalendarScheduleWidget(context)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCalendarScheduleWidget(context),
                    const SizedBox(height: 16),
                    _buildNotificationsQueueCard(context),
                    const SizedBox(height: 16),
                    _buildTreatmentsProgressCard(context),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // ==========================================================
          // 3. BOTTOM ROW COMPOSITION (REFERENCE 2)
          // Block 1: Today's Clinical Workload with Progress Bars
          // Block 2: Solid Purple Operatory Highlight Card
          // Block 3: Circular Performance Gauges + Priority Consultation
          // ==========================================================
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1060;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bottom Left: Tasks / Activity with % Progress Bars (40%)
                    Expanded(flex: 40, child: _buildClinicActivityProgressCard(context)),
                    const SizedBox(width: 16),
                    // Bottom Center: Purple Feature Highlight Card (24%)
                    Expanded(flex: 24, child: _buildPurpleOperatoryHighlightCard(context)),
                    const SizedBox(width: 16),
                    // Bottom Right: Circular Gauges & Next Appointment (36%)
                    Expanded(flex: 36, child: _buildGaugesAndNextActionCard(context)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildClinicActivityProgressCard(context),
                    const SizedBox(height: 16),
                    _buildPurpleOperatoryHighlightCard(context),
                    const SizedBox(height: 16),
                    _buildGaugesAndNextActionCard(context),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TOP STATS CARDS (REFERENCE 2 - 3 Rounded Cards)
  // ==========================================================
  Widget _buildTopFeatureCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4E4F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1B4B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E2A72)),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MIDDLE COLUMN 1: NOTIFICATIONS / QUEUE (REFERENCE 2)
  // ==========================================================
  Widget _buildNotificationsQueueCard(BuildContext context) {
    final clinic = context.clinic;
    final waitingApts = clinic.waitingRoomPatients;
    final nextPatient = waitingApts.isNotEmpty ? waitingApts.first : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E4F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
              ),
              InkWell(
                onTap: () => clinic.setNavIndex(1),
                child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5856D6))),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reference 2: Elevated white subcard with shadow
          if (nextPatient != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0FA)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5856D6).withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981), // Live green dot
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next Arrived Patient',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEDFC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          nextPatient.tokenNumber,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5856D6)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextPatient.patientName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${nextPatient.appointmentType} • ${nextPatient.doctorName}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        nextPatient.timeString,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5856D6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          clinic.updateAppointmentStatus(nextPatient.id, AppointmentStatus.inProgress);
                          AppFeedback.showSuccess(context, '${nextPatient.patientName} moved to consultation');
                        },
                        child: const Text('Call In', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Text('No patients currently in waiting room', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ),

          const SizedBox(height: 14),

          // Secondary Notification
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.ring_volume_rounded, size: 18, color: Color(0xFF5856D6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Follow-up Reminders',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
                      ),
                      Text(
                        '${clinic.pendingRemindersCount} pending patient follow-ups',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => clinic.setNavIndex(6),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                  child: const Text('Queue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5856D6))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MIDDLE COLUMN 2: TREATMENTS IN PROGRESS (REFERENCE 2 ASSIGNMENTS)
  // ==========================================================
  Widget _buildTreatmentsProgressCard(BuildContext context) {
    final clinic = context.clinic;
    final inProgressApts = clinic.todayAppointments.where((a) => a.status == AppointmentStatus.inProgress).toList();
    final activeApt = inProgressApts.isNotEmpty ? inProgressApts.first : (clinic.todayAppointments.isNotEmpty ? clinic.todayAppointments.first : null);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E4F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clinical Treatments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
              ),
              InkWell(
                onTap: () => AddAppointmentDialog.show(context),
                child: const Text('+ Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5856D6))),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tags row (Reference 2 style: Motion design / Logo pills)
          Row(
            children: [
              _buildTagPill('Dental Surgery', const Color(0xFF5856D6), const Color(0xFFEEEDFC)),
              const SizedBox(width: 8),
              _buildTagPill('Operatory 01', const Color(0xFF059669), const Color(0xFFD1FAE5)),
            ],
          ),
          const SizedBox(height: 14),

          if (activeApt != null) ...[
            Text(
              '${activeApt.appointmentType} Procedure',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Patient: ${activeApt.patientName} (${activeApt.patientPhone})',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'In Progress',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                  ),
                ),
                const Spacer(),
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF5856D6),
                  child: Text('DS', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Text(
                  activeApt.doctorName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B)),
                ),
              ],
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('All scheduled procedures for this slot are clear', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Add New Treatment Button (Reference 2: + Add new assignment)
          InkWell(
            onTap: () => AddAppointmentDialog.show(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0FA)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF5856D6)),
                  SizedBox(width: 8),
                  Text(
                    'Add new appointment',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5856D6)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(String title, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  // ==========================================================
  // MIDDLE COLUMN 3: CALENDAR & TIMED SCHEDULE (REFERENCE 2)
  // ==========================================================
  Widget _buildCalendarScheduleWidget(BuildContext context) {
    final clinic = context.clinic;
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: _selectedDayOffset));

    final displayApts = _selectedDayOffset == 0
        ? clinic.todayAppointments
        : clinic.appointments.where((a) =>
            a.dateTime.year == targetDate.year &&
            a.dateTime.month == targetDate.month &&
            a.dateTime.day == targetDate.day).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E4F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header (Reference 2: "May 2021" with left/right arrows)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(targetDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _selectedDayOffset--),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _selectedDayOffset++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Date Selector Row (Reference 2: Mon 14, Tue 15, Wed 16, Thr 17, Fr 18 with 18 highlighted)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (i) {
                final offset = i - 2; // -2, -1, 0 (Today), 1, 2, 3, 4
                final d = now.add(Duration(days: offset));
                final isSelected = offset == _selectedDayOffset;
                final isToday = offset == 0;
                final weekdayStr = isToday ? 'TODAY' : DateFormat('EEE').format(d).toUpperCase();
                final dayNumStr = DateFormat('dd').format(d);

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedDayOffset = offset),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF5856D6) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weekdayStr,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white70 : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayNumStr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : const Color(0xFF1E1B4B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFECECF8)),
          const SizedBox(height: 14),

          // Timed Consultations List (Reference 2 format: 04:30-05:00 PM Team meeting)
          if (displayApts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 28, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 6),
                    const Text('No bookings on this day', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => AddAppointmentDialog.show(context),
                      child: const Text('+ Book slot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5856D6))),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayApts.take(3).length,
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final apt = displayApts[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apt.timeString,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5856D6)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: apt.status == AppointmentStatus.completed ? const Color(0xFF10B981) : const Color(0xFF5856D6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${apt.patientName} • ${apt.appointmentType}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
                          ),
                        ),
                        StatusBadge.fromAppointmentStatus(apt.status),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM BLOCK 1: CLINIC WORKLOAD WITH PROGRESS BARS (REFERENCE 2 TODAY TASKS)
  // ==========================================================
  Widget _buildClinicActivityProgressCard(BuildContext context) {
    final clinic = context.clinic;
    final todayApts = clinic.todayAppointments;
    final completedCount = todayApts.where((a) => a.status == AppointmentStatus.completed).length;
    final totalCount = todayApts.isNotEmpty ? todayApts.length : 1;
    final completionPct = (completedCount / totalCount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E4F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today Clinical Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
              ),
              InkWell(
                onTap: () => clinic.setNavIndex(7),
                child: const Text('Reports', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5856D6))),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Progress Row 1: Completed Consultations
          _buildProgressTaskRow(
            title: 'Consultations Completed',
            subtext: '$completedCount of ${todayApts.length} patients seen today',
            percentage: completionPct,
            pctLabel: '${(completionPct * 100).toInt()}%',
            color: const Color(0xFF5856D6),
          ),
          const SizedBox(height: 14),

          // Progress Row 2: Operatory Utilization
          _buildProgressTaskRow(
            title: 'Operatory Chair Utilization',
            subtext: '${clinic.consultingDoctorsCount} active doctor consultations',
            percentage: 0.70,
            pctLabel: '70%',
            color: const Color(0xFF059669),
          ),
          const SizedBox(height: 14),

          // Progress Row 3: Call Reminders Handled
          _buildProgressTaskRow(
            title: 'Call Reminders Handled',
            subtext: '${clinic.pendingRemindersCount} remaining in call queue',
            percentage: 0.50,
            pctLabel: '50%',
            color: const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTaskRow({
    required String title,
    required String subtext,
    required double percentage,
    required String pctLabel,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B))),
            Text(pctLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtext, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: const Color(0xFFEEEDFC),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // BOTTOM BLOCK 2: SOLID PURPLE HIGHLIGHT CARD (REFERENCE 2 GO PREMIUM)
  // ==========================================================
  Widget _buildPurpleOperatoryHighlightCard(BuildContext context) {
    final clinic = context.clinic;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF5856D6), // Solid Reference 2 purple
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5856D6).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Illustration
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Operatory 01 Live',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dr. Sharma is consulting with patients in Chair 01. Operatory 02 is ready for walk-ins.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFD6D5F7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5856D6),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => clinic.setNavIndex(4),
            child: const Text('View Rosters', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM BLOCK 3: CIRCULAR GAUGES & NEXT ACTION (REFERENCE 2)
  // ==========================================================
  Widget _buildGaugesAndNextActionCard(BuildContext context) {
    final clinic = context.clinic;
    final todayApts = clinic.todayAppointments;
    final nextApt = todayApts.where((a) => a.status == AppointmentStatus.scheduled || a.status == AppointmentStatus.confirmed).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E4F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Gauges Row (Reference 2: 90% Marketing, 65% Typography)
          Row(
            children: [
              Expanded(
                child: _buildCircularGauge(
                  label: 'COMPLETION',
                  metricName: 'Attended',
                  percentage: 0.88,
                  pctString: '88%',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCircularGauge(
                  label: 'COLLECTION',
                  metricName: 'Bills Paid',
                  percentage: 0.74,
                  pctString: '74%',
                  color: const Color(0xFF5856D6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFECECF8)),
          const SizedBox(height: 14),

          // Next Consultation Priority Card (Reference 2: "Board meeting" card with Reschedule / Accept invite)
          const Text(
            'Next Priority Consultation',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 4),
          if (nextApt != null) ...[
            Text(
              '${nextApt.timeString} • ${nextApt.patientName} (${nextApt.appointmentType})',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E0F9)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => clinic.setNavIndex(3),
                    child: const Text('Reschedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5856D6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      clinic.updateAppointmentStatus(nextApt.id, AppointmentStatus.arrived);
                      AppFeedback.showSuccess(context, '${nextApt.patientName} marked as Arrived');
                    },
                    child: const Text('Mark Arrived', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('No further upcoming appointments scheduled for today', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularGauge({
    required String label,
    required String metricName,
    required double percentage,
    required String pctString,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 4.5,
                  backgroundColor: const Color(0xFFE5E5F6),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    pctString,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
                ),
                Text(
                  metricName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
