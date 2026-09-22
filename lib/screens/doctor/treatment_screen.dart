import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import 'prescription_screen.dart';

class TreatmentScreen extends StatefulWidget {
  final String patientName;
  final String reason;
  final String examination;
  final String diagnosis;
  final String notes;

  const TreatmentScreen({
    super.key,
    this.patientName = 'Aarav Mehta',
    this.reason = 'Regular Check-up & Scaling',
    this.examination = 'Mild supragingival calculus in lower anterior lingual surfaces.',
    this.diagnosis = 'Generalized mild chronic marginal gingivitis.',
    this.notes = 'Patient advised warm saline rinses.',
  });

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  final _treatmentController = TextEditingController(
    text: 'Full mouth ultrasonic scaling completed. Polishing with fine abrasive paste. Subgingival irrigation with povidone-iodine.',
  );
  final _procedureCodeController = TextEditingController(text: 'D1110 - Prophylaxis Adult');

  @override
  void dispose() {
    _treatmentController.dispose();
    _procedureCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation: Step 2 of 4 (Treatment & Procedures)'),
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
            // Patient & Diagnosis Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined, color: AppColors.primaryDark, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patient: ${widget.patientName}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Diagnosis: ${widget.diagnosis}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Treatment Rendered', style: AppTextStyles.h4),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _procedureCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Dental Procedure / CDT Code *',
                      prefixIcon: Icon(Icons.tag_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _treatmentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Treatment Given / Operative Notes *',
                      prefixIcon: Icon(Icons.edit_note_outlined),
                      alignLabelWithHint: true,
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
                text: 'Continue to Prescriptions (Step 3) →',
                icon: Icons.medication_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrescriptionScreen(
                        patientName: widget.patientName,
                        reason: widget.reason,
                        examination: widget.examination,
                        diagnosis: widget.diagnosis,
                        treatment: _treatmentController.text.trim(),
                        procedureCode: _procedureCodeController.text.trim(),
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
