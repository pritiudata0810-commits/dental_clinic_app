import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/appointment.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/stat_summary_card.dart';
import '../../widgets/common/toast_notification.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';
import '../../widgets/patients/add_patient_dialog.dart';

class ReceptionistDashboardScreen extends StatelessWidget {
  const ReceptionistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final todayApts = clinic.todayAppointments;
    final waitingCount = clinic.waitingRoomCount;
    final availableDocs = clinic.availableDoctorsCount;
    final consultingDocs = clinic.consultingDoctorsCount;
    final completedCount = todayApts.where((a) => a.status == AppointmentStatus.completed).length;
    final upcomingCount = todayApts.where((a) => a.status == AppointmentStatus.scheduled || a.status == AppointmentStatus.confirmed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Good Morning Banner with Quick Actions
          _buildWelcomeHeader(context),
          const SizedBox(height: 20),

          // 4 Compact Summary KPI Cards (Section 9)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final crossAxisCount = isNarrow ? 2 : 4;
              final width = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: width,
                    child: StatSummaryCard(
                      label: "Today's Appointments",
                      mainValue: '${todayApts.length}',
                      subtext: '$completedCount completed • $upcomingCount upcoming',
                      icon: Icons.calendar_today_rounded,
                      iconBgColor: AppColors.primaryLight,
                      iconColor: AppColors.primary,
                      onTap: () => clinic.setNavIndex(3),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatSummaryCard(
                      label: 'Waiting Room',
                      mainValue: waitingCount.toString().padLeft(2, '0'),
                      subtext: '$waitingCount patient${waitingCount == 1 ? '' : 's'} waiting right now',
                      icon: Icons.airline_seat_recline_normal_rounded,
                      iconBgColor: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFB45309),
                      onTap: () => clinic.setNavIndex(1),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatSummaryCard(
                      label: 'Doctors Available',
                      mainValue: clinic.doctors.length.toString().padLeft(2, '0'),
                      subtext: '$availableDocs ready • $consultingDocs currently consulting',
                      icon: Icons.medical_services_outlined,
                      iconBgColor: const Color(0xFFEDE9FE),
                      iconColor: const Color(0xFF7C3AED),
                      onTap: () => clinic.setNavIndex(4),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatSummaryCard(
                      label: "Today's Billing",
                      mainValue: currency.format(clinic.todayBillingTotal),
                      subtext: '${currency.format(clinic.todayCollectedTotal)} collected',
                      icon: Icons.payments_outlined,
                      iconBgColor: const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF047857),
                      onTap: () => clinic.setNavIndex(5),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Main Split Area: Left = Waiting Room + Today's Schedule, Right = Available Doctors + Quick Actions
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1080;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left 65%
                    Expanded(
                      flex: 65,
                      child: Column(
                        children: [
                          _buildWaitingRoomPreview(context),
                          const SizedBox(height: 20),
                          _buildTodayScheduleCard(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right 35%
                    Expanded(
                      flex: 35,
                      child: Column(
                        children: [
                          _buildDoctorStatusCard(context),
                          const SizedBox(height: 20),
                          _buildQuickActionsCard(context),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildWaitingRoomPreview(context),
                    const SizedBox(height: 20),
                    _buildTodayScheduleCard(context),
                    const SizedBox(height: 20),
                    _buildDoctorStatusCard(context),
                    const SizedBox(height: 20),
                    _buildQuickActionsCard(context),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_sunny_outlined, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good Morning, Sunita 👋',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    'SmileCare Clinic is operating normally. 4 patients expected in next 2 hours.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              AppButton.outline(
                text: 'Waiting Queue',
                icon: Icons.airline_seat_recline_normal,
                onPressed: () => context.clinic.setNavIndex(1),
              ),
              const SizedBox(width: 10),
              AppButton(
                text: '+ Book Appointment',
                icon: Icons.calendar_today,
                onPressed: () => AddAppointmentDialog.show(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingRoomPreview(BuildContext context) {
    final clinic = context.clinic;
    final waitingApts = clinic.waitingRoomPatients;

    return AppCard(
      title: 'Current Waiting Room',
      subtitle: '${waitingApts.length} active in reception pipeline',
      trailing: TextButton.icon(
        onPressed: () => clinic.setNavIndex(1),
        icon: const Icon(Icons.arrow_forward, size: 14),
        label: const Text('Full Waiting Room', style: TextStyle(fontSize: 12)),
      ),
      child: waitingApts.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Waiting room is currently empty. All arrived patients are attended.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: waitingApts.take(3).length,
              separatorBuilder: (c, i) => const Divider(height: 16, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final apt = waitingApts[index];
                return Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          apt.tokenNumber,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(apt.patientName, style: AppTextStyles.h4),
                              const SizedBox(width: 8),
                              StatusBadge.fromAppointmentStatus(apt.status),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${apt.appointmentType} • ${apt.doctorName} (${apt.roomNumber ?? 'Operatory'})',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (apt.status == AppointmentStatus.arrived)
                      AppButton.outline(
                        text: 'Check In',
                        height: 34,
                        onPressed: () {
                          clinic.updateAppointmentStatus(apt.id, AppointmentStatus.checkedIn);
                          AppFeedback.showSuccess(context, '${apt.patientName} checked in');
                        },
                      )
                    else if (apt.status == AppointmentStatus.checkedIn || apt.status == AppointmentStatus.waiting)
                      AppButton(
                        text: 'Call In',
                        height: 34,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          clinic.updateAppointmentStatus(apt.id, AppointmentStatus.inProgress);
                          AppFeedback.showSuccess(context, '${apt.patientName} moved to ${apt.doctorName}');
                        },
                      )
                    else
                      Text('In Treatment', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTodayScheduleCard(BuildContext context) {
    final clinic = context.clinic;
    final apts = clinic.todayAppointments;

    return AppCard(
      title: "Today's Schedule & Appointments",
      subtitle: '${apts.length} appointments scheduled today',
      trailing: TextButton.icon(
        onPressed: () => clinic.setNavIndex(3),
        icon: const Icon(Icons.calendar_month, size: 14),
        label: const Text('View All Schedule', style: TextStyle(fontSize: 12)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: apts.take(4).length,
        separatorBuilder: (c, i) => const Divider(height: 18, color: AppColors.borderLight),
        itemBuilder: (context, index) {
          final apt = apts[index];
          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6)),
                          child: Text(apt.timeString, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(apt.patientName, style: AppTextStyles.h4, overflow: TextOverflow.ellipsis)),
                        StatusBadge.fromAppointmentStatus(apt.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${apt.appointmentType} with ${apt.doctorName}', style: AppTextStyles.bodySmall),
                  ],
                );
              }

              return Row(
                children: [
                  // Time Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      apt.timeString,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(apt.patientName, style: AppTextStyles.h4, overflow: TextOverflow.ellipsis),
                        Text(
                          '${apt.appointmentType} with ${apt.doctorName}',
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  StatusBadge.fromAppointmentStatus(apt.status),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDoctorStatusCard(BuildContext context) {
    final clinic = context.clinic;
    final docs = clinic.doctors;

    return AppCard(
      title: 'Doctor Operatories',
      subtitle: 'Real-time room & chair status',
      trailing: TextButton(
        onPressed: () => clinic.setNavIndex(4),
        child: const Text('View Rosters', style: TextStyle(fontSize: 12)),
      ),
      child: Column(
        children: docs.map((doc) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    doc.avatarInitials,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.name, style: AppTextStyles.h4.copyWith(fontSize: 14)),
                      Text('${doc.roomNumber} • ${doc.specialization.split('&').first.trim()}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                StatusBadge.fromDoctorStatus(doc.status),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final clinic = context.clinic;

    return AppCard(
      title: 'Quick Operations',
      subtitle: 'Frequent receptionist tasks',
      child: Column(
        children: [
          _buildActionRow(
            icon: Icons.person_add_alt,
            title: 'Add New Patient',
            desc: 'Register patient file & contact',
            onTap: () => AddPatientDialog.show(context),
          ),
          const Divider(height: 14, color: AppColors.borderLight),
          _buildActionRow(
            icon: Icons.calendar_month,
            title: 'Schedule Appointment',
            desc: 'Book patient in calendar',
            onTap: () => AddAppointmentDialog.show(context),
          ),
          const Divider(height: 14, color: AppColors.borderLight),
          _buildActionRow(
            icon: Icons.receipt_long,
            title: 'Generate / Check Bill',
            desc: 'View invoices and collect payment',
            onTap: () => clinic.setNavIndex(5),
          ),
          const Divider(height: 14, color: AppColors.borderLight),
          _buildActionRow(
            icon: Icons.chat,
            title: 'Send Bulk Reminder',
            desc: 'Broadcast appointment reminders',
            onTap: () => clinic.setNavIndex(6),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(desc, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
