import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/appointment.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/toast_notification.dart';

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  String _filter = 'All'; // 'All', 'Waiting', 'With Doctor', 'Checked In'

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final allWaiting = clinic.waitingRoomPatients;

    List<Appointment> filtered = allWaiting;
    if (_filter == 'Waiting') {
      filtered = allWaiting.where((a) => a.status == AppointmentStatus.waiting || a.status == AppointmentStatus.arrived).toList();
    } else if (_filter == 'Checked In') {
      filtered = allWaiting.where((a) => a.status == AppointmentStatus.checkedIn).toList();
    } else if (_filter == 'With Doctor') {
      filtered = allWaiting.where((a) => a.status == AppointmentStatus.inProgress).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Description (Responsive Wrap to avoid right/bottom overflow)
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Waiting Room & Patient Queue', style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text(
                    'Track patient arrival, waiting duration, and chair assignments in real-time',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.statusWaitingBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Text(
                      'Avg Wait: 12 Mins • ${allWaiting.length} Active in Queue',
                      style: AppTextStyles.label.copyWith(color: const Color(0xFFB45309), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Scrollable Workflow Stage Progression Guide (Guarantees zero bottom/right overflow)
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: Row(
                  children: [
                    _buildWorkflowStep('1. Arrived', 'Reception desk greeting', false),
                    _buildWorkflowArrow(),
                    _buildWorkflowStep('2. Checked In', 'File ready & verified', false),
                    _buildWorkflowArrow(),
                    _buildWorkflowStep('3. Waiting', 'Seated in lounge', true),
                    _buildWorkflowArrow(),
                    _buildWorkflowStep('4. With Doctor', 'In operatory chair', false),
                    _buildWorkflowArrow(),
                    _buildWorkflowStep('5. Completed', 'Checkout & invoice', false),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Filter Segmented Controls
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All (${allWaiting.length})', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('Waiting Lounge', 'Waiting'),
                const SizedBox(width: 8),
                _buildFilterChip('Checked In', 'Checked In'),
                const SizedBox(width: 8),
                _buildFilterChip('With Doctor (In Chair)', 'With Doctor'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Patient Waiting List Table / Cards (Responsive layout)
          if (filtered.isEmpty)
            AppCard(
              child: EmptyStateView.noWaitingPatients(
                onCheckIn: () => clinic.setNavIndex(3),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final apt = filtered[index];
                return _WaitingPatientCard(appointment: apt);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowStep(String title, String subtitle, bool isHighlighted) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.label.copyWith(
              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWorkflowArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
    );
  }
}

class _WaitingPatientCard extends StatelessWidget {
  final Appointment appointment;

  const _WaitingPatientCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 950;

        if (isNarrow) {
          // ─── Adaptive Card Layout for Tablet & Narrow Screens ──────
          return AppCard(
            enableHoverEffect: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Token + Patient Name & ID + Status Badge
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          appointment.tokenNumber,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(appointment.patientName, style: AppTextStyles.h4, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(4)),
                                child: Text(appointment.patientId, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${appointment.appointmentType} • ${appointment.patientPhone}', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    StatusBadge.fromAppointmentStatus(appointment.status),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 10),

                // Middle Row: Doctor, Room, Time & Wait Duration
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.medical_services_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('${appointment.doctorName} (${appointment.roomNumber ?? 'Operatory 1'})', style: AppTextStyles.bodySmall),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('Slot: ${appointment.timeString}', style: AppTextStyles.bodySmall),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFB45309)),
                        const SizedBox(width: 6),
                        Text('${appointment.waitMinutes} mins wait', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom Action: Workflow Button
                _buildWorkflowAction(context, clinic),
              ],
            ),
          );
        }

        // ─── Desktop Balanced Row Layout ──────────────────────────────
        return AppCard(
          enableHoverEffect: true,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              // Token Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    appointment.tokenNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Patient Name & ID
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(appointment.patientName, style: AppTextStyles.h4, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(appointment.patientId, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${appointment.appointmentType} • ${appointment.patientPhone}',
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Doctor & Room
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.roomNumber ?? 'Operatory 1',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),

              // Wait Time
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appointment.waitMinutes} mins wait',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                    ),
                    Text('Slot: ${appointment.timeString}', style: AppTextStyles.caption),
                  ],
                ),
              ),

              // Status Badge
              StatusBadge.fromAppointmentStatus(appointment.status),
              const SizedBox(width: 14),

              // Workflow Action
              _buildWorkflowAction(context, clinic),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkflowAction(BuildContext context, clinic) {
    if (appointment.status == AppointmentStatus.arrived) {
      return AppButton(
        text: 'Check In',
        icon: Icons.how_to_reg,
        onPressed: () {
          clinic.updateAppointmentStatus(appointment.id, AppointmentStatus.checkedIn);
          AppFeedback.showSuccess(context, '${appointment.patientName} marked Checked In');
        },
      );
    } else if (appointment.status == AppointmentStatus.checkedIn || appointment.status == AppointmentStatus.waiting) {
      return AppButton(
        text: 'Call to Chair',
        icon: Icons.chair_alt_outlined,
        onPressed: () {
          clinic.updateAppointmentStatus(appointment.id, AppointmentStatus.inProgress);
          AppFeedback.showSuccess(context, '${appointment.patientName} escorted to ${appointment.doctorName}');
        },
      );
    } else if (appointment.status == AppointmentStatus.inProgress) {
      return AppButton.success(
        text: 'Mark Completed',
        icon: Icons.task_alt,
        onPressed: () {
          clinic.updateAppointmentStatus(appointment.id, AppointmentStatus.completed);
          AppFeedback.showSuccess(context, 'Consultation completed for ${appointment.patientName}');
        },
      );
    }
    return const SizedBox.shrink();
  }
}
