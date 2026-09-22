import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/appointment.dart';
import '../../state/clinic_scope.dart';
import '../common/app_button.dart';
import '../common/toast_notification.dart';

enum SlotStatus { available, booked, unavailable }

class AddAppointmentDialog extends StatefulWidget {
  final String? initialPatientId;
  final String? initialDoctorId;

  const AddAppointmentDialog({super.key, this.initialPatientId, this.initialDoctorId});

  static void show(BuildContext context, {String? initialPatientId, String? initialDoctorId}) {
    showDialog(
      context: context,
      builder: (ctx) => AddAppointmentDialog(
        initialPatientId: initialPatientId,
        initialDoctorId: initialDoctorId,
      ),
    );
  }

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;
  String? _selectedDoctorId;
  DateTime _selectedDate = DateTime.now();
  String _selectedSlotTime = '10:30 AM';
  String _appointmentType = 'Consultation';
  int _durationMinutes = 30;
  final _notesController = TextEditingController();

  final List<String> _appointmentTypes = const [
    'Consultation',
    'Routine Checkup',
    'Teeth Cleaning & Polishing',
    'Dental Filling (Composite)',
    'Root Canal Treatment',
    'Tooth Extraction',
    'Crown & Bridge Fitting',
    'Orthodontic Adjustment',
    'Pediatric Dental Exam',
  ];

  // Clinic Standard Slots: Morning & Afternoon
  final List<String> _standardSlots = const [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clinic = context.clinic;
    if (_selectedPatientId == null && clinic.patients.isNotEmpty) {
      _selectedPatientId = widget.initialPatientId ?? clinic.patients.first.id;
    }
    if (_selectedDoctorId == null && clinic.doctors.isNotEmpty) {
      _selectedDoctorId = widget.initialDoctorId ?? clinic.doctors.first.id;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  SlotStatus _getSlotStatus(String slotTime) {
    final clinic = context.clinic;
    // Check if lunch break or past closing
    if (slotTime == '12:30 PM') {
      return SlotStatus.unavailable; // Clinic sterilization / lunch break
    }

    // Check if any existing appointment on that date for this doctor matches slot
    final dateApts = clinic.getAppointmentsForDate(_selectedDate);
    final isBooked = dateApts.any((a) {
      if (_selectedDoctorId != null && a.doctorId != _selectedDoctorId) {
        return false;
      }
      return a.timeString.trim().toLowerCase() == slotTime.trim().toLowerCase() &&
          a.status != AppointmentStatus.cancelled;
    });

    return isBooked ? SlotStatus.booked : SlotStatus.available;
  }

  void _saveAppointment() {
    if (_formKey.currentState?.validate() ?? false) {
      final clinic = context.clinic;
      final patient = clinic.patients.firstWhere((p) => p.id == _selectedPatientId);
      final doctor = clinic.doctors.firstWhere((d) => d.id == _selectedDoctorId);

      // Parse selected slot time e.g. "10:30 AM"
      int hour = 10;
      int minute = 30;
      try {
        final parsed = DateFormat('hh:mm a').parse(_selectedSlotTime);
        hour = parsed.hour;
        minute = parsed.minute;
      } catch (_) {}

      final dt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );

      final token = 'TK-${clinic.appointments.length + 10}';
      final newId = 'APT-${DateTime.now().millisecondsSinceEpoch % 10000}';

      final newApt = Appointment(
        id: newId,
        patientId: patient.id,
        patientName: patient.name,
        patientPhone: patient.phone,
        doctorId: doctor.id,
        doctorName: doctor.name,
        dateTime: dt,
        timeString: _selectedSlotTime,
        appointmentType: _appointmentType,
        durationMinutes: _durationMinutes,
        status: AppointmentStatus.scheduled,
        tokenNumber: token,
        roomNumber: doctor.roomNumber,
        notes: _notesController.text.trim(),
      );

      clinic.addAppointment(newApt);
      Navigator.of(context).pop();
      AppFeedback.showSuccess(
        context,
        'Appointment booked! ${patient.name} with ${doctor.name} on ${DateFormat('dd MMM').format(dt)} at $_selectedSlotTime',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final patients = clinic.patients;
    final doctors = clinic.doctors;

    final formattedDateText = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final isTomorrow = DateUtils.isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Book Dental Appointment', style: AppTextStyles.h3),
                          Text('Select Date -> Slot -> Doctor -> Patient -> Confirm', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 12),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // STEP 1: SELECT DATE & DOCTOR
                        const Text('1. Select Date & Attending Doctor', style: AppTextStyles.label),
                        const SizedBox(height: 8),

                        // Date Selector Row with quick pills
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                    color: AppColors.surface,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_outlined, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(formattedDateText, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                      ),
                                      const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                            const SizedBox(width: 6),
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
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Doctor Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedDoctorId,
                          decoration: const InputDecoration(
                            labelText: 'Attending Doctor & Operatory *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: doctors.map((d) {
                            return DropdownMenuItem(
                              value: d.id,
                              child: Text('${d.name} (${d.roomNumber}) • ${d.specialization.split('&').first.trim()}'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedDoctorId = v),
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: AppColors.borderLight),
                        const SizedBox(height: 10),

                        // STEP 2: AVAILABLE TIME SLOTS GRID
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('2. View & Select Time Slot', style: AppTextStyles.label),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLegendDot(const Color(0xFF16A34A), 'Available'),
                                const SizedBox(width: 10),
                                _buildLegendDot(const Color(0xFF94A3B8), 'Booked'),
                                const SizedBox(width: 10),
                                _buildLegendDot(const Color(0xFFEF4444), 'Unavailable'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Slots Grid
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _standardSlots.map((slot) {
                            final status = _getSlotStatus(slot);
                            final isSelected = _selectedSlotTime == slot;

                            Color bgColor;
                            Color textColor;
                            BorderSide border;

                            if (isSelected) {
                              bgColor = AppColors.primary;
                              textColor = Colors.white;
                              border = const BorderSide(color: AppColors.primaryDark, width: 1.5);
                            } else {
                              switch (status) {
                                case SlotStatus.available:
                                  bgColor = const Color(0xFFF0FDF4);
                                  textColor = const Color(0xFF15803D);
                                  border = const BorderSide(color: Color(0xFFBBF7D0));
                                  break;
                                case SlotStatus.booked:
                                  bgColor = const Color(0xFFF1F5F9);
                                  textColor = const Color(0xFF94A3B8);
                                  border = const BorderSide(color: Color(0xFFE2E8F0));
                                  break;
                                case SlotStatus.unavailable:
                                  bgColor = const Color(0xFFFEF2F2);
                                  textColor = const Color(0xFFF87171);
                                  border = const BorderSide(color: Color(0xFFFECACA));
                                  break;
                              }
                            }

                            return InkWell(
                              onTap: status == SlotStatus.available
                                  ? () => setState(() => _selectedSlotTime = slot)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.fromBorderSide(border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(Icons.check, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      slot,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: textColor,
                                        decoration: status == SlotStatus.booked ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: AppColors.borderLight),
                        const SizedBox(height: 10),

                        // STEP 3: SELECT PATIENT & VISIT DETAILS
                        const Text('3. Patient & Visit Reason', style: AppTextStyles.label),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          value: _selectedPatientId,
                          decoration: const InputDecoration(
                            labelText: 'Select Patient *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: patients.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} (${p.id}) • ${p.phone}'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedPatientId = v),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _appointmentType,
                                decoration: const InputDecoration(
                                  labelText: 'Visit Reason / Treatment',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: _appointmentTypes.map((t) {
                                  return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: (v) => setState(() => _appointmentType = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<int>(
                                value: _durationMinutes,
                                decoration: const InputDecoration(
                                  labelText: 'Duration',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 15, child: Text('15 mins', style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 30, child: Text('30 mins', style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 45, child: Text('45 mins', style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 60, child: Text('60 mins', style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (v) => setState(() => _durationMinutes = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Clinical Notes / Symptoms (Optional)',
                            hintText: 'e.g., Molar pain, routine checkup, or post-op evaluation',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // STEP 4: LIVE CONFIRMATION SUMMARY BANNER
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.primaryDark, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Slot Summary: $_selectedSlotTime on ${DateFormat('dd MMM').format(_selectedDate)} (${_durationMinutes}m) • $_appointmentType',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 10),

                // Dialog Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.ghost(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'Confirm & Book Slot',
                      icon: Icons.check_circle_outline,
                      onPressed: _saveAppointment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
