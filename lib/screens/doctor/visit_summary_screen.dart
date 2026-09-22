import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../services/consultation_service.dart';

class VisitSummaryScreen extends StatelessWidget {
  final String patientName;
  final String reason;
  final String examination;
  final String diagnosis;
  final String treatment;
  final String procedureCode;
  final List<Map<String, String>> medicines;

  const VisitSummaryScreen({
    super.key,
    this.patientName = 'Aarav Mehta',
    this.reason = 'Regular Check-up & Scaling',
    this.examination = 'Mild supragingival calculus in lower anterior lingual surfaces.',
    this.diagnosis = 'Generalized mild chronic marginal gingivitis.',
    this.treatment = 'Full mouth ultrasonic scaling completed. Polishing with fine abrasive paste.',
    this.procedureCode = 'D1110 - Prophylaxis Adult',
    this.medicines = const [
      {
        'name': 'Chlorhexidine 0.2% Mouthwash',
        'dosage': '10 ml',
        'frequency': 'Twice daily (BD)',
        'duration': '7 Days',
        'instructions': 'Rinse for 60 seconds after meals.',
      },
      {
        'name': 'Amoxicillin 500mg',
        'dosage': '500 mg',
        'frequency': 'Thrice daily (TDS)',
        'duration': '5 Days',
        'instructions': 'Take with food. Complete the full course.',
      },
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation: Step 4 of 4 (Visit Summary & Billing)'),
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
            // Patient Header Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Text('AM', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patientName, style: AppTextStyles.h3),
                        const SizedBox(height: 2),
                        const Text('Attending: Dr. Sharma • Operatory 01', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Consultation Complete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Examination & Diagnosis Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Findings & Diagnosis', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _rowItem('Reason for Visit', reason),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _rowItem('Intraoral Findings', examination),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _rowItem('Clinical Diagnosis', diagnosis),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Treatment Rendered Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Treatment & Procedures Rendered', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _rowItem('Procedure Code', procedureCode),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _rowItem('Operative Notes', treatment),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Prescriptions Rx Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Prescriptions Issued (Rx)', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  ...medicines.map((m) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medication, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const Spacer(),
                              Text('${m['dosage']} • ${m['frequency']}', style: AppTextStyles.caption),
                            ],
                          ),
                          if ((m['instructions'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Instructions: ${m['instructions']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Billing Overview Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Billing & Fee Overview', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _billingRow('Doctor Consultation Fee', '₹500'),
                  _billingRow('Full Mouth Scaling (D1110)', '₹700'),
                  const Divider(color: AppColors.borderLight, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Total Payable Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text('₹1,200', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: AppButton(
                text: 'Save & Complete Clinical Visit',
                icon: Icons.check_circle_outline,
                onPressed: () {
                  ConsultationService().saveConsultation(
                    patientId: 'P-1001',
                    patientName: patientName,
                    doctorId: 'DOC-01',
                    doctorName: 'Dr. Rahul Sharma',
                    reasonForVisit: reason,
                    examinationFindings: examination,
                    diagnosis: diagnosis,
                    clinicalNotes: treatment,
                    procedureCode: procedureCode,
                    totalFee: 1200.0,
                    medicines: medicines,
                  );

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clinical Visit Saved'),
                      content: const Text(
                        'The patient visit notes, treatment record, and prescription have been successfully saved to the electronic dental health record.',
                      ),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () {
                            Navigator.pop(ctx);
                            // Return back to doctor dashboard / patient profile
                            int count = 0;
                            Navigator.of(context).popUntil((_) => count++ >= 4);
                          },
                          child: const Text('Done', style: TextStyle(color: Colors.white)),
                        ),
                      ],
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

  static Widget _rowItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4)),
      ],
    );
  }

  static Widget _billingRow(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}