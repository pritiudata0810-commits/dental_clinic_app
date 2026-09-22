import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../state/clinic_scope.dart';
import '../../models/appointment.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String? preSelectedPatient;

  const BookAppointmentScreen({super.key, this.preSelectedPatient});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  late String _selectedPatient;
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '10:30 AM';
  final _reasonController = TextEditingController(text: 'Routine Dental Consultation');
  final _notesController = TextEditingController();

  final List<String> _patients = [
    'Aarav Mehta',
    'Ananya Patil',
    'Rohan Deshmukh',
    'Sneha Kulkarni',
    'Vedant Joshi',
    'Kavita Iyer',
  ];

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
  void initState() {
    super.initState();
    _selectedPatient = widget.preSelectedPatient ?? _patients.first;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _bookAppointment() {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reason for visit')),
      );
      return;
    }

    final newApt = Appointment(
      id: 'APT-${DateTime.now().millisecondsSinceEpoch % 100000}',
      patientId: 'PT-01',
      patientName: _selectedPatient,
      patientPhone: '+91 98765 43210',
      doctorId: 'DOC-01',
      doctorName: 'Dr. Sharma',
      dateTime: _selectedDate,
      timeString: _selectedTime,
      appointmentType: _reasonController.text.trim(),
      status: AppointmentStatus.confirmed,
      tokenNumber: 'TK-19',
      notes: _notesController.text.trim(),
    );

    context.clinic.addAppointment(newApt);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Appointment booked for $_selectedPatient at $_selectedTime')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                    value: _selectedPatient,
                    decoration: const InputDecoration(
                      labelText: 'Select Patient *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: _patients.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedPatient = v);
                    },
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
    );
  }
}