import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/appointment.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/toast_notification.dart';
import '../../widgets/appointments/add_appointment_dialog.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedDoctorFilter;
  String _selectedStatusFilter = 'All';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _stepDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  List<Appointment> _applyFilters(List<Appointment> list) {
    return list.where((apt) {
      if (_selectedDoctorFilter != null && apt.doctorId != _selectedDoctorFilter) {
        return false;
      }
      if (_selectedStatusFilter != 'All') {
        if (apt.status.label.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final dateApts = clinic.getAppointmentsForDate(_selectedDate);
    final filteredApts = _applyFilters(dateApts);

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final isTomorrow = DateUtils.isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Appointment CTA
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appointment Scheduling & Roster', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Organize daily patient consultations, operatory timings, and schedule clinic slots',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: '+ Schedule Appointment',
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
                        const Text('Appointment Scheduling & Roster', style: AppTextStyles.h2),
                        const SizedBox(height: 4),
                        Text(
                          'Organize daily patient consultations, operatory timings, and schedule clinic slots',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    text: '+ Schedule Appointment',
                    icon: Icons.calendar_today,
                    onPressed: () => AddAppointmentDialog.show(context),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Fluid Date Navigation Bar
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    // Date Stepper & Picker Button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          tooltip: 'Previous Day',
                          onPressed: () => _stepDate(-1),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event, size: 16, color: AppColors.primaryDark),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('EEE, dd MMMM yyyy').format(_selectedDate),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primaryDark),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          tooltip: 'Next Day',
                          onPressed: () => _stepDate(1),
                        ),
                      ],
                    ),

                    // Quick Jump Pills
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChoiceChip(
                          label: const Text('Today'),
                          selected: isToday,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                          onSelected: (_) => setState(() => _selectedDate = DateTime.now()),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Tomorrow'),
                          selected: isTomorrow,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isTomorrow ? FontWeight.w700 : FontWeight.w500,
                            color: isTomorrow ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                          onSelected: (_) => setState(() => _selectedDate = DateTime.now().add(const Duration(days: 1))),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${filteredApts.length} Appointments',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Filters Bar: Doctor and Status
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Doctor Filter
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Doctor: ', style: AppTextStyles.label),
                        const SizedBox(width: 8),
                        DropdownButton<String?>(
                          value: _selectedDoctorFilter,
                          underline: const SizedBox(),
                          hint: const Text('All Doctors', style: AppTextStyles.bodySmall),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Doctors', style: AppTextStyles.bodySmall)),
                            ...clinic.doctors.map((d) {
                              return DropdownMenuItem(value: d.id, child: Text(d.name, style: AppTextStyles.bodySmall));
                            }),
                          ],
                          onChanged: (v) => setState(() => _selectedDoctorFilter = v),
                        ),
                      ],
                    ),

                    // Status Filter
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Status: ', style: AppTextStyles.label),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedStatusFilter,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Statuses', style: AppTextStyles.bodySmall)),
                            DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled', style: AppTextStyles.bodySmall)),
                            DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed', style: AppTextStyles.bodySmall)),
                            DropdownMenuItem(value: 'Waiting', child: Text('Waiting', style: AppTextStyles.bodySmall)),
                            DropdownMenuItem(value: 'With Doctor', child: Text('With Doctor', style: AppTextStyles.bodySmall)),
                            DropdownMenuItem(value: 'Completed', child: Text('Completed', style: AppTextStyles.bodySmall)),
                            DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled', style: AppTextStyles.bodySmall)),
                          ],
                          onChanged: (v) => setState(() => _selectedStatusFilter = v ?? 'All'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Appointment List based on selected date
          if (filteredApts.isEmpty)
            AppCard(
              child: EmptyStateView.noAppointments(
                onSchedule: () => AddAppointmentDialog.show(context),
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredApts.length,
                separatorBuilder: (c, i) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final apt = filteredApts[index];
                  return _AppointmentTile(
                    appointment: apt,
                    isToday: isToday,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool isToday;

  const _AppointmentTile({
    required this.appointment,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 950;

          if (isNarrow) {
            // Adaptive Stacked Layout for Tablet / Narrow Screens
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            appointment.timeString,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 4),
                          Text('(${appointment.durationMinutes}m)', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(appointment.tokenNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primaryDark)),
                    ),
                    const Spacer(),
                    StatusBadge.fromAppointmentStatus(appointment.status),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.patientName, style: AppTextStyles.h4),
                          const SizedBox(height: 2),
                          Text('${appointment.appointmentType} • Phone: ${appointment.patientPhone}', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(appointment.doctorName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text(appointment.roomNumber ?? 'Operatory 1', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (isToday && appointment.status == AppointmentStatus.scheduled)
                      AppButton(
                        text: 'Mark Arrived',
                        icon: Icons.how_to_reg_outlined,
                        onPressed: () {
                          clinic.updateAppointmentStatus(appointment.id, AppointmentStatus.arrived);
                          AppFeedback.showSuccess(context, '${appointment.patientName} marked Arrived');
                        },
                      )
                    else if (isToday && appointment.status == AppointmentStatus.arrived)
                      AppButton(
                        text: 'Check In',
                        icon: Icons.login_rounded,
                        onPressed: () {
                          clinic.updateAppointmentStatus(appointment.id, AppointmentStatus.checkedIn);
                          AppFeedback.showSuccess(context, '${appointment.patientName} checked in');
                        },
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                      splashRadius: 18,
                      onSelected: (action) {
                        if (action == 'cancel') {
                          clinic.cancelAppointment(appointment.id);
                          AppFeedback.showInfo(context, 'Appointment cancelled for ${appointment.patientName}');
                        } else if (action == 'reschedule') {
                          AddAppointmentDialog.show(context, initialPatientId: appointment.patientId);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'reschedule', child: Text('Reschedule Slot')),
                        const PopupMenuItem(value: 'cancel', child: Text('Cancel Appointment', style: TextStyle(color: Color(0xFFDC2626)))),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }

          // Desktop Balanced Row
          return Row(
            children: [
              // Time Box
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      appointment.timeString,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${appointment.durationMinutes}m',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Patient Name & Details
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(appointment.patientName, style: AppTextStyles.h4, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(appointment.tokenNumber, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
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
                    Text(appointment.doctorName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    Text(appointment.roomNumber ?? 'Operatory 1', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),

              // Status Badge
              StatusBadge.fromAppointmentStatus(appointment.status),
              const SizedBox(width: 14),

              // Contextual Action Buttons
              if (isToday && appointment.status == AppointmentStatus.scheduled) ...[
                AppButton(
                  text: 'Mark Arrived',
                  onPressed: () {
                    clinic.updateAppointmentStatus(appointment.id, AppointmentStatus.arrived);
                    AppFeedback.showSuccess(context, '${appointment.patientName} marked Arrived');
                  },
                ),
                const SizedBox(width: 8),
              ] else if (isToday && appointment.status == AppointmentStatus.arrived) ...[
                AppButton(
                  text: 'Check In',
                  onPressed: () {
                    clinic.updateAppointmentStatus(appointment.id, AppointmentStatus.checkedIn);
                    AppFeedback.showSuccess(context, '${appointment.patientName} checked in');
                  },
                ),
                const SizedBox(width: 8),
              ],

              // Cancel / Reschedule menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                splashRadius: 18,
                onSelected: (action) {
                  if (action == 'cancel') {
                    clinic.cancelAppointment(appointment.id);
                    AppFeedback.showInfo(context, 'Appointment cancelled for ${appointment.patientName}');
                  } else if (action == 'reschedule') {
                    AddAppointmentDialog.show(context, initialPatientId: appointment.patientId);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'reschedule', child: Text('Reschedule Slot')),
                  const PopupMenuItem(value: 'cancel', child: Text('Cancel Appointment', style: TextStyle(color: Color(0xFFDC2626)))),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
