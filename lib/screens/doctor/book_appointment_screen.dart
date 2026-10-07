import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../state/clinic_scope.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String? preSelectedPatient;

  const BookAppointmentScreen({super.key, this.preSelectedPatient});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  String? _selectedDoctorId;
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '10:30 AM';
  final _reasonController = TextEditingController(text: 'Routine Dental Consultation');
  final _notesController = TextEditingController();

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clinic = context.clinic;
    if (_selectedPatientId == null && clinic.patients.isNotEmpty) {
      if (widget.preSelectedPatient != null) {
        final match = clinic.patients.cast<dynamic>().firstWhere(
              (p) => p.name.toLowerCase() == widget.preSelectedPatient!.toLowerCase(),
              orElse: () => clinic.patients.first,
            );
        _selectedPatientId = match.id;
      } else {
        _selectedPatientId = clinic.patients.first.id;
      }
    }
    if (_selectedDoctorId == null && clinic.doctors.isNotEmpty) {
      _selectedDoctorId = clinic.doctors.first.id;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bookAppointment() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final clinic = context.clinic;
    if (_selectedPatientId == null || !clinic.patients.any((p) => p.id == _selectedPatientId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid patient')),
      );
      return;
    }

    final patient = clinic.patients.firstWhere((p) => p.id == _selectedPatientId);
    final doctor = clinic.doctors.firstWhere(
      (d) => d.id == _selectedDoctorId,
      orElse: () => clinic.doctors.isNotEmpty
          ? clinic.doctors.first
          : const Doctor(
              id: 'DOC-01',
              name: 'Dr. Sharma',
              specialization: 'General Dentist',
              qualification: 'BDS',
              status: DoctorStatus.available,
              nextAvailableTime: 'Now',
              roomNumber: 'OPD 1',
              phone: '',
              avatarInitials: 'DS',
            ),
    );

    int hour = 10;
    int minute = 30;
    try {
      final parsed = TimeOfDay(
        hour: int.parse(_selectedTime.split(':')[0]) + (_selectedTime.contains('PM') && !_selectedTime.startsWith('12') ? 12 : 0),
        minute: int.parse(_selectedTime.split(':')[1].split(' ')[0]),
      );
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

    final newApt = Appointment(
      id: 'APT-${DateTime.now().millisecondsSinceEpoch % 100000}',
      patientId: patient.id,
      patientName: patient.name,
      patientPhone: patient.phone,
      doctorId: doctor.id,
      doctorName: doctor.name,
      dateTime: dt,
      timeString: _selectedTime,
      appointmentType: _reasonController.text.trim(),
      status: AppointmentStatus.confirmed,
      tokenNumber: 'TK-${clinic.appointments.length + 12}',
      roomNumber: doctor.roomNumber,
      notes: _notesController.text.trim(),
    );

    final success = await context.clinic.addAppointment(newApt);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment booked for ${patient.name} at $_selectedTime')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to book: Doctor already has an active appointment at this time or database error occurred.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final patients = clinic.patients;
    final doctors = clinic.doctors;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Clinical Appointment'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appointment Details', style: AppTextStyles.h4),
                    const SizedBox(height: 16),

                    // Patient Selector
                    DropdownButtonFormField<String>(
                      value: _selectedPatientId,
                      decoration: const InputDecoration(
                        labelText: 'Select Patient *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select a patient' : null,
                      items: patients.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.phone})'))).toList(),
                      onChanged: (v) => setState(() => _selectedPatientId = v),
                    ),

                    const SizedBox(height: 14),

                    // Doctor Selector
                    DropdownButtonFormField<String>(
                      value: _selectedDoctorId,
                      decoration: const InputDecoration(
                        labelText: 'Select Doctor *',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select a doctor' : null,
                      items: doctors.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.name} (${d.specialization.split('&').first.trim()})'))).toList(),
                      onChanged: (v) => setState(() => _selectedDoctorId = v),
                    ),

                    const SizedBox(height: 16),

                  // Date Picker Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => setState(() => _selectedDate = DateTime.now()),
                        child: const Text('Today'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Time Slots
                  const Text('Select Time Slot', style: AppTextStyles.label),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeSlots.map((slot) {
                      final isSelected = _selectedTime == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: isSelected,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedTime = slot);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Reason
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Visit / Procedure *',
                      prefixIcon: Icon(Icons.healing_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter reason for visit / procedure';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Notes (Optional)',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: AppButton(
                text: 'Confirm & Schedule Appointment',
                icon: Icons.check,
                onPressed: _bookAppointment,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}