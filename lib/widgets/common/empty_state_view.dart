import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_button.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double padding;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.padding = 40,
  });

  factory EmptyStateView.noAppointments({VoidCallback? onSchedule}) {
    return EmptyStateView(
      icon: Icons.calendar_today_outlined,
      title: 'No appointments scheduled for today',
      description: 'The schedule is open. You can book a new appointment or review upcoming days.',
      actionLabel: onSchedule != null ? 'Schedule Appointment' : null,
      onAction: onSchedule,
    );
  }

  factory EmptyStateView.noWaitingPatients({VoidCallback? onCheckIn}) {
    return EmptyStateView(
      icon: Icons.airline_seat_recline_normal_outlined,
      title: 'Waiting room is currently empty',
      description: 'Patients will appear here once they arrive and are checked in at reception.',
      actionLabel: onCheckIn != null ? 'View Appointments' : null,
      onAction: onCheckIn,
    );
  }

  factory EmptyStateView.noPatients({VoidCallback? onAddPatient}) {
    return EmptyStateView(
      icon: Icons.person_search_outlined,
      title: 'No patients found',
      description: 'Try adjusting your search criteria or register a new patient in the system.',
      actionLabel: onAddPatient != null ? 'Register New Patient' : null,
      onAction: onAddPatient,
    );
  }

  factory EmptyStateView.noNotifications() {
    return const EmptyStateView(
      icon: Icons.notifications_none_outlined,
      title: "You're all caught up!",
      description: 'No unread notifications or immediate operational alerts right now.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              AppButton(
                text: actionLabel!,
                onPressed: onAction,
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
