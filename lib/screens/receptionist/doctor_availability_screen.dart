import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/doctor.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  DoctorStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final allDoctors = clinic.doctors;

    final availableCount = allDoctors.where((d) => d.status == DoctorStatus.available).length;
    final consultingCount = allDoctors.where((d) => d.status == DoctorStatus.inConsultation || d.status == DoctorStatus.busy).length;
    final awayCount = allDoctors.where((d) => d.status == DoctorStatus.onBreak || d.status == DoctorStatus.unavailable).length;

    final filteredDoctors = _statusFilter == null
        ? allDoctors
        : allDoctors.where((d) => d.status == _statusFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doctor Operatory & Availability', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Live chair occupancy, consulting statuses, and next open slots',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: '+ Book Appointment',
                      icon: Icons.calendar_today,
                      onPressed: () => AddAppointmentDialog.show(context),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Doctor Operatory & Availability', style: AppTextStyles.h2),
                        const SizedBox(height: 4),
                        Text(
                          'Live chair occupancy, consulting statuses, and next open slots',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    text: '+ Book Appointment',
                    icon: Icons.calendar_today,
                    onPressed: () => AddAppointmentDialog.show(context),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Quick Metric Overview Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final crossCount = isNarrow ? 2 : 4;
              final cardWidth = (constraints.maxWidth - (crossCount - 1) * 12) / crossCount;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildMetricPill(
                    width: cardWidth,
                    label: 'Total Doctors',
                    count: '${allDoctors.length}',
                    color: AppColors.primary,
                    icon: Icons.medical_services_outlined,
                  ),
                  _buildMetricPill(
                    width: cardWidth,
                    label: 'Available Now',
                    count: '$availableCount',
                    color: const Color(0xFF16A34A),
                    icon: Icons.check_circle_outline,
                  ),
                  _buildMetricPill(
                    width: cardWidth,
                    label: 'In Consultation',
                    count: '$consultingCount',
                    color: const Color(0xFF0284C7),
                    icon: Icons.person_outline,
                  ),
                  _buildMetricPill(
                    width: cardWidth,
                    label: 'On Break / Away',
                    count: '$awayCount',
                    color: const Color(0xFFD97706),
                    icon: Icons.coffee_outlined,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('All Doctors (${allDoctors.length})'),
                selected: _statusFilter == null,
                selectedColor: AppColors.primaryLight,
                labelStyle: TextStyle(
                  fontWeight: _statusFilter == null ? FontWeight.w700 : FontWeight.w500,
                  color: _statusFilter == null ? AppColors.primaryDark : AppColors.textPrimary,
                ),
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              ChoiceChip(
                label: Text('Available ($availableCount)'),
                selected: _statusFilter == DoctorStatus.available,
                selectedColor: const Color(0xFFDCFCE7),
                labelStyle: TextStyle(
                  fontWeight: _statusFilter == DoctorStatus.available ? FontWeight.w700 : FontWeight.w500,
                  color: _statusFilter == DoctorStatus.available ? const Color(0xFF16A34A) : AppColors.textPrimary,
                ),
                onSelected: (_) => setState(() => _statusFilter = DoctorStatus.available),
              ),
              ChoiceChip(
                label: Text('In Consultation ($consultingCount)'),
                selected: _statusFilter == DoctorStatus.inConsultation,
                selectedColor: AppColors.primaryLight,
                labelStyle: TextStyle(
                  fontWeight: _statusFilter == DoctorStatus.inConsultation ? FontWeight.w700 : FontWeight.w500,
                  color: _statusFilter == DoctorStatus.inConsultation ? AppColors.primaryDark : AppColors.textPrimary,
                ),
                onSelected: (_) => setState(() => _statusFilter = DoctorStatus.inConsultation),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Grid of Doctor Availability Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              int crossAxisCount;
              if (width < 680) {
                crossAxisCount = 1;
              } else if (width < 1100) {
                crossAxisCount = 2;
              } else {
                crossAxisCount = 3;
              }

              final itemWidth = (width - (crossAxisCount - 1) * 20) / crossAxisCount;

              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: filteredDoctors.map((doctor) {
                  return SizedBox(
                    width: itemWidth,
                    child: _DoctorCard(doctor: doctor),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required double width,
    required String label,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: AppTextStyles.h3.copyWith(color: color)),
                Text(label, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      enableHoverEffect: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  doctor.avatarInitials,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              StatusBadge.fromDoctorStatus(doctor.status),
            ],
          ),
          const SizedBox(height: 14),

          // Name & Credentials
          Text(doctor.name, style: AppTextStyles.h4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(doctor.qualification, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            doctor.specialization,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),

          // Operatory Room & Current Chair State
          _buildInfoRow(
            Icons.meeting_room_outlined,
            'Operatory Location',
            doctor.roomNumber,
          ),
          const SizedBox(height: 8),

          _buildInfoRow(
            Icons.person_outline,
            'Current Patient',
            doctor.currentPatientName ?? 'None (Chair Free)',
            highlight: doctor.currentPatientName != null,
          ),
          const SizedBox(height: 8),

          _buildInfoRow(
            Icons.access_time_outlined,
            'Next Available Slot',
            doctor.nextAvailableTime,
            highlight: doctor.status == DoctorStatus.available,
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),

          // Daily Load & Quick Slot Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${doctor.completedTodayCount}/${doctor.todayAppointmentsCount} Completed',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text('Today\'s schedule', style: AppTextStyles.caption),
                  ],
                ),
              ),
              AppButton.outline(
                text: 'Book Slot',
                height: 34,
                icon: Icons.add,
                onPressed: () => AddAppointmentDialog.show(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.primaryDark : AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
