import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/patient.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/search_bar_field.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/patients/add_patient_dialog.dart';
import 'patient_detail_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _searchQuery = '';
  Patient? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;

    // If viewing details for a selected patient:
    if (_selectedPatient != null) {
      // Find the latest version of this patient in state in case of updates
      final currentP = clinic.patients.firstWhere(
        (p) => p.id == _selectedPatient!.id,
        orElse: () => _selectedPatient!,
      );
      return PatientDetailScreen(
        patient: currentP,
        onBack: () => setState(() => _selectedPatient = null),
      );
    }

    final query = _searchQuery.toLowerCase().trim();
    final filteredPatients = clinic.patients.where((p) {
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.phone.contains(query) ||
          p.id.toLowerCase().contains(query) ||
          p.crNumber.toLowerCase().contains(query) ||
          p.assignedDoctorName.toLowerCase().contains(query);
    }).toList();

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Patients', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                'Manage patient profiles, clinical history, and treatment records',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search & Filter Toolbar
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SearchBarField(
                    hintText: 'Type patient name, mobile (+91), or patient ID (e.g. P-1001)...',
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${filteredPatients.length} Patients found',
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Patients Table / List
          if (filteredPatients.isEmpty)
            AppCard(
              child: EmptyStateView.noPatients(
                onAddPatient: () => AddPatientDialog.show(context),
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredPatients.length,
                separatorBuilder: (c, i) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final patient = filteredPatients[index];

                  return InkWell(
                    onTap: () => setState(() => _selectedPatient = patient),
                    hoverColor: AppColors.surfaceHover,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 950;

                          if (isNarrow) {
                            // Adaptive Stacked Layout for narrow screens / tablet
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(
                                        patient.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primaryDark),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(patient.name, style: AppTextStyles.h4, overflow: TextOverflow.ellipsis),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryLight,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                                ),
                                                child: Text('CR: ${patient.crNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceMuted,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(patient.id, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                                              ),
                                            ],
                                          ),
                                          Text('${patient.gender} • ${patient.phone}', style: AppTextStyles.bodySmall),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: patient.balanceDue > 0 ? const Color(0xFFFFE4E6) : const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        patient.balanceDue > 0 ? currency.format(patient.balanceDue) : 'Settled',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: patient.balanceDue > 0 ? const Color(0xFFDC2626) : const Color(0xFF047857),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.medical_services_outlined, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text('Doctor: ${patient.assignedDoctorName}', style: AppTextStyles.bodySmall),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.history_outlined, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text('Last: ${patient.lastVisit} (${patient.totalVisits} visits)', style: AppTextStyles.caption),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AppButton.outline(
                                  text: 'View Patient File',
                                  icon: Icons.chevron_right_rounded,
                                  onPressed: () => setState(() => _selectedPatient = patient),
                                ),
                              ],
                            );
                          }

                          // Desktop Balanced Row
                          return Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  patient.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name & ID
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(patient.name, style: AppTextStyles.h4, overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                          ),
                                          child: Text('CR: ${patient.crNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceMuted,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(patient.id, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${patient.gender} • ${patient.phone}',
                                      style: AppTextStyles.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Assigned Doctor
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(patient.assignedDoctorName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                    Text('Last: ${patient.lastVisit}', style: AppTextStyles.caption),
                                  ],
                                ),
                              ),

                              // Balance Due
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.balanceDue > 0 ? currency.format(patient.balanceDue) : 'Settled',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: patient.balanceDue > 0 ? const Color(0xFFDC2626) : const Color(0xFF047857),
                                      ),
                                    ),
                                    Text('${patient.totalVisits} visits', style: AppTextStyles.caption),
                                  ],
                                ),
                              ),

                              AppButton.outline(
                                text: 'View Patient File',
                                icon: Icons.chevron_right_rounded,
                                onPressed: () => setState(() => _selectedPatient = patient),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
