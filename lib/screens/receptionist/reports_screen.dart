import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../widgets/common/app_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _timeRange = 'This Week'; // 'Today', 'This Week', 'This Month'

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Time Range Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reports & Practice Insights', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Operational statistics, patient volume, collections, and chair occupancy',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Time Range Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: ['Today', 'This Week', 'This Month'].map((range) {
                    final isSel = _timeRange == range;
                    return InkWell(
                      onTap: () => setState(() => _timeRange = range),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Overview KPI Numbers
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'TOTAL APPOINTMENTS',
                  '38',
                  '+12% vs last week',
                  Icons.calendar_month,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'COMPLETED SESSIONS',
                  '32',
                  '84% completion rate',
                  Icons.task_alt,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'NEW PATIENT INTAKE',
                  '14',
                  'Registered this week',
                  Icons.person_add_alt_1,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'REVENUE COLLECTED',
                  currency.format(clinic.todayBillingTotal * 2.4),
                  '₹4,500 pending collection',
                  Icons.account_balance_wallet,
                  const Color(0xFF0D9488),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Weekly Volume Chart & Doctor Load Breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly Appointments Volume Bar Chart
              Expanded(
                flex: 6,
                child: AppCard(
                  title: 'Daily Patient Volume & Consultations',
                  subtitle: 'Number of dental visits scheduled vs completed',
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBar('Mon', 14, 12),
                          _buildBar('Tue', 18, 16),
                          _buildBar('Wed', 22, 20),
                          _buildBar('Thu', 19, 18),
                          _buildBar('Fri', 24, 21),
                          _buildBar('Sat', 28, 25, isToday: true),
                          _buildBar('Sun', 8, 6),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.borderLight),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegend(AppColors.primary, 'Scheduled Visits'),
                          const SizedBox(width: 24),
                          _buildLegend(const Color(0xFF10B981), 'Successfully Completed'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Doctor Operatory Share
              Expanded(
                flex: 4,
                child: AppCard(
                  title: 'Dentist Operatory Share',
                  subtitle: 'Patient intake distribution by doctor',
                  child: Column(
                    children: [
                      _buildDoctorProgress('Dr. Rahul Sharma', 'Chief Implantologist', 0.42, '16 Patients'),
                      const SizedBox(height: 16),
                      _buildDoctorProgress('Dr. Priya Mehta', 'Orthodontics & Kids', 0.38, '14 Patients'),
                      const SizedBox(height: 16),
                      _buildDoctorProgress('Dr. Amit Shah', 'Endodontist (RCT)', 0.20, '8 Patients'),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Dr. Rahul Sharma has highest chair utilization (88%) this week.',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Treatment Types Breakdown Table
          AppCard(
            title: 'Top Treatments & Services Delivered',
            subtitle: 'Procedure counts and total invoice revenue',
            child: Column(
              children: [
                _buildTreatmentRow('Routine Oral Checkup & Consultation', 22, '₹11,000'),
                const Divider(color: AppColors.borderLight),
                _buildTreatmentRow('Single Sitting Rotary Root Canal (RCT)', 8, '₹52,000'),
                const Divider(color: AppColors.borderLight),
                _buildTreatmentRow('Ultrasonic Prophylaxis & Deep Cleaning', 14, '₹21,000'),
                const Divider(color: AppColors.borderLight),
                _buildTreatmentRow('Composite Resin Tooth Restoration', 12, '₹21,600'),
                const Divider(color: AppColors.borderLight),
                _buildTreatmentRow('CAD/CAM Ceramic Zirconia Crowns', 5, '₹60,000'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String subtext, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 10)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.statValue),
          const SizedBox(height: 4),
          Text(subtext, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBar(String day, int scheduled, int completed, {bool isToday = false}) {
    final maxHeight = 140.0;
    final scheduledHeight = (scheduled / 30) * maxHeight;
    final completedHeight = (completed / 30) * maxHeight;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 14,
              height: scheduledHeight,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 14,
              height: completedHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDoctorProgress(String name, String specialty, double percent, String count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Text(count, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 2),
        Text(specialty, style: AppTextStyles.caption),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          minHeight: 6,
          backgroundColor: AppColors.borderLight,
          valueColor: AlwaysStoppedAnimation<Color>(
            percent > 0.4 ? AppColors.primary : const Color(0xFF10B981),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTreatmentRow(String name, int count, String revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text('$count procedures', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: 24),
              SizedBox(
                width: 80,
                child: Text(
                  revenue,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
