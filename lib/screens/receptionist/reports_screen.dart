import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/appointment.dart';
import '../../models/billing.dart';
import '../../models/tooth_record.dart';
import '../../widgets/common/app_card.dart';

enum PracticeReportTimeRange {
  today,
  thisWeek,
  thisMonth,
  allTime;

  String get label {
    switch (this) {
      case PracticeReportTimeRange.today:
        return 'Today';
      case PracticeReportTimeRange.thisWeek:
        return 'This Week';
      case PracticeReportTimeRange.thisMonth:
        return 'This Month';
      case PracticeReportTimeRange.allTime:
        return 'All Time';
    }
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  PracticeReportTimeRange _timeRange = PracticeReportTimeRange.thisWeek;

  bool _isWithinRange(DateTime date, PracticeReportTimeRange range) {
    final now = DateTime.now();
    switch (range) {
      case PracticeReportTimeRange.today:
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case PracticeReportTimeRange.thisWeek:
        final startOfWeek = now.subtract(const Duration(days: 7));
        return date.isAfter(startOfWeek);
      case PracticeReportTimeRange.thisMonth:
        final startOfMonth = now.subtract(const Duration(days: 30));
        return date.isAfter(startOfMonth);
      case PracticeReportTimeRange.allTime:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();

    // -------------------------------------------------------------
    // DYNAMIC METRIC CALCULATIONS FROM CLINIC STATE
    // -------------------------------------------------------------
    final allAppointments = clinic.appointments;
    final allInvoices = clinic.invoices;
    final allPatients = clinic.patients;
    final allDoctors = clinic.doctors;
    final allToothRecords = clinic.toothRecords;

    // Filter by selected range
    final filteredAppointments = allAppointments
        .where((a) => _isWithinRange(a.dateTime, _timeRange))
        .toList();
    final filteredInvoices = allInvoices
        .where((inv) => _isWithinRange(inv.date, _timeRange))
        .toList();
    final filteredToothRecords = allToothRecords
        .where((t) => _isWithinRange(t.treatmentDate, _timeRange))
        .toList();

    // 13 Key Practice Metrics:
    // 1. Total Appointments
    final totalAppointments = filteredAppointments.length;

    // 2. Completed Sessions
    final completedAppointments = filteredAppointments
        .where((a) => a.status == AppointmentStatus.completed)
        .length;

    // 3. In-Progress / Waiting Room
    final waitingOrInProgress = filteredAppointments
        .where((a) =>
            a.status == AppointmentStatus.inProgress ||
            a.status == AppointmentStatus.waiting ||
            a.status == AppointmentStatus.arrived ||
            a.status == AppointmentStatus.checkedIn)
        .length;

    // 4. Cancellations & No-Shows
    final cancelledOrNoShow = filteredAppointments
        .where((a) =>
            a.status == AppointmentStatus.cancelled ||
            a.status == AppointmentStatus.noShow)
        .length;

    // 5. Gross Invoiced Revenue
    final grossRevenue = filteredInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.totalAmount,
    );

    // 6. Net Collections Collected
    final collectedRevenue = filteredInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.paidAmount,
    );

    // 7. Outstanding Receivables
    final outstandingReceivables = filteredInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.balanceAmount,
    );

    // 8. Average Revenue per Visit
    final avgRevenuePerVisit = completedAppointments > 0
        ? grossRevenue / completedAppointments
        : (totalAppointments > 0 ? grossRevenue / totalAppointments : 0.0);

    // 9. Total Registered Patients
    final totalPatients = allPatients.length;

    // 10. New Patient Intake in Range
    final newPatientsInRange = allPatients
        .where((p) => _isWithinRange(p.registrationDate, _timeRange))
        .length;

    // 11. Total Tooth Procedures Tracked
    final totalProceduresTracked = filteredToothRecords.length;

    // 12. Appointment Completion Rate (%)
    final completionRate = totalAppointments > 0
        ? ((completedAppointments / totalAppointments) * 100).round()
        : 100;

    // 13. Active Pathologies / Unresolved Cases
    final unresolvedPathologies = filteredToothRecords
        .where((t) =>
            t.status == ToothStatus.caries ||
            t.status == ToothStatus.underTreatment ||
            t.status == ToothStatus.requiresFollowUp)
        .length;

    // Collections efficiency
    final collectionEfficiency = grossRevenue > 0
        ? ((collectedRevenue / grossRevenue) * 100).round()
        : 100;

    // Primary KPI cards
    final kpi1 = _buildMetricCard(
      'TOTAL APPOINTMENTS',
      '$totalAppointments',
      '$waitingOrInProgress active • $cancelledOrNoShow cancelled',
      Icons.calendar_month,
      AppColors.primary,
    );
    final kpi2 = _buildMetricCard(
      'COMPLETED SESSIONS',
      '$completedAppointments',
      '$completionRate% completion rate',
      Icons.task_alt,
      const Color(0xFF10B981),
    );
    final kpi3 = _buildMetricCard(
      'NEW PATIENT INTAKE',
      '$newPatientsInRange',
      'Total registry: $totalPatients',
      Icons.person_add_alt_1,
      const Color(0xFF8B5CF6),
    );
    final kpi4 = _buildMetricCard(
      'REVENUE COLLECTED',
      currency.format(collectedRevenue),
      '${currency.format(outstandingReceivables)} pending',
      Icons.account_balance_wallet,
      const Color(0xFF0D9488),
    );

    // Secondary KPI cards
    final sec1 = _buildMetricCard(
      'GROSS BILLED VOLUME',
      currency.format(grossRevenue),
      '${filteredInvoices.length} invoices generated',
      Icons.receipt_long_outlined,
      const Color(0xFF3B82F6),
    );
    final sec2 = _buildMetricCard(
      'AVG REVENUE / VISIT',
      currency.format(avgRevenuePerVisit),
      'Across $completedAppointments consultations',
      Icons.show_chart,
      const Color(0xFFF59E0B),
    );
    final sec3 = _buildMetricCard(
      'TOOTH PROCEDURES',
      '$totalProceduresTracked',
      '$unresolvedPathologies pending review',
      Icons.medical_services_outlined,
      const Color(0xFF6366F1),
    );
    final sec4 = _buildMetricCard(
      'COLLECTION EFFICIENCY',
      '$collectionEfficiency%',
      '${currency.format(outstandingReceivables)} outstanding',
      Icons.verified_outlined,
      collectionEfficiency >= 80 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
    );

    // Chart Card
    final chartCard = AppCard(
      title: 'Daily Patient Volume & Consultations',
      subtitle: 'Scheduled appointments vs successfully completed visits over recent days',
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildRealSevenDayBarChart(allAppointments, now),
          const SizedBox(height: 24),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppColors.primaryLight, 'Scheduled / Attended'),
              const SizedBox(width: 24),
              _buildLegend(const Color(0xFF10B981), 'Successfully Completed'),
            ],
          ),
        ],
      ),
    );

    // Doctor Share Card
    final doctorCard = AppCard(
      title: 'Dentist Operatory Share',
      subtitle: 'Real consultation load and patient distribution by clinician',
      child: Column(
        children: [
          ...allDoctors.map((doc) {
            final docAppts = filteredAppointments
                .where((a) => a.doctorId == doc.id || a.doctorName == doc.name)
                .length;
            final ratio = totalAppointments > 0 ? (docAppts / totalAppointments) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildDoctorProgress(
                doc.name,
                doc.specialization,
                ratio,
                '$docAppts Patients (${(ratio * 100).round()}%)',
              ),
            );
          }),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    allDoctors.isNotEmpty
                        ? 'Lead clinician this period: ${_getTopDoctorName(allDoctors, filteredAppointments)} with ${filteredAppointments.length} total scheduled visits.'
                        : 'Practice clinicians actively monitoring appointments.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Payments Card
    final paymentsCard = AppCard(
      title: 'Collections by Payment Method',
      subtitle: 'Channel breakdown for invoices in selected period',
      child: _buildPaymentMethodBreakdown(filteredInvoices, currency, grossRevenue),
    );

    // Top Treatments Card
    final treatmentsCard = AppCard(
      title: 'Top Treatments & Services Delivered',
      subtitle: 'Clinical procedures aggregated from tooth timelines and billing',
      child: _buildTopTreatmentsList(filteredToothRecords, filteredInvoices, currency),
    );

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
                    const Text('Practice Intelligence & Clinical Analytics', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Live practice telemetry calculated directly from patient records, dental timelines, and billing accounts',
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
                  children: PracticeReportTimeRange.values.map((range) {
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
                          range.label,
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

          // -------------------------------------------------------------
          // PRIMARY KPI ROW
          // -------------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  children: [
                    Expanded(child: kpi1),
                    const SizedBox(width: 16),
                    Expanded(child: kpi2),
                    const SizedBox(width: 16),
                    Expanded(child: kpi3),
                    const SizedBox(width: 16),
                    Expanded(child: kpi4),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(children: [Expanded(child: kpi1), const SizedBox(width: 16), Expanded(child: kpi2)]),
                    const SizedBox(height: 16),
                    Row(children: [Expanded(child: kpi3), const SizedBox(width: 16), Expanded(child: kpi4)]),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------------------
          // SECONDARY 4-METRIC ROW
          // -------------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  children: [
                    Expanded(child: sec1),
                    const SizedBox(width: 16),
                    Expanded(child: sec2),
                    const SizedBox(width: 16),
                    Expanded(child: sec3),
                    const SizedBox(width: 16),
                    Expanded(child: sec4),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(children: [Expanded(child: sec1), const SizedBox(width: 16), Expanded(child: sec2)]),
                    const SizedBox(height: 16),
                    Row(children: [Expanded(child: sec3), const SizedBox(width: 16), Expanded(child: sec4)]),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // -------------------------------------------------------------
          // 7-DAY VOLUME CHART & DENTIST LOAD BREAKDOWN
          // -------------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 850) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: chartCard),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: doctorCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    chartCard,
                    const SizedBox(height: 20),
                    doctorCard,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // -------------------------------------------------------------
          // REVENUE INTELLIGENCE & PAYMENT MODES
          // -------------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 850) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: paymentsCard),
                    const SizedBox(width: 20),
                    Expanded(flex: 5, child: treatmentsCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    paymentsCard,
                    const SizedBox(height: 20),
                    treatmentsCard,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRealSevenDayBarChart(List<Appointment> allAppointments, DateTime now) {
    final days = <Widget>[];
    int maxDaily = 1;

    // Calculate max volume for scaling
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final count = allAppointments.where((a) =>
          a.dateTime.year == date.year &&
          a.dateTime.month == date.month &&
          a.dateTime.day == date.day).length;
      if (count > maxDaily) maxDaily = count;
    }

    // Build each of the 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = DateFormat('E').format(date);
      final isToday = i == 0;

      final dayAppts = allAppointments.where((a) =>
          a.dateTime.year == date.year &&
          a.dateTime.month == date.month &&
          a.dateTime.day == date.day).toList();

      final scheduled = dayAppts.length;
      final completed = dayAppts.where((a) => a.status == AppointmentStatus.completed).length;

      days.add(_buildBar(dayName, scheduled, completed, maxDaily: maxDaily, isToday: isToday));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days,
    );
  }

  Widget _buildPaymentMethodBreakdown(
    List<Invoice> invoices,
    NumberFormat currency,
    double totalGross,
  ) {
    if (invoices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No invoices recorded in this time range.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final Map<String, double> methodTotals = {};
    for (final inv in invoices) {
      final method = inv.paymentMethod.isNotEmpty ? inv.paymentMethod : 'Cash';
      methodTotals[method] = (methodTotals[method] ?? 0.0) + inv.paidAmount;
    }

    return Column(
      children: methodTotals.entries.map((entry) {
        final ratio = totalGross > 0 ? (entry.value / totalGross) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(_getPaymentIcon(entry.key), size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${currency.format(entry.value)} (${(ratio * 100).round()}%)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    entry.key.toLowerCase().contains('upi')
                        ? const Color(0xFF0D9488)
                        : entry.key.toLowerCase().contains('card')
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopTreatmentsList(
    List<ToothRecord> toothRecords,
    List<Invoice> invoices,
    NumberFormat currency,
  ) {
    // Collect from tooth records & invoices
    final Map<String, int> procedureCounts = {};

    for (final t in toothRecords) {
      if (t.procedure.isNotEmpty) {
        procedureCounts[t.procedure] = (procedureCounts[t.procedure] ?? 0) + 1;
      }
    }

    for (final inv in invoices) {
      for (final item in inv.items) {
        if (item.description.isNotEmpty) {
          procedureCounts[item.description] = (procedureCounts[item.description] ?? 0) + item.quantity;
        }
      }
    }

    if (procedureCounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No treatments recorded in this period.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final sortedEntries = procedureCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topFive = sortedEntries.take(5);

    return Column(
      children: topFive.map((e) {
        return _buildTreatmentRow(e.key, e.value);
      }).toList(),
    );
  }

  IconData _getPaymentIcon(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('upi') || lower.contains('qr')) return Icons.qr_code_2;
    if (lower.contains('card')) return Icons.credit_card;
    if (lower.contains('insurance')) return Icons.health_and_safety;
    return Icons.payments_outlined;
  }

  String _getTopDoctorName(List<dynamic> doctors, List<Appointment> appts) {
    String topDoc = doctors.first.name;
    int maxCount = -1;
    for (final doc in doctors) {
      final count = appts.where((a) => a.doctorId == doc.id || a.doctorName == doc.name).length;
      if (count > maxCount) {
        maxCount = count;
        topDoc = doc.name;
      }
    }
    return topDoc;
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
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTextStyles.statValue),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, int scheduled, int completed, {required int maxDaily, bool isToday = false}) {
    final maxHeight = 130.0;
    final scheduledHeight = maxDaily > 0 ? ((scheduled / maxDaily) * maxHeight).clamp(4.0, maxHeight) : 4.0;
    final completedHeight = maxDaily > 0 ? ((completed / maxDaily) * maxHeight).clamp(4.0, maxHeight) : 4.0;

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
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(count, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 2),
        Text(specialty, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: AppColors.borderLight,
          valueColor: AlwaysStoppedAnimation<Color>(
            percent > 0.35 ? AppColors.primary : const Color(0xFF10B981),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTreatmentRow(String name, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(name,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count logged',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}
