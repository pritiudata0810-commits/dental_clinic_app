import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/tooth_record.dart';

class InteractiveToothChart extends StatelessWidget {
  final Map<int, ToothRecord> latestTeethMap;
  final int? selectedToothNumber;
  final ValueChanged<int?> onToothSelected;

  const InteractiveToothChart({
    super.key,
    required this.latestTeethMap,
    required this.selectedToothNumber,
    required this.onToothSelected,
  });

  // FDI adult permanent quadrant layouts:
  // Upper Maxilla: Q1 (18 to 11) | Q2 (21 to 28)
  static const List<int> _quadrant1 = [18, 17, 16, 15, 14, 13, 12, 11];
  static const List<int> _quadrant2 = [21, 22, 23, 24, 25, 26, 27, 28];
  // Lower Mandible: Q4 (48 to 41) | Q3 (31 to 38)
  static const List<int> _quadrant4 = [48, 47, 46, 45, 44, 43, 42, 41];
  static const List<int> _quadrant3 = [31, 32, 33, 34, 35, 36, 37, 38];

  @override
  Widget build(BuildContext context) {
    // Compute dentition summary
    int healthyCount = 0;
    int treatedCount = 0;
    int attentionCount = 0;

    for (int t = 11; t <= 48; t++) {
      if (!ToothRecord.isValidFdi(t)) continue;
      final rec = latestTeethMap[t];
      final status = rec?.status ?? ToothStatus.healthy;
      if (status == ToothStatus.healthy) {
        healthyCount++;
      } else if (status == ToothStatus.caries ||
          status == ToothStatus.fracture ||
          status == ToothStatus.underTreatment ||
          status == ToothStatus.requiresFollowUp) {
        attentionCount++;
      } else {
        treatedCount++;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with dentition summary
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grid_view_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Adult Permanent Dentition Chart (FDI System)',
                        style: AppTextStyles.h4),
                    Text(
                      '32 Teeth Monitored • Tap any tooth to view clinical timeline or record treatment',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Summary badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _summaryChip('$healthyCount Healthy', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
                  _summaryChip('$treatedCount Restored/RCT', const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
                  if (attentionCount > 0)
                    _summaryChip('$attentionCount Attention Needed', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Dental Arch Layout (Maxillary on top, Mandibular below)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 780),
              child: Column(
                children: [
                  // Maxillary Arch Label
                  _buildArchHeader('MAXILLARY ARCH (UPPER JAW)', Icons.arrow_upward),
                  const SizedBox(height: 8),

                  // Maxillary Teeth (Q1 & Q2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Quadrant 1 (Upper Right)
                      _buildQuadrantBlock('Q1 • Upper Right', _quadrant1, isRightSide: true),
                      // Midline Divider
                      Container(
                        width: 2,
                        height: 90,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: AppColors.primaryDark.withOpacity(0.3),
                      ),
                      // Quadrant 2 (Upper Left)
                      _buildQuadrantBlock('Q2 • Upper Left', _quadrant2, isRightSide: false),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Arch Midline Horizontal Separator
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 200, height: 1, color: AppColors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OCCLUSAL PLANE / CLINICAL MIDLINE',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted.withOpacity(0.8),
                            ),
                          ),
                        ),
                        Container(width: 200, height: 1, color: AppColors.border),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Mandibular Teeth (Q4 & Q3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Quadrant 4 (Lower Right)
                      _buildQuadrantBlock('Q4 • Lower Right', _quadrant4, isRightSide: true),
                      // Midline Divider
                      Container(
                        width: 2,
                        height: 90,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: AppColors.primaryDark.withOpacity(0.3),
                      ),
                      // Quadrant 3 (Lower Left)
                      _buildQuadrantBlock('Q3 • Lower Left', _quadrant3, isRightSide: false),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // Mandibular Arch Label
                  _buildArchHeader('MANDIBULAR ARCH (LOWER JAW)', Icons.arrow_downward),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Clinical Status Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Legend:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              _legendItem(ToothStatus.healthy),
              _legendItem(ToothStatus.caries),
              _legendItem(ToothStatus.filling),
              _legendItem(ToothStatus.crown),
              _legendItem(ToothStatus.rootCanal),
              _legendItem(ToothStatus.implant),
              _legendItem(ToothStatus.extraction),
              _legendItem(ToothStatus.underTreatment),
              _legendItem(ToothStatus.requiresFollowUp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrantBlock(String quadTitle, List<int> teeth, {required bool isRightSide}) {
    return Column(
      crossAxisAlignment: isRightSide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            quadTitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: teeth.map((toothNum) => _buildToothButton(toothNum)).toList(),
        ),
      ],
    );
  }

  Widget _buildToothButton(int toothNum) {
    final record = latestTeethMap[toothNum];
    final status = record?.status ?? ToothStatus.healthy;
    final isSelected = selectedToothNumber == toothNum;

    // Helper tooth anatomy representation
    final pos = toothNum % 10;
    final isMolar = pos >= 6;
    final isPremolar = pos == 4 || pos == 5;
    final isCanine = pos == 3;

    final shapeIcon = isMolar
        ? Icons.rectangle_rounded
        : isPremolar
            ? Icons.square_rounded
            : isCanine
                ? Icons.change_history_rounded
                : Icons.crop_portrait_rounded;

    final tooltipMessage = record != null
        ? '${record.toothName}\nStatus: ${status.label}\nProcedure: ${record.procedure.isNotEmpty ? record.procedure : "None recorded"}\nFinding: ${record.clinicalFinding}'
        : 'Tooth #$toothNum (${status.label})\nHealthy dentition - No pathological findings';

    return Tooltip(
      message: tooltipMessage,
      child: InkWell(
        onTap: () {
          if (isSelected) {
            onToothSelected(null); // Deselect to show all
          } else {
            onToothSelected(toothNum);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 66,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : status.backgroundColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryDark
                  : status == ToothStatus.healthy
                      ? AppColors.border
                      : status.color,
              width: isSelected ? 2.5 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // FDI Tooth Number
              Text(
                '$toothNum',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),

              // Tooth icon representation
              Icon(
                shapeIcon,
                size: 16,
                color: status.color,
              ),

              // Status indicator dot or badge
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _legendItem(ToothStatus status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          status.label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
