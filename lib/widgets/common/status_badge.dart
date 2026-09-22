import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/billing.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.fromAppointmentStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return const StatusBadge(
          label: 'Scheduled',
          backgroundColor: AppColors.statusScheduledBg,
          textColor: AppColors.statusScheduledText,
          icon: Icons.calendar_today_outlined,
        );
      case AppointmentStatus.confirmed:
        return const StatusBadge(
          label: 'Confirmed',
          backgroundColor: Color(0xFFE0F2FE),
          textColor: Color(0xFF0369A1),
          icon: Icons.check_circle_outline,
        );
      case AppointmentStatus.arrived:
        return const StatusBadge(
          label: 'Arrived',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFFB45309),
          icon: Icons.place_outlined,
        );
      case AppointmentStatus.checkedIn:
        return const StatusBadge(
          label: 'Checked In',
          backgroundColor: Color(0xFFFEF08A),
          textColor: Color(0xFF854D0E),
          icon: Icons.how_to_reg_outlined,
        );
      case AppointmentStatus.waiting:
        return const StatusBadge(
          label: 'Waiting',
          backgroundColor: AppColors.statusWaitingBg,
          textColor: AppColors.statusWaitingText,
          icon: Icons.hourglass_top_outlined,
        );
      case AppointmentStatus.inProgress:
        return const StatusBadge(
          label: 'With Doctor',
          backgroundColor: AppColors.statusInConsultationBg,
          textColor: AppColors.statusInConsultationText,
          icon: Icons.medical_services_outlined,
        );
      case AppointmentStatus.completed:
        return const StatusBadge(
          label: 'Completed',
          backgroundColor: AppColors.statusCompletedBg,
          textColor: AppColors.statusCompletedText,
          icon: Icons.task_alt_outlined,
        );
      case AppointmentStatus.cancelled:
        return const StatusBadge(
          label: 'Cancelled',
          backgroundColor: AppColors.statusCancelledBg,
          textColor: AppColors.statusCancelledText,
          icon: Icons.cancel_outlined,
        );
      case AppointmentStatus.noShow:
        return const StatusBadge(
          label: 'No Show',
          backgroundColor: AppColors.statusCancelledBg,
          textColor: AppColors.statusCancelledText,
          icon: Icons.person_off_outlined,
        );
    }
  }

  factory StatusBadge.fromDoctorStatus(DoctorStatus status) {
    switch (status) {
      case DoctorStatus.available:
        return const StatusBadge(
          label: 'Available',
          backgroundColor: Color(0xFFD1FAE5),
          textColor: Color(0xFF065F46),
          icon: Icons.circle,
        );
      case DoctorStatus.inConsultation:
        return const StatusBadge(
          label: 'In Consultation',
          backgroundColor: Color(0xFFEDE9FE),
          textColor: Color(0xFF5B21B6),
          icon: Icons.circle,
        );
      case DoctorStatus.busy:
        return const StatusBadge(
          label: 'Busy',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFF92400E),
          icon: Icons.circle,
        );
      case DoctorStatus.onBreak:
        return const StatusBadge(
          label: 'On Break',
          backgroundColor: Color(0xFFF1F5F9),
          textColor: Color(0xFF475569),
          icon: Icons.circle,
        );
      case DoctorStatus.unavailable:
        return const StatusBadge(
          label: 'Unavailable',
          backgroundColor: Color(0xFFFFE4E6),
          textColor: Color(0xFF9F1239),
          icon: Icons.circle,
        );
    }
  }

  factory StatusBadge.fromPaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const StatusBadge(
          label: 'Paid',
          backgroundColor: Color(0xFFD1FAE5),
          textColor: Color(0xFF047857),
          icon: Icons.check_circle_outlined,
        );
      case PaymentStatus.pending:
        return const StatusBadge(
          label: 'Pending',
          backgroundColor: Color(0xFFFFE4E6),
          textColor: Color(0xFFBE123C),
          icon: Icons.pending_outlined,
        );
      case PaymentStatus.partial:
        return const StatusBadge(
          label: 'Partial',
          backgroundColor: Color(0xFFFFEDD5),
          textColor: Color(0xFFC2410C),
          icon: Icons.pie_chart_outline,
        );
      case PaymentStatus.refunded:
        return const StatusBadge(
          label: 'Refunded',
          backgroundColor: Color(0xFFF1F5F9),
          textColor: Color(0xFF475569),
          icon: Icons.replay_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: icon == Icons.circle ? 8 : 13,
              color: textColor,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
