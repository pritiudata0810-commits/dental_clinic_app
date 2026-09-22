import 'package:flutter/material.dart';
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
  final _emergencyController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _notesController = TextEditingController();

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
    _emergencyController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _savePatient() {
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
        dateOfBirth: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : '15 Jan 1995',
        gender: _gender,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Bengaluru, India',
        emergencyContact: _emergencyController.text.trim().isNotEmpty ? _emergencyController.text.trim() : 'Next of kin',
        assignedDoctorId: _assignedDoctorId ?? 'DOC-01',
        assignedDoctorName: _assignedDoctorName ?? 'Dr. Rahul Sharma',
        lastVisit: 'New Registration',
        totalVisits: 0,
        balanceDue: 0.0,
        bloodGroup: _bloodGroup,
        allergies: allergiesList,
        notes: _notesController.text.trim(),
        registrationDate: DateTime.now(),
      );

      clinic.addPatient(newPatient);
      Navigator.of(context).pop();
      AppFeedback.showSuccess(context, 'Patient ${newPatient.name} ($newId) registered successfully!');
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Register New Patient', style: AppTextStyles.h3),
                        Text(
                          'Enter patient profile details for clinic registration & digital file',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
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
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile Number *',
                                  hintText: '+91 98765 00000',
                                ),
                                validator: (v) => (v == null || v.trim().length < 5) ? 'Enter valid phone' : null,
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
                                decoration: const InputDecoration(
                                  labelText: 'Date of Birth',
                                  hintText: 'e.g. 14 May 1992',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _bloodGroup,
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
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'patient@email.com',
                          ),
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
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _assignedDoctorId,
                                decoration: const InputDecoration(labelText: 'Primary Assigned Doctor'),
                                items: doctors.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text('${doc.name} (${doc.specialization.split('&').first.trim()})'),
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _emergencyController,
                                decoration: const InputDecoration(
                                  labelText: 'Emergency Contact',
                                  hintText: 'Relation & Phone number',
                                ),
                              ),
                            ),
                          ],
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
