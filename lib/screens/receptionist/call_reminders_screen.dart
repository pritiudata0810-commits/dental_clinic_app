import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/call_reminder.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/toast_notification.dart';
import '../../widgets/communication/quick_comm_dialogs.dart';

class CallRemindersScreen extends StatefulWidget {
  const CallRemindersScreen({super.key});

  @override
  State<CallRemindersScreen> createState() => _CallRemindersScreenState();
}

class _CallRemindersScreenState extends State<CallRemindersScreen> {
  String _activeFilter = 'All'; // 'All', 'Pending', 'Confirmed', 'Missed'

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final allReminders = clinic.callReminders;

    final filtered = allReminders.where((r) {
      if (_activeFilter == 'Pending') {
        return r.status == ReminderStatus.pending || r.status == ReminderStatus.retryRequired;
      } else if (_activeFilter == 'Confirmed') {
        return r.status == ReminderStatus.confirmed;
      } else if (_activeFilter == 'Missed') {
        return r.status == ReminderStatus.missed;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Call Reminders Queue', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Dedicated outbound reminder workstation for upcoming patient appointments',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AppButton(
                text: 'Mark All Processed',
                icon: Icons.done_all,
                onPressed: () {
                  AppFeedback.showSuccess(context, 'All reminder calls processed');
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // KPI Summary Cards: 8 pending, 3 confirmed, 2 missed, 3 remaining
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              final width = isNarrow
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _buildKpiCard(
                      '${clinic.pendingRemindersCount} Reminders Pending',
                      'Requires immediate calls',
                      Icons.alarm_on_rounded,
                      const Color(0xFFF59E0B),
                      const Color(0xFFFEF3C7),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildKpiCard(
                      '${clinic.confirmedRemindersCount} Patients Confirmed',
                      'Confirmed for tomorrow',
                      Icons.check_circle_outline,
                      const Color(0xFF10B981),
                      const Color(0xFFD1FAE5),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildKpiCard(
                      '${clinic.missedRemindersCount} Missed Calls',
                      'Retry attempt required',
                      Icons.phone_missed_rounded,
                      const Color(0xFFEF4444),
                      const Color(0xFFFFE4E6),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildKpiCard(
                      '${clinic.remainingRemindersCount} Total Remaining',
                      'Active reminder queue',
                      Icons.pending_actions_rounded,
                      AppColors.primary,
                      AppColors.primaryLight,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Filter Segmented Controls
          Row(
            children: [
              _buildFilterPill('All (${allReminders.length})', 'All'),
              const SizedBox(width: 8),
              _buildFilterPill('Pending (${clinic.pendingRemindersCount})', 'Pending'),
              const SizedBox(width: 8),
              _buildFilterPill('Confirmed (${clinic.confirmedRemindersCount})', 'Confirmed'),
              const SizedBox(width: 8),
              _buildFilterPill('Missed (${clinic.missedRemindersCount})', 'Missed'),
            ],
          ),

          const SizedBox(height: 16),

          // Reminders List (Adaptive Card / Row)
          if (filtered.isEmpty)
            const AppCard(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No call reminders in this category.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reminder = filtered[index];
                return _CallReminderCard(reminder: reminder);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String subtitle, IconData icon, Color color, Color bg) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
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
}

class _CallReminderCard extends StatelessWidget {
  final CallReminder reminder;

  const _CallReminderCard({required this.reminder});

  Color _statusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.confirmed:
        return const Color(0xFF10B981);
      case ReminderStatus.missed:
        return const Color(0xFFEF4444);
      case ReminderStatus.called:
      case ReminderStatus.answered:
        return const Color(0xFF0284C7);
      case ReminderStatus.pending:
      case ReminderStatus.retryRequired:
        return const Color(0xFFF59E0B);
      case ReminderStatus.cancelled:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final statusColor = _statusColor(reminder.status);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        if (isNarrow) {
          // Adaptive Stacked Card for Tablet / Narrow viewports
          return AppCard(
            padding: const EdgeInsets.all(16),
            enableHoverEffect: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(reminder.patientName, style: AppTextStyles.h4),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reminder.status.label,
                        style: AppTextStyles.label.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${reminder.phoneNumber} • ${reminder.appointmentType}', style: AppTextStyles.bodySmall),
                const SizedBox(height: 10),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 8),

                // Details
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${reminder.appointmentDate}, ${reminder.appointmentTime}', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 14),
                    const Icon(Icons.medical_services_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(child: Text(reminder.doctorName, style: AppTextStyles.bodySmall)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Last: ${reminder.lastAttempt}', style: AppTextStyles.caption),
                    const SizedBox(width: 12),
                    Text('Next: ${reminder.nextAttempt}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 14),

                // Full-width Communication Action Buttons [ CALL ] [ SMS ] [ WHATSAPP ]
                Row(
                  children: [
                    Expanded(
                      child: _buildCallButton(context, clinic),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSmsButton(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildWhatsAppButton(context),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusMenu(context, clinic),
                  ],
                ),
              ],
            ),
          );
        }

        // Desktop Row Layout
        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          enableHoverEffect: true,
          child: Row(
            children: [
              // Patient Info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.patientName, style: AppTextStyles.h4),
                    Text(reminder.phoneNumber, style: AppTextStyles.caption),
                  ],
                ),
              ),

              // Appointment Date & Doctor
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reminder.appointmentDate} • ${reminder.appointmentTime}',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text('${reminder.doctorName} (${reminder.appointmentType})', style: AppTextStyles.caption),
                  ],
                ),
              ),

              // Attempt Tracking
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.lastAttempt, style: AppTextStyles.caption),
                    Text(reminder.nextAttempt, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  reminder.status.label,
                  style: AppTextStyles.label.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),

              // Action Buttons: [ CALL ] [ SMS ] [ WHATSAPP ] + Menu
              _buildCallButton(context, clinic),
              const SizedBox(width: 6),
              _buildSmsButton(context),
              const SizedBox(width: 6),
              _buildWhatsAppButton(context),
              const SizedBox(width: 6),
              _buildStatusMenu(context, clinic),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallButton(BuildContext context, clinic) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.callGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 36),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: const Icon(Icons.phone, size: 14),
      label: const Text('CALL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      onPressed: () {
        QuickCommDialogs.showCallDialog(
          context,
          patientId: reminder.patientId,
          patientName: reminder.patientName,
          phoneNumber: reminder.phoneNumber,
        );
        clinic.updateReminderStatus(
          reminder.id,
          ReminderStatus.called,
          lastAttempt: 'Today just now - Call initiated',
        );
      },
    );
  }

  Widget _buildSmsButton(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: const Icon(Icons.sms_outlined, size: 14),
      label: const Text('SMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      onPressed: () => QuickCommDialogs.showSmsDialog(
        context,
        patientId: reminder.patientId,
        patientName: reminder.patientName,
        phoneNumber: reminder.phoneNumber,
      ),
    );
  }

  Widget _buildWhatsAppButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.whatsappGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 36),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: const Icon(Icons.chat_bubble_outline, size: 14),
      label: const Text('WHATSAPP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      onPressed: () => QuickCommDialogs.showWhatsAppDialog(
        context,
        patientId: reminder.patientId,
        patientName: reminder.patientName,
        phoneNumber: reminder.phoneNumber,
      ),
    );
  }

  Widget _buildStatusMenu(BuildContext context, clinic) {
    return PopupMenuButton<ReminderStatus>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
      splashRadius: 18,
      tooltip: 'Change status',
      onSelected: (status) {
        clinic.updateReminderStatus(reminder.id, status);
        AppFeedback.showSuccess(context, 'Reminder marked as ${status.label}');
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: ReminderStatus.confirmed, child: Text('Mark Confirmed')),
        const PopupMenuItem(value: ReminderStatus.missed, child: Text('Mark Missed')),
        const PopupMenuItem(value: ReminderStatus.retryRequired, child: Text('Retry Required')),
        const PopupMenuItem(value: ReminderStatus.cancelled, child: Text('Mark Cancelled')),
      ],
    );
  }
}
