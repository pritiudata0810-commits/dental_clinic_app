import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import 'treatment_screen.dart';

class VisitNotesScreen extends StatefulWidget {
  final String patientName;
  final String appointmentReason;

  const VisitNotesScreen({
    super.key,
    this.patientName = 'Aarav Mehta',
    this.appointmentReason = 'Regular Check-up & Scaling',
  });

  @override
  State<VisitNotesScreen> createState() => _VisitNotesScreenState();
}

class _VisitNotesScreenState extends State<VisitNotesScreen> {
  late TextEditingController _reasonController;
  final _examinationController = TextEditingController(
    text: 'Mild supragingival calculus in lower anterior lingual surfaces. Gingival margins slightly erythematous. No mobility detected.',
  );
  final _diagnosisController = TextEditingController(
    text: 'Generalized mild chronic marginal gingivitis.',
  );
  final _notesController = TextEditingController(
    text: 'Patient advised warm saline rinses and improved interdental brushing technique.',
  );

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.appointmentReason);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _examinationController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation: Step 1 of 4 (Visit Notes)'),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Patient: ${widget.patientName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Spacer(),
                  const Text('Consultation in Progress', style: TextStyle(fontSize: 11, color: AppColors.primaryDark)),
                ],
              ),
            ),

            const SizedBox(height: 18),

            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Examination & Diagnosis', style: AppTextStyles.h4),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Visit *',
                      prefixIcon: Icon(Icons.help_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _examinationController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Examination & Intraoral Findings *',
                      prefixIcon: Icon(Icons.search),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _diagnosisController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Diagnosis *',
                      prefixIcon: Icon(Icons.healing_outlined),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Additional Clinical Notes & Observations',
                      prefixIcon: Icon(Icons.note_alt_outlined),
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
                text: 'Continue to Treatment (Step 2) →',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TreatmentScreen(
                        patientName: widget.patientName,
                        reason: _reasonController.text.trim(),
                        examination: _examinationController.text.trim(),
                        diagnosis: _diagnosisController.text.trim(),
                        notes: _notesController.text.trim(),
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