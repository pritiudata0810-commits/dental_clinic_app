import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/patient.dart';
import '../../state/clinic_scope.dart';
import '../common/app_button.dart';
import '../common/toast_notification.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AddPatientDialog(),
    );
  }

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+91 ');
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDob;
  int? _calculatedAge;

  String _gender = 'Male';
  String _bloodGroup = 'O+';
  String? _assignedDoctorId;
  String? _assignedDoctorName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assignedDoctorId == null && context.clinic.doctors.isNotEmpty) {
      _assignedDoctorId = context.clinic.doctors.first.id;
      _assignedDoctorName = context.clinic.doctors.first.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      final age = now.year -
          picked.year -
          ((now.month < picked.month || (now.month == picked.month && now.day < picked.day)) ? 1 : 0);
      setState(() {
        _selectedDob = picked;
        _calculatedAge = age;
        _dobController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _savePatient() async {
    if (_formKey.currentState?.validate() ?? false) {
      final clinic = context.clinic;
      final newId = 'P-${1000 + clinic.patients.length + 1}';

      final allergiesList = _allergiesController.text.trim().isNotEmpty
          ? _allergiesController.text.split(',').map((e) => e.trim()).toList()
          : <String>[];

      final newPatient = Patient(
        id: newId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : '${_nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@gmail.com',
        dateOfBirth: _dobController.text.trim(),
        gender: _gender,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : 'Bengaluru, India',
        emergencyContact: '',
        assignedDoctorId: _assignedDoctorId ?? 'DOC-01',
        assignedDoctorName: _assignedDoctorName ?? 'Dr. Rahul Sharma',
        lastVisit: 'New Registration',
        totalVisits: 0,
        balanceDue: 0.0,
        bloodGroup: _bloodGroup,
        allergies: allergiesList,
        notes: _notesController.text.trim(),
        registrationDate: DateTime.now(),
        age: _calculatedAge != null ? '$_calculatedAge' : '',
      );

      final success = await clinic.addPatient(newPatient);
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        AppFeedback.showSuccess(context, 'Patient ${newPatient.name} ($newId) registered successfully!');
      } else {
        AppFeedback.showError(context, 'Failed to register patient in database. Please check your connection and try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctors = context.clinic.doctors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(28),
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
                      child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Register New Patient', style: AppTextStyles.h3),
                          Text(
                            'Enter patient profile details for clinic registration & digital file',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 16),

                // Form Content with clean two-column grid
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Personal Information
                        Text('1. PERSONAL INFORMATION', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name *',
                                  hintText: 'e.g. Ramesh Chandra',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Please enter patient name';
                                  if (v.trim().length < 2) return 'Name must be at least 2 characters';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile Number *',
                                  hintText: '+91 98765 00000',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Please enter mobile number';
                                  final digits = v.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length < 10) return 'Enter valid 10-digit phone number';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Gender'),
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (v) => setState(() => _gender = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _dobController,
                                readOnly: true,
                                onTap: _selectDateOfBirth,
                                decoration: InputDecoration(
                                  labelText: _calculatedAge != null
                                      ? 'Date of Birth (${_calculatedAge}y) *'
                                      : 'Date of Birth *',
                                  hintText: 'Tap to select date',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                                    onPressed: _selectDateOfBirth,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Select date of birth';
                                  if (_selectedDob != null && _selectedDob!.isAfter(DateTime.now())) {
                                    return 'DOB cannot be future date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _bloodGroup,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Blood Group'),
                                items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                                    .toList(),
                                onChanged: (v) => setState(() => _bloodGroup = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address (Optional)',
                            hintText: 'patient@email.com',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Residential Address',
                            hintText: 'House/Flat, Street, Area, City',
                          ),
                        ),

                        const SizedBox(height: 20),
                        // Section: Medical & Assignment
                        Text('2. CLINIC ASSIGNMENT & MEDICAL NOTES', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _assignedDoctorId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Primary Assigned Doctor'),
                          items: doctors.map((doc) {
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                '${doc.name} (${doc.specialization.split('&').first.trim()})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            final doc = doctors.firstWhere((d) => d.id == v);
                            setState(() {
                              _assignedDoctorId = v;
                              _assignedDoctorName = doc.name;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _allergiesController,
                          decoration: const InputDecoration(
                            labelText: 'Known Allergies (Comma separated)',
                            hintText: 'e.g. Penicillin, Latex, NSAIDs',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Reception Notes / Initial Complaint',
                            hintText: 'e.g. Complains of mild sensitivity in lower jaw',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 16),

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
                      text: 'Register Patient',
                      icon: Icons.check,
                      onPressed: _savePatient,
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
}
