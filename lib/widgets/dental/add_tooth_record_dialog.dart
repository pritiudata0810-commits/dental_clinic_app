import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/tooth_record.dart';
import '../../models/patient.dart';
import '../../state/clinic_scope.dart';
import '../common/app_button.dart';

class AddToothRecordDialog extends StatefulWidget {
  final Patient patient;
  final int? initialToothNumber;

  const AddToothRecordDialog({
    super.key,
    required this.patient,
    this.initialToothNumber,
  });

  static Future<ToothRecord?> show(
    BuildContext context, {
    required Patient patient,
    int? initialToothNumber,
  }) {
    return showDialog<ToothRecord>(
      context: context,
      builder: (ctx) => AddToothRecordDialog(
        patient: patient,
        initialToothNumber: initialToothNumber,
      ),
    );
  }

  @override
  State<AddToothRecordDialog> createState() => _AddToothRecordDialogState();
}

class _AddToothRecordDialogState extends State<AddToothRecordDialog> {
  final _formKey = GlobalKey<FormState>();

  late int _selectedToothNumber;
  ToothStatus _status = ToothStatus.caries;
  ToothTreatmentCompletionStatus _completionStatus = ToothTreatmentCompletionStatus.completed;

  final _procedureController = TextEditingController();
  final _findingController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedDentistName = 'Dr. Rahul Sharma';
  String? _selectedDentistId = 'DOC-01';

  DateTime _treatmentDate = DateTime.now();
  DateTime? _followUpDate;

  // FDI adult permanent teeth list
  static const List<int> _allFdiTeeth = [
    // Q1
    18, 17, 16, 15, 14, 13, 12, 11,
    // Q2
    21, 22, 23, 24, 25, 26, 27, 28,
    // Q3
    31, 32, 33, 34, 35, 36, 37, 38,
    // Q4
    41, 42, 43, 44, 45, 46, 47, 48,
  ];

  @override
  void initState() {
    super.initState();
    _selectedToothNumber = widget.initialToothNumber != null &&
            ToothRecord.isValidFdi(widget.initialToothNumber!)
        ? widget.initialToothNumber!
        : 11;
  }

  @override
  void dispose() {
    _procedureController.dispose();
    _findingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyProcedurePreset(String preset, ToothStatus status) {
    setState(() {
      _procedureController.text = preset;
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final doctors = clinic.doctors;

    final dummyRecord = ToothRecord(
      id: '',
      patientId: widget.patient.id,
      toothNumber: _selectedToothNumber,
      status: _status,
      treatmentDate: _treatmentDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history_edu_outlined,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Add Tooth Clinical Record',
                                style: AppTextStyles.h3),
                            Text(
                              'Patient: ${widget.patient.name} (${widget.patient.id})',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Form Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FDI Tooth Selector
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                initialValue: _selectedToothNumber,
                                decoration: const InputDecoration(
                                  labelText: 'FDI Tooth Number *',
                                  prefixIcon: Icon(Icons.tag),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                                items: _allFdiTeeth.map((tooth) {
                                  final temp = ToothRecord(
                                    id: '',
                                    patientId: '',
                                    toothNumber: tooth,
                                    status: ToothStatus.healthy,
                                    treatmentDate: DateTime.now(),
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  return DropdownMenuItem<int>(
                                    value: tooth,
                                    child: Text(
                                      '#$tooth - ${temp.toothName}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedToothNumber = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Quadrant & Name',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      dummyRecord.toothName,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Clinical Status Picker
                        const Text('Clinical Status *',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ToothStatus.values.map((status) {
                            final isSel = _status == status;
                            return ChoiceChip(
                              label: Text(status.label),
                              selected: isSel,
                              selectedColor: status.backgroundColor,
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSel ? status.color : AppColors.border,
                                  width: isSel ? 1.5 : 1,
                                ),
                              ),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? status.color : AppColors.textPrimary,
                              ),
                              onSelected: (_) => setState(() => _status = status),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Quick Presets
                        const Text('Quick Procedure Templates:',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _presetChip('Composite Filling', ToothStatus.filling,
                                  'Class I Light-cured composite resin restoration'),
                              const SizedBox(width: 6),
                              _presetChip('Root Canal (RCT)', ToothStatus.rootCanal,
                                  'Biomechanical preparation & single sitting obturation'),
                              const SizedBox(width: 6),
                              _presetChip('Zirconia Crown', ToothStatus.crown,
                                  'Crown preparation and digital scanning for zirconia crown'),
                              const SizedBox(width: 6),
                              _presetChip('Dental Implant', ToothStatus.implant,
                                  'Fixture placement with healing abutment'),
                              const SizedBox(width: 6),
                              _presetChip('Caries Detected', ToothStatus.caries,
                                  'Occlusal cavitation requiring excavation and restoration'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Procedure Name
                        TextFormField(
                          controller: _procedureController,
                          decoration: const InputDecoration(
                            labelText: 'Procedure / Treatment *',
                            hintText: 'e.g. Class II Composite Filling / RCT Phase 1',
                            prefixIcon: Icon(Icons.medical_services_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Please enter procedure' : null,
                        ),

                        const SizedBox(height: 14),

                        // Clinical Finding / Diagnosis
                        TextFormField(
                          controller: _findingController,
                          decoration: const InputDecoration(
                            labelText: 'Clinical Finding / Diagnosis',
                            hintText: 'e.g. Deep occlusal fissure decay with sensitivity',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Operative Clinical Notes
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Clinical Notes & Observation',
                            hintText: 'e.g. Under local anesthesia (Lignox 2%), rubber dam isolation...',
                            prefixIcon: Icon(Icons.notes_outlined),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Attending Dentist & Treatment Stage
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedDentistName,
                                decoration: const InputDecoration(
                                  labelText: 'Dentist / Clinician',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                items: doctors.map((doc) {
                                  return DropdownMenuItem<String>(
                                    value: doc.name,
                                    child: Text(doc.name, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedDentistName = val;
                                      final matched =
                                          doctors.firstWhere((d) => d.name == val, orElse: () => doctors.first);
                                      _selectedDentistId = matched.id;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<ToothTreatmentCompletionStatus>(
                                initialValue: _completionStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status of Treatment',
                                  prefixIcon: Icon(Icons.task_alt),
                                  border: OutlineInputBorder(),
                                ),
                                items: ToothTreatmentCompletionStatus.values.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _completionStatus = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Dates: Treatment Date & Follow-up Date
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _treatmentDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _treatmentDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Treatment Date',
                                    prefixIcon: Icon(Icons.calendar_today_outlined),
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(_treatmentDate),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _followUpDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Follow-up Date (Optional)',
                                    prefixIcon: const Icon(Icons.event_repeat),
                                    suffixIcon: _followUpDate != null
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: () => setState(() => _followUpDate = null),
                                          )
                                        : null,
                                    border: const OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _followUpDate != null
                                        ? DateFormat('dd MMM yyyy').format(_followUpDate!)
                                        : 'None scheduled',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _followUpDate != null
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'Save Tooth Record',
                      icon: Icons.check,
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;

                        final newRecord = ToothRecord(
                          id: 'TR-${DateTime.now().millisecondsSinceEpoch}',
                          patientId: widget.patient.id,
                          toothNumber: _selectedToothNumber,
                          status: _status,
                          procedure: _procedureController.text.trim(),
                          clinicalFinding: _findingController.text.trim(),
                          notes: _notesController.text.trim(),
                          dentistId: _selectedDentistId,
                          dentistName: _selectedDentistName,
                          treatmentDate: _treatmentDate,
                          followUpDate: _followUpDate,
                          completionStatus: _completionStatus,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        clinic.addToothRecord(newRecord);
                        Navigator.pop(context, newRecord);
                      },
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

  Widget _presetChip(String label, ToothStatus status, String procedureText) {
    return ActionChip(
      label: Text(label),
      avatar: CircleAvatar(
        radius: 5,
        backgroundColor: status.color,
      ),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.border),
      ),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      onPressed: () => _applyProcedurePreset(procedureText, status),
    );
  }
}
