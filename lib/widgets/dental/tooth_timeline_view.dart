import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/tooth_record.dart';
import '../../models/patient.dart';
import '../../state/clinic_scope.dart';
import '../common/app_card.dart';
import '../common/app_button.dart';
import 'add_tooth_record_dialog.dart';

class ToothTimelineView extends StatelessWidget {
  final Patient patient;
  final int? selectedToothNumber;
  final ValueChanged<int?> onClearSelection;

  const ToothTimelineView({
    super.key,
    required this.patient,
    required this.selectedToothNumber,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final allRecords = clinic.getToothRecordsForPatient(patient.id);

    final filteredRecords = selectedToothNumber != null
        ? allRecords.where((r) => r.toothNumber == selectedToothNumber).toList()
        : allRecords;

    final dummySelected = selectedToothNumber != null
        ? ToothRecord(
            id: '',
            patientId: patient.id,
            toothNumber: selectedToothNumber!,
            status: ToothStatus.healthy,
            treatmentDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                    child: const Icon(Icons.timeline_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Digital Tooth Timeline', style: AppTextStyles.h4),
                          if (selectedToothNumber != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$selectedToothNumber Selected',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        selectedToothNumber != null
                            ? 'Showing clinical history for ${dummySelected!.toothName}'
                            : 'All recorded chronological tooth procedures & diagnostic notes (${allRecords.length} entries)',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (selectedToothNumber != null)
                    TextButton.icon(
                      onPressed: () => onClearSelection(null),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('View All Teeth', style: TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 8),
                  AppButton(
                    text: selectedToothNumber != null
                        ? 'Record Tooth #$selectedToothNumber'
                        : 'Add Tooth Record',
                    icon: Icons.add,
                    onPressed: () {
                      AddToothRecordDialog.show(
                        context,
                        patient: patient,
                        initialToothNumber: selectedToothNumber,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Timeline Body
          if (filteredRecords.isEmpty)
            _buildEmptyState(context)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRecords.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (ctx, index) {
                final rec = filteredRecords[index];
                return _buildTimelineItem(context, rec, isFirst: index == 0, isLast: index == filteredRecords.length - 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 44, color: AppColors.textMuted.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            selectedToothNumber != null
                ? 'No clinical records logged yet for Tooth #$selectedToothNumber'
                : 'No digital tooth records logged yet for this patient',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Click "Add Tooth Record" or select a tooth from the FDI chart above to log restorations, RCT, extractions, or diagnostics.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          AppButton.outline(
            text: selectedToothNumber != null
                ? 'Log First Record for Tooth #$selectedToothNumber'
                : 'Log First Tooth Record',
            icon: Icons.add,
            onPressed: () {
              AddToothRecordDialog.show(
                context,
                patient: patient,
                initialToothNumber: selectedToothNumber,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, ToothRecord rec, {required bool isFirst, required bool isLast}) {
    final clinic = context.clinic;
    final dateStr = DateFormat('dd MMM yyyy').format(rec.treatmentDate);
    final followUpStr = rec.followUpDate != null
        ? DateFormat('dd MMM yyyy').format(rec.followUpDate!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rec.status.color.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tooth badge, Date, Status Chip, Completion Status, Delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tooth number badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FDI #${rec.toothNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tooth anatomical name
              Expanded(
                child: Text(
                  rec.toothName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rec.status.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: rec.status.color.withOpacity(0.4)),
                ),
                child: Text(
                  rec.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rec.status.color,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Completion Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rec.completionStatus.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: rec.completionStatus.color.withOpacity(0.3)),
                ),
                child: Text(
                  rec.completionStatus.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rec.completionStatus.color,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Delete Record Action
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                splashRadius: 18,
                tooltip: 'Delete Record',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Tooth Record?'),
                      content: Text('Are you sure you want to remove the record for Tooth #${rec.toothNumber}? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                          onPressed: () {
                            clinic.deleteToothRecord(rec.id);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Procedure Name
          if (rec.procedure.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.procedure,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

          if (rec.clinicalFinding.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Finding: ${rec.clinicalFinding}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (rec.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.notes,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Metadata footer: Dentist & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_pin, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    rec.dentistName.isNotEmpty ? rec.dentistName : 'Attending Dentist',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(dateStr, style: AppTextStyles.caption),
                ],
              ),
              if (followUpStr != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_repeat, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        'Follow-up: $followUpStr',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
