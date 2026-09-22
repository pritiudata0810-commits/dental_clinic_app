import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import 'visit_summary_screen.dart';

class PrescriptionScreen extends StatefulWidget {
  final String patientName;
  final String reason;
  final String examination;
  final String diagnosis;
  final String treatment;
  final String procedureCode;

  const PrescriptionScreen({
    super.key,
    this.patientName = 'Aarav Mehta',
    this.reason = 'Regular Check-up & Scaling',
    this.examination = 'Mild supragingival calculus.',
    this.diagnosis = 'Mild chronic gingivitis.',
    this.treatment = 'Full mouth ultrasonic scaling completed.',
    this.procedureCode = 'D1110 - Prophylaxis Adult',
  });

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final List<Map<String, TextEditingController>> _medicines = [];

  @override
  void initState() {
    super.initState();
    _addMedicine(
      name: 'Chlorhexidine 0.2% Mouthwash',
      dosage: '10 ml',
      frequency: 'Twice daily (BD)',
      duration: '7 Days',
      instructions: 'Rinse for 60 seconds after meals. Do not swallow.',
    );
    _addMedicine(
      name: 'Amoxicillin 500mg',
      dosage: '500 mg',
      frequency: 'Thrice daily (TDS)',
      duration: '5 Days',
      instructions: 'Take with food. Complete the full course.',
    );
  }

  void _addMedicine({
    String name = '',
    String dosage = '',
    String frequency = '',
    String duration = '',
    String instructions = '',
  }) {
    setState(() {
      _medicines.add({
        'medicine': TextEditingController(text: name),
        'dosage': TextEditingController(text: dosage),
        'frequency': TextEditingController(text: frequency),
        'duration': TextEditingController(text: duration),
        'instructions': TextEditingController(text: instructions),
      });
    });
  }

  void _removeMedicine(int index) {
    if (_medicines.length <= 1) return;
    final item = _medicines[index];
    for (final c in item.values) {
      c.dispose();
    }
    setState(() {
      _medicines.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final item in _medicines) {
      for (final c in item.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation: Step 3 of 4 (Prescription Rx)'),
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
            // Patient Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication_outlined, color: AppColors.primaryDark, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Prescribing for: ${widget.patientName} • Diagnosis: ${widget.diagnosis}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prescribed Medications (Rx)', style: AppTextStyles.h4),
                OutlinedButton.icon(
                  onPressed: () => _addMedicine(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Drug'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dynamic Medicine Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medicines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _medicines[index];
                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Medication #${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const Spacer(),
                          if (_medicines.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                              tooltip: 'Remove Drug',
                              onPressed: () => _removeMedicine(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: item['medicine'],
                        decoration: const InputDecoration(
                          labelText: 'Medicine / Generic Drug Name *',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item['dosage'],
                              decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: item['frequency'],
                              decoration: const InputDecoration(labelText: 'Frequency (e.g. 1-0-1)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: item['duration'],
                              decoration: const InputDecoration(labelText: 'Duration (e.g. 5 Days)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: item['instructions'],
                        decoration: const InputDecoration(
                          labelText: 'Special Patient Instructions',
                          prefixIcon: Icon(Icons.info_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: AppButton(
                text: 'Continue to Summary & Billing (Step 4) →',
                icon: Icons.receipt_long_outlined,
                onPressed: () {
                  final medicineList = _medicines.map((m) {
                    return {
                      'name': m['medicine']!.text.trim(),
                      'dosage': m['dosage']!.text.trim(),
                      'frequency': m['frequency']!.text.trim(),
                      'duration': m['duration']!.text.trim(),
                      'instructions': m['instructions']!.text.trim(),
                    };
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VisitSummaryScreen(
                        patientName: widget.patientName,
                        reason: widget.reason,
                        examination: widget.examination,
                        diagnosis: widget.diagnosis,
                        treatment: widget.treatment,
                        procedureCode: widget.procedureCode,
                        medicines: medicineList,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}