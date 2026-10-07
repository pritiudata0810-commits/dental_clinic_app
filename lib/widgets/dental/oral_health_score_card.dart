import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/patient.dart';
import '../../state/clinic_scope.dart';
import '../../services/oral_health_score_service.dart';
import '../common/app_card.dart';

class OralHealthScoreCard extends StatelessWidget {
  final Patient patient;

  const OralHealthScoreCard({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final patientAppts = clinic.appointments.where((a) => a.patientId == patient.id).toList();
    final patientTeeth = clinic.getToothRecordsForPatient(patient.id);

    final result = OralHealthScoreService.calculate(
      patient: patient,
      appointments: patientAppts,
      toothRecords: patientTeeth,
    );

    final observationsBox = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Clinical Observations',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...result.clinicalObservations.map((obs) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Expanded(
                      child: Text(obs, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );

    final recommendationsBox = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 6),
              const Text(
                'Recommended Next Steps',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...result.recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(rec, style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.3)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Disclaimer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: result.categoryBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.health_and_safety_outlined,
                          color: result.categoryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Patient Oral-Health Score',
                                  style: AppTextStyles.h4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: result.categoryBgColor,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: result.categoryColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  result.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: result.categoryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text(
                                'Informational clinical summary',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Calculated deterministically using 6 clinical factors: preventive care, follow-up adherence, treatment completion, visit adherence, active caries burden, and recall recency. Informational summary only, not a standalone medical diagnosis.',
                                child: Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Big Score Circular Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: result.categoryBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: result.categoryColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.totalScore}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: result.categoryColor,
                      ),
                    ),
                    const Text(
                      ' / 100',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            result.summary,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 6 Weighted Factors Breakdown
          const Text(
            'Scoring Breakdown (6 Clinical Factors)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: result.factors.map((factor) {
                  return SizedBox(
                    width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    child: _buildFactorRow(factor),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Clinical Observations & Recommendations (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: observationsBox),
                    const SizedBox(width: 14),
                    Expanded(child: recommendationsBox),
                  ],
                );
              } else {
                return Column(
                  children: [
                    observationsBox,
                    const SizedBox(height: 14),
                    recommendationsBox,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow(OralHealthFactor factor) {
    final barColor = factor.ratio >= 0.8
        ? const Color(0xFF16A34A)
        : factor.ratio >= 0.5
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                factor.title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${factor.score} / ${factor.maxScore} pts',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: factor.ratio,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          factor.observation,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
