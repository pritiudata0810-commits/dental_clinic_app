import 'dart:convert';
import 'package:intl/intl.dart';
import '../../state/clinic_state.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/billing.dart';
import '../../models/call_reminder.dart';

/// Registry of real internal tools that query actual clinic state.
/// Ensures the AI NEVER invents clinic appointments, balances, or patients.
/// Statically strips private credentials, biometric data, and passwords.
class ClinicToolsRegistry {
  /// Standard OpenAI-compatible Tool Specifications
  static List<Map<String, dynamic>> getToolDefinitions() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'getTodaysAppointments',
          'description': 'Retrieve all dental appointments scheduled for today with patient names, times, doctor names, status, and treatment reasons.',
          'parameters': {
            'type': 'object',
            'properties': {
              'statusFilter': {
                'type': 'string',
                'description': 'Optional filter: scheduled, waiting, inProgress, completed, cancelled, confirmed',
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getTomorrowAppointments',
          'description': 'Retrieve all dental appointments scheduled for tomorrow with patient names, times, assigned doctors, and status.',
          'parameters': {
            'type': 'object',
            'properties': {},
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'searchPatients',
          'description': 'Search clinic patient directory by name, phone number, or patient ID.',
          'parameters': {
            'type': 'object',
            'properties': {
              'query': {
                'type': 'string',
                'description': 'Patient name or partial name to search for (e.g. Rahul, Priya, Sharma)',
              },
            },
            'required': ['query'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getPatientAppointments',
          'description': 'Get all past, today, and upcoming appointments for a specific patient by name or ID.',
          'parameters': {
            'type': 'object',
            'properties': {
              'patientNameOrId': {
                'type': 'string',
                'description': 'Patient name or ID to look up appointment history for',
              },
            },
            'required': ['patientNameOrId'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getDoctorAvailability',
          'description': 'Check real-time availability, consultation status, and daily schedules of dental doctors.',
          'parameters': {
            'type': 'object',
            'properties': {
              'doctorName': {
                'type': 'string',
                'description': 'Optional doctor name (e.g. Dr. Rajesh, Dr. Priya)',
              },
              'timeSlot': {
                'type': 'string',
                'description': 'Optional specific time inquiry (e.g. 4 PM, 16:00, tomorrow afternoon)',
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getPendingPayments',
          'description': 'Retrieve all unpaid or partially paid billing invoices, overdue amounts, and debtor patient balances.',
          'parameters': {
            'type': 'object',
            'properties': {},
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getPatientBalance',
          'description': 'Calculate outstanding financial balance, total billed amount, and payment history for a specific patient.',
          'parameters': {
            'type': 'object',
            'properties': {
              'patientNameOrId': {
                'type': 'string',
                'description': 'Patient name or ID to inspect billing balance for',
              },
            },
            'required': ['patientNameOrId'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getFollowUps',
          'description': 'Retrieve all pending call reminders, post-procedure follow-ups, and unconfirmed patient visits.',
          'parameters': {
            'type': 'object',
            'properties': {
              'status': {
                'type': 'string',
                'description': 'Optional reminder status: pending, confirmed, retryRequired, missed',
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getClinicSummary',
          'description': 'Get a high-level operational overview of today: total appointments, waiting room queue, doctor status, and daily billing/collections.',
          'parameters': {
            'type': 'object',
            'properties': {},
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getInvoiceDetails',
          'description': 'Retrieve full financial and line-item details for a specific invoice by invoice number or ID.',
          'parameters': {
            'type': 'object',
            'properties': {
              'invoiceNumberOrId': {
                'type': 'string',
                'description': 'Invoice number or ID (e.g. INV-2026-001, INV-101)',
              },
            },
            'required': ['invoiceNumberOrId'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getBillingSummary',
          'description': 'Calculate aggregated billing totals, collections, outstanding receivables, and collection rate for a given period.',
          'parameters': {
            'type': 'object',
            'properties': {
              'period': {
                'type': 'string',
                'description': 'Period: today, yesterday, or this_week',
              },
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'getPaymentHistory',
          'description': 'Retrieve payment ledger records for a patient or overall clinic payments.',
          'parameters': {
            'type': 'object',
            'properties': {
              'patientNameOrId': {
                'type': 'string',
                'description': 'Optional patient name or ID to filter payment history',
              },
              'period': {
                'type': 'string',
                'description': 'Optional period: today, yesterday, this_week',
              },
            },
          },
        },
      },
    ];
  }

  /// Executes the requested tool securely against the application's actual data state.
  /// Minimizes patient data exposure and returns structured ground-truth facts.
  static Future<String> executeTool({
    required String toolName,
    required Map<String, dynamic> arguments,
    required ClinicState clinicState,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('hh:mm a');

    String? domainError;
    switch (toolName) {
      case 'getTodaysAppointments':
      case 'getTomorrowAppointments':
      case 'getAppointmentCount':
        domainError = clinicState.appointmentsError;
        break;
      case 'searchPatients':
        domainError = clinicState.patientsError;
        break;
      case 'getDoctorAvailability':
        domainError = clinicState.doctorsError ?? clinicState.appointmentsError;
        break;
      case 'getPendingInvoices':
      case 'getInvoiceDetails':
      case 'getPeriodBilling':
        domainError = clinicState.billingError;
        break;
      case 'getPendingPayments':
      case 'getTodayRevenue':
      case 'getCollectionRate':
      case 'getPaymentHistory':
        domainError = clinicState.paymentsError;
        break;
      case 'getUpcomingFollowUps':
        domainError = clinicState.remindersError;
        break;
      case 'getClinicSummary':
        domainError = clinicState.appointmentsError ??
            clinicState.patientsError ??
            clinicState.billingError;
        break;
    }

    if (domainError != null) {
      return jsonEncode({
        'error': domainError,
      });
    }

    switch (toolName) {
      case 'getTodaysAppointments':
        final todayList = clinicState.todayAppointments;
        final statusFilter = arguments['statusFilter']?.toString().toLowerCase();

        final filtered = todayList.where((apt) {
          if (statusFilter == null || statusFilter.isEmpty) return true;
          return apt.status.name.toLowerCase().contains(statusFilter);
        }).toList();

        final result = filtered.map((apt) {
          return {
            'id': apt.id,
            'patientName': apt.patientName,
            'time': apt.timeString.isNotEmpty ? apt.timeString : timeFormat.format(apt.dateTime),
            'status': apt.status.label,
            'doctorName': apt.doctorName,
            'treatment': apt.appointmentType,
            'tokenNumber': apt.tokenNumber,
            'isConfirmed': apt.status != AppointmentStatus.scheduled,
          };
        }).toList();

        return jsonEncode({
          'date': dateFormat.format(DateTime.now()),
          'totalAppointmentsToday': todayList.length,
          'returnedCount': result.length,
          'appointments': result,
        });

      case 'getTomorrowAppointments':
        final tomorrowList = clinicState.tomorrowAppointments;
        final tomorrowDate = DateTime.now().add(const Duration(days: 1));

        final result = tomorrowList.map((apt) {
          return {
            'id': apt.id,
            'patientName': apt.patientName,
            'time': apt.timeString.isNotEmpty ? apt.timeString : timeFormat.format(apt.dateTime),
            'status': apt.status.label,
            'doctorName': apt.doctorName,
            'treatment': apt.appointmentType,
          };
        }).toList();

        return jsonEncode({
          'date': dateFormat.format(tomorrowDate),
          'totalAppointmentsTomorrow': result.length,
          'appointments': result,
        });

      case 'searchPatients':
        final query = arguments['query']?.toString().toLowerCase().trim() ?? '';
        if (query.isEmpty) {
          return jsonEncode({'error': 'Search query cannot be empty'});
        }

        final matches = clinicState.patients.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.id.toLowerCase().contains(query) ||
              p.phone.contains(query);
        }).toList();

        final result = matches.map((p) {
          return {
            'id': p.id,
            'name': p.name,
            'age': p.age,
            'gender': p.gender,
            'phone': p.phone,
            'lastVisit': p.lastVisit,
            'medicalAlerts': p.medicalAlerts,
          };
        }).toList();

        return jsonEncode({
          'query': query,
          'matchCount': result.length,
          'patients': result,
        });

      case 'getPatientAppointments':
        final nameOrId = arguments['patientNameOrId']?.toString().toLowerCase().trim() ?? '';
        if (nameOrId.isEmpty) {
          return jsonEncode({'error': 'Patient name or ID is required'});
        }

        final apts = clinicState.appointments.where((a) {
          return a.patientName.toLowerCase().contains(nameOrId) ||
              a.patientId.toLowerCase() == nameOrId;
        }).toList();

        final result = apts.map((a) {
          return {
            'id': a.id,
            'patientName': a.patientName,
            'dateTime': DateFormat('dd MMM yyyy, hh:mm a').format(a.dateTime),
            'status': a.status.label,
            'doctorName': a.doctorName,
            'treatment': a.appointmentType,
          };
        }).toList();

        return jsonEncode({
          'patientQuery': nameOrId,
          'totalFound': result.length,
          'appointments': result,
        });

      case 'getDoctorAvailability':
        final doctorFilter = arguments['doctorName']?.toString().toLowerCase();
        final doctors = clinicState.doctors.where((d) {
          if (doctorFilter == null || doctorFilter.isEmpty) return true;
          return d.name.toLowerCase().contains(doctorFilter);
        }).toList();

        final result = doctors.map((d) {
          final docAppointmentsToday = clinicState.todayAppointments
              .where((a) => a.doctorId == d.id || a.doctorName == d.name)
              .toList();

          return {
            'id': d.id,
            'name': d.name,
            'specialization': d.specialization,
            'status': d.status.label,
            'isAvailableNow': d.status == DoctorStatus.available,
            'appointmentsTodayCount': docAppointmentsToday.length,
            'bookedTimesToday': docAppointmentsToday
                .map((a) => a.timeString.isNotEmpty ? a.timeString : timeFormat.format(a.dateTime))
                .toList(),
          };
        }).toList();

        return jsonEncode({
          'doctors': result,
          'totalAvailable': doctors.where((d) => d.status == DoctorStatus.available).length,
        });

      case 'getPendingPayments':
        final pendingInvoices = clinicState.invoices.where((inv) {
          return inv.status == PaymentStatus.pending ||
              inv.status == PaymentStatus.partial;
        }).toList();

        final result = pendingInvoices.map((inv) {
          return {
            'invoiceId': inv.id,
            'invoiceNumber': inv.invoiceNumber,
            'patientName': inv.patientName,
            'totalAmount': inv.totalAmount,
            'paidAmount': inv.paidAmount,
            'balanceAmount': inv.balanceAmount,
            'status': inv.status.label,
            'date': dateFormat.format(inv.date),
          };
        }).toList();

        final totalPendingSum = pendingInvoices.fold(0.0, (sum, inv) => sum + inv.balanceAmount);

        return jsonEncode({
          'totalPendingCount': result.length,
          'totalPendingAmount': totalPendingSum,
          'currency': 'INR (₹)',
          'invoices': result,
        });

      case 'getPatientBalance':
        final nameOrId = arguments['patientNameOrId']?.toString().toLowerCase().trim() ?? '';
        final patientInvoices = clinicState.invoices.where((inv) {
          return inv.patientName.toLowerCase().contains(nameOrId) ||
              inv.patientId.toLowerCase() == nameOrId;
        }).toList();

        double totalBilled = 0.0;
        double totalPaid = 0.0;
        double totalDue = 0.0;

        for (final inv in patientInvoices) {
          totalBilled += inv.totalAmount;
          totalPaid += inv.paidAmount;
          totalDue += inv.balanceAmount;
        }

        return jsonEncode({
          'patientQuery': nameOrId,
          'invoiceCount': patientInvoices.length,
          'totalBilled': totalBilled,
          'totalPaid': totalPaid,
          'outstandingBalanceDue': totalDue,
          'currency': 'INR (₹)',
        });

      case 'getFollowUps':
        final statusArg = arguments['status']?.toString().toLowerCase();
        final reminders = clinicState.callReminders.where((r) {
          if (statusArg == null || statusArg.isEmpty) return true;
          return r.status.name.toLowerCase().contains(statusArg);
        }).toList();

        final result = reminders.map((r) {
          return {
            'id': r.id,
            'patientName': r.patientName,
            'phoneNumber': r.phoneNumber,
            'appointmentType': r.appointmentType,
            'appointmentDate': r.appointmentDate,
            'appointmentTime': r.appointmentTime,
            'status': r.status.label,
            'lastAttempt': r.lastAttempt,
            'nextAttempt': r.nextAttempt,
          };
        }).toList();

        return jsonEncode({
          'remindersCount': result.length,
          'pendingCount': clinicState.pendingRemindersCount,
          'confirmedCount': clinicState.confirmedRemindersCount,
          'followUps': result,
        });

      case 'getClinicSummary':
        final now = DateTime.now();
        final todayList = clinicState.todayAppointments;
        final waitingCount = clinicState.waitingRoomCount;
        final completedCount = todayList.where((a) => a.status == AppointmentStatus.completed).length;
        final cancelledCount = todayList.where((a) => a.status == AppointmentStatus.cancelled).length;
        final inProgressCount = todayList.where((a) => a.status == AppointmentStatus.inProgress).length;

        // Busiest doctor today
        final Map<String, int> docCounts = {};
        for (final apt in todayList) {
          docCounts[apt.doctorName] = (docCounts[apt.doctorName] ?? 0) + 1;
        }
        String busiestDoctor = 'None';
        int maxApts = 0;
        docCounts.forEach((doc, count) {
          if (count > maxApts) {
            maxApts = count;
            busiestDoctor = doc;
          }
        });

        return jsonEncode({
          'date': DateFormat('dd MMMM yyyy').format(now),
          'totalAppointmentsToday': todayList.length,
          'waitingRoomQueue': waitingCount,
          'inProgressCount': inProgressCount,
          'completedCount': completedCount,
          'cancelledCount': cancelledCount,
          'availableDoctorsCount': clinicState.availableDoctorsCount,
          'busiestDoctorToday': busiestDoctor,
          'busiestDoctorAppointments': maxApts,
          'todayBillingTotal': clinicState.todayBillingTotal,
          'todayCollectedTotal': clinicState.todayCollectedTotal,
          'pendingRemindersCount': clinicState.pendingRemindersCount,
        });

      case 'getInvoiceDetails':
        final invoiceNumOrId = arguments['invoiceNumberOrId']?.toString().trim() ?? '';
        if (invoiceNumOrId.isEmpty) {
          return jsonEncode({'error': 'Invoice identifier is required'});
        }
        final match = clinicState.invoices.firstWhere(
          (inv) =>
              inv.invoiceNumber.toLowerCase() == invoiceNumOrId.toLowerCase() ||
              inv.id.toLowerCase() == invoiceNumOrId.toLowerCase(),
          orElse: () => Invoice(
            id: '',
            invoiceNumber: '',
            patientId: '',
            patientName: '',
            patientPhone: '',
            doctorId: '',
            doctorName: '',
            date: DateTime.now(),
            items: const [],
            subtotal: 0,
            totalAmount: 0,
            paidAmount: 0,
            balanceAmount: 0,
            status: PaymentStatus.pending,
            paymentMethod: '',
          ),
        );

        if (match.id.isEmpty && match.invoiceNumber.isEmpty) {
          return jsonEncode({'found': false, 'error': 'Invoice not found: $invoiceNumOrId'});
        }

        return jsonEncode({
          'found': true,
          'id': match.id,
          'invoiceNumber': match.invoiceNumber,
          'patientId': match.patientId,
          'patientName': match.patientName,
          'patientPhone': match.patientPhone,
          'doctorId': match.doctorId,
          'doctorName': match.doctorName,
          'date': DateFormat('yyyy-MM-dd').format(match.date),
          'status': match.status.name,
          'subtotal': match.subtotal,
          'discount': match.discount,
          'tax': match.tax,
          'totalAmount': match.totalAmount,
          'paidAmount': match.paidAmount,
          'balanceAmount': match.balanceAmount,
          'paymentMethod': match.paymentMethod,
          'receiptNumber': match.receiptNumber,
          'notes': match.notes,
          'items': match.items.map((it) => {
            'description': it.description,
            'quantity': it.quantity,
            'unitPrice': it.unitPrice,
            'amount': it.amount,
          }).toList(),
        });

      case 'getBillingSummary':
        final period = arguments['period']?.toString().toLowerCase().trim() ?? 'today';
        final now = DateTime.now();
        List<Invoice> filteredInvoices = [];

        DateTime start;
        DateTime end;

        if (period == 'yesterday') {
          final yesterday = now.subtract(const Duration(days: 1));
          start = DateTime(yesterday.year, yesterday.month, yesterday.day);
          end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        } else if (period == 'this_week' || period == 'week') {
          final monday = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(monday.year, monday.month, monday.day);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        } else {
          start = DateTime(now.year, now.month, now.day);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        }

        filteredInvoices = clinicState.invoices.where((inv) {
          return inv.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                 inv.date.isBefore(end.add(const Duration(seconds: 1)));
        }).toList();

        double totalBilled = 0.0;
        double totalCollected = 0.0;
        double outstandingBalance = 0.0;
        int paidCount = 0;
        int pendingCount = 0;
        int partialCount = 0;

        for (final inv in filteredInvoices) {
          totalBilled += inv.totalAmount;
          totalCollected += inv.paidAmount;
          outstandingBalance += inv.balanceAmount;
          if (inv.status == PaymentStatus.paid) {
            paidCount++;
          } else if (inv.status == PaymentStatus.partial) {
            partialCount++;
          } else {
            pendingCount++;
          }
        }

        if (period == 'today') {
          totalBilled = clinicState.todayBillingTotal;
          totalCollected = clinicState.todayCollectedTotal;
        }

        final double? collectionRate = totalBilled > 0
            ? (totalCollected / totalBilled) * 100
            : null;

        return jsonEncode({
          'period': period,
          'startDate': DateFormat('yyyy-MM-dd').format(start),
          'endDate': DateFormat('yyyy-MM-dd').format(end),
          'totalInvoices': filteredInvoices.length,
          'totalBilled': totalBilled,
          'totalCollected': totalCollected,
          'outstandingBalance': outstandingBalance,
          'collectionRate': collectionRate,
          'paidInvoicesCount': paidCount,
          'pendingInvoicesCount': pendingCount,
          'partialInvoicesCount': partialCount,
        });

      case 'getPaymentHistory':
        final patientQuery = arguments['patientNameOrId']?.toString().toLowerCase().trim();
        final records = clinicState.paymentRecords;

        final filtered = records.where((r) {
          if (patientQuery == null || patientQuery.isEmpty) return true;
          return r.patientName.toLowerCase().contains(patientQuery) ||
                 r.patientId.toLowerCase() == patientQuery;
        }).toList();

        final result = filtered.map((r) {
          return {
            'id': r.id,
            'invoiceId': r.invoiceId,
            'patientId': r.patientId,
            'patientName': r.patientName,
            'amount': r.amount,
            'paymentMethod': r.paymentMethod,
            'receiptNumber': r.receiptNumber,
            'transactionRef': r.transactionRef,
            'paymentDate': r.paymentDate.toIso8601String(),
            'notes': r.notes,
          };
        }).toList();

        double totalCollectedFromRecords = 0.0;
        for (final r in filtered) {
          totalCollectedFromRecords += r.amount;
        }

        return jsonEncode({
          'count': result.length,
          'totalCollected': totalCollectedFromRecords,
          'records': result,
        });

      default:
        return jsonEncode({'error': 'Unknown tool: $toolName'});
    }
  }

  /// High-level prompt grounding summary provided to the model in every system prompt.
  /// Gives immediate real-time stats without requiring function execution for simple counts.
  static String buildLiveClinicGrounding(ClinicState clinicState) {
    final now = DateTime.now();
    return '''
[LIVE GROUND-TRUTH CLINIC DATA - TODAY: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}]
- Clinic: SmileCare Dental Clinic (Pune Camp)
- Total Appointments Scheduled Today: ${clinicState.todayAppointments.length}
- Waiting Room Active Queue: ${clinicState.waitingRoomCount} patients
- Total Registered Patients: ${clinicState.patients.length}
- Total Dental Doctors: ${clinicState.doctors.length} (${clinicState.availableDoctorsCount} currently available)
- Pending Call Reminders: ${clinicState.pendingRemindersCount}
- Today's Billed Total: ₹${clinicState.todayBillingTotal.toStringAsFixed(0)} | Collected: ₹${clinicState.todayCollectedTotal.toStringAsFixed(0)}
''';
  }
}
