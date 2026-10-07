import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../state/clinic_state.dart';
import '../../models/appointment.dart';
import '../../models/billing.dart';
import '../../models/patient.dart';
import '../../models/call_reminder.dart';
import 'clinic_tools_registry.dart';
import 'local_dental_knowledge.dart';

/// Supported intents for the deterministic Local Assistant Engine.
enum AssistantIntent {
  todayAppointments,
  tomorrowAppointments,
  yesterdayAppointments,
  thisWeekAppointments,
  appointmentCount,
  patientSearch,
  doctorAvailability,
  pendingInvoices,
  pendingPayments,
  todayRevenue,
  clinicSummary,
  followUps,
  patientAppointments,
  patientBalance,
  patientFollowUp,
  patientSummary,
  invoiceDetails,
  collectionRate,
  periodBilling,
  paymentHistory,
  patientToothRecords,
  dentalKnowledge,
  unsupported,
}

/// Structured patient lookup result for safe disambiguation.
class PatientLookupResult {
  final List<Patient> matches;
  final String searchTerm;

  const PatientLookupResult({
    required this.matches,
    required this.searchTerm,
  });

  bool get isEmpty => matches.isEmpty;
  bool get isUnique => matches.length == 1;
  bool get isMultiple => matches.length > 1;
  Patient? get single => isUnique ? matches.first : null;
}

/// Structured response produced by the Local Assistant Engine.
class AssistantResponse {
  final String text;
  final AssistantIntent intent;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  const AssistantResponse({
    required this.text,
    required this.intent,
    this.success = true,
    this.errorMessage,
    this.data,
  });

  @override
  String toString() => 'AssistantResponse(intent: $intent, success: $success, text: $text)';
}

/// Pure local, deterministic AI Assistant engine.
/// Works with NO API key, makes NO external network calls,
/// and queries real application state directly via ClinicToolsRegistry and ClinicState.
class LocalAssistantEngine {
  /// Robust query normalization handling:
  /// - uppercase/lowercase differences
  /// - multiple spaces and leading/trailing whitespace
  /// - common punctuation
  /// - colloquial contraction expansions
  static String normalizeQuery(String raw) {
    var s = raw.toLowerCase().trim();

    // Normalize unicode/curly apostrophes
    s = s.replaceAll('’', "'").replaceAll('`', "'");

    // Expand common contractions and variations
    s = s.replaceAll("today's", "today").replaceAll("todays", "today");
    s = s.replaceAll("tomorrow's", "tomorrow").replaceAll("tomorrows", "tomorrow");
    s = s.replaceAll("yesterday's", "yesterday").replaceAll("yesterdays", "yesterday");
    s = s.replaceAll("who's", "who is");
    s = s.replaceAll("what's", "what is");
    s = s.replaceAll("how's", "how is");
    s = s.replaceAll("there's", "there is");

    // Replace punctuation with spaces
    s = s.replaceAll(RegExp(r'[?!.,;:"#%&*()\[\]{}_/\\-]'), ' ');

    // Condense repeated whitespace into a single space
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  /// Parses the user message into a discrete intent using normalized deterministic pattern matching.
  static AssistantIntent parseIntent(String query) {
    final q = normalizeQuery(query);
    if (q.isEmpty) return AssistantIntent.unsupported;

    // Check for explicit patient identifier cues (ID, Phone, possessive, preposition)
    final hasPatientId = RegExp(r'\b(?:p|pt)-\d+\b', caseSensitive: false).hasMatch(query);
    final hasPhone = RegExp(r'\b\d{10}\b').hasMatch(query);

    // Extract potential possessive subject (e.g. "Rahul's balance" vs "today's appointments")
    String? patientPossessiveWord;
    final pMatch = RegExp(r"\b([a-zA-Z0-9\-_]+)'s\b", caseSensitive: false).firstMatch(query);
    if (pMatch != null) {
      final word = pMatch.group(1)!.toLowerCase();
      const nonPatientWords = {
        'today', 'tomorrow', 'yesterday', 'who', 'what', 'how', 'there',
        'clinic', 'practice', 'doctor', 'dentist', 'day', 'week', 'month', 'year',
      };
      if (!nonPatientWords.contains(word)) {
        patientPossessiveWord = word;
      }
    }
    final hasPatientPossessive = patientPossessiveWord != null;

    // Check for prepositional patient reference (e.g. "for Rahul" vs "for today", "for this week")
    bool hasPatientPreposition = false;
    final prepMatch = RegExp(r"(?:appointments?|balance|follow\-?up)\s+(?:for|of|with)\s+([a-zA-Z0-9\-_]+(?:\s+[a-zA-Z0-9\-_]+)?)", caseSensitive: false).firstMatch(query);
    if (prepMatch != null) {
      final target = prepMatch.group(1)!.toLowerCase().trim();
      const nonPatientTargets = {
        'today', 'tomorrow', 'yesterday', 'this week', 'next week', 'the clinic', 'clinic', 'now',
      };
      if (!nonPatientTargets.contains(target) && !target.startsWith('this ') && !target.startsWith('next ') && !target.startsWith('the clinic')) {
        hasPatientPreposition = true;
      }
    }

    // Check for "does <name> have", "how much does <name> owe"
    bool hasDoesPatient = false;
    final doesMatch = RegExp(r"\bdoes\s+([a-zA-Z0-9\-_]+(?:\s+[a-zA-Z0-9\-_]+)?)\s+(?:have|need|owe)", caseSensitive: false).firstMatch(query);
    if (doesMatch != null) {
      final name = doesMatch.group(1)!.toLowerCase().trim();
      if (name != 'the clinic' && name != 'doctor' && name != 'anyone') {
        hasDoesPatient = true;
      }
    }

    // Check for "when is <name> scheduled/appointment"
    bool hasWhenIsPatient = false;
    final whenMatch = RegExp(r"\bwhen\s+is\s+([a-zA-Z0-9\-_]+(?:\s+[a-zA-Z0-9\-_]+)?)\s+(?:next\s+)?(?:appointment|visit|scheduled)", caseSensitive: false).firstMatch(query);
    if (whenMatch != null) {
      final name = whenMatch.group(1)!.toLowerCase().trim();
      if (!['today', 'tomorrow', 'the next'].contains(name)) {
        hasWhenIsPatient = true;
      }
    }

    // Invoice details by number or ID (evaluated before patient summary to avoid false intercept of "details for invoice...")
    final hasInvoiceId = RegExp(r'\binv-[\w-]+\b', caseSensitive: false).hasMatch(query) ||
        RegExp(r'\bbill-[\w-]+\b', caseSensitive: false).hasMatch(query);
    if (hasInvoiceId ||
        q.contains('invoice details') ||
        q.contains('details of invoice') ||
        q.contains('details for invoice') ||
        q.startsWith('invoice ') ||
        q.startsWith('show invoice ')) {
      return AssistantIntent.invoiceDetails;
    }

    // Dental Educational Knowledge Base & Medical Guard (evaluated early to prevent false clinic intercepts)
    if (LocalDentalKnowledge.isDiagnosisAttempt(query)) {
      return AssistantIntent.dentalKnowledge;
    }

    final isSpecificClinicDataQuery = q.contains('appointment') ||
        q.contains('booking') ||
        (q.contains('schedule') && !q.contains('cleaning') && !q.contains('brushing')) ||
        q.contains('visit') ||
        (q.contains('available') && (q.contains('doctor') || q.contains('dentist') || q.contains('who'))) ||
        q.contains('who is free') ||
        q.contains('on duty') ||
        q.contains('roster') ||
        q.contains('invoice') ||
        q.contains('bill') ||
        q.contains('payment') ||
        q.contains('balance') ||
        q.contains('owe') ||
        q.contains('revenue') ||
        q.contains('collected') ||
        q.contains('clinic summary') ||
        q.contains('remind') ||
        hasPatientId ||
        hasPhone ||
        hasPatientPossessive ||
        hasPatientPreposition;

    if (!isSpecificClinicDataQuery) {
      if (LocalDentalKnowledge.detectTopic(query) != null) {
        return AssistantIntent.dentalKnowledge;
      }
      final isGeneralDentalQuestion = (q.startsWith('what is ') ||
              q.startsWith('what are ') ||
              q.startsWith('explain ') ||
              q.startsWith('tell me about ') ||
              q.startsWith('how does ') ||
              q.startsWith('why do ') ||
              q.startsWith('why does ') ||
              q.contains('dental') ||
              q.contains('dentistry')) &&
          (q.contains('dental') ||
              q.contains('teeth') ||
              q.contains('tooth') ||
              q.contains('oral') ||
              q.contains('mouth') ||
              q.contains('implant') ||
              q.contains('braces') ||
              q.contains('orthodont') ||
              q.contains('wisdom'));

      final isCreativeOrNonDental = q.contains('poem') ||
          q.contains('joke') ||
          q.contains('story') ||
          q.contains('song') ||
          q.contains('capital of');

      if (isGeneralDentalQuestion && !isCreativeOrNonDental) {
        return AssistantIntent.dentalKnowledge;
      }
    }

    // Patient Tooth Records & Dental Chart History
    if ((q.contains('tooth record') ||
            q.contains('teeth record') ||
            q.contains('tooth chart') ||
            q.contains('teeth chart') ||
            q.contains('dental chart') ||
            (q.contains('record') && (q.contains('tooth') || q.contains('teeth'))) ||
            (q.contains('chart') && (q.contains('tooth') || q.contains('teeth') || q.contains('dental')))) &&
        LocalDentalKnowledge.detectTopic(query) == null) {
      return AssistantIntent.patientToothRecords;
    }

    // 1. Patient Summary / Profile
    if (!q.contains('invoice') && !q.contains('revenue') && !q.contains('billing') && !q.contains('collection') && LocalDentalKnowledge.detectTopic(query) == null) {
      if (q.contains('tell me about') ||
          q.contains('patient summary') ||
          q.contains('patient profile') ||
          q.contains('patient details') ||
          (q.contains('summary of') && !q.contains('clinic') && !q.contains('daily') && !q.contains('operations') && !q.contains('practice')) ||
          (q.contains('summary for') && !q.contains('clinic') && !q.contains('today') && !q.contains('tomorrow') && !q.contains('yesterday')) ||
          (q.contains('profile of') || q.contains('profile for')) ||
          (q.contains('details of') || q.contains('details for')) ||
          (q.contains('who is') && !q.contains('who is available') && !q.contains('who is free') && !q.contains('who is coming') && !q.contains('who is on duty')) ||
          (q.endsWith('profile') && !q.contains('clinic')) ||
          (q.endsWith('summary') && !q.contains('clinic') && !q.contains('daily') && !q.contains('operations') && !q.contains('practice'))) {
        if (!q.contains('clinic summary') && !q.contains('daily summary')) {
          return AssistantIntent.patientSummary;
        }
      }
    }

    // 2. Patient-Specific Follow-Up
    if (q.contains('follow up') || q.contains('followup') || q.contains('call reminder') || q.contains('reminders')) {
      final isGenericFollowUp = q == 'follow up' ||
          q == 'follow ups' ||
          q == 'pending reminders' ||
          q == 'pending follow ups' ||
          q == 'show pending follow ups' ||
          q == 'show today follow up reminders' ||
          q == 'which follow ups are pending' ||
          q == 'which patients need follow up' ||
          q == 'who should we call' ||
          q == 'who do we call' ||
          q == 'whom should we call';

      if (!isGenericFollowUp && (hasPatientId || hasPhone || hasPatientPossessive || hasPatientPreposition || hasDoesPatient || q.contains('does the patient have a follow up') || q.contains('reminders for'))) {
        return AssistantIntent.patientFollowUp;
      }
    }

    // 3. Patient-Specific Balance & Invoices
    if (q.contains('balance') || q.contains('owe') || q.contains('owes') || q.contains('unpaid invoice') || q.contains('unpaid bill') || q.contains('billing for') || q.contains('invoices for')) {
      final isGenericBalance = q == 'outstanding balance' ||
          q == 'who owes' ||
          q == 'how much money is pending' ||
          q == 'how much is pending' ||
          q == 'money is pending' ||
          q == 'which patients still have a balance' ||
          q == 'show unpaid invoices' ||
          q == 'show pending invoices' ||
          q == 'unpaid bills' ||
          q == 'pending bills';

      if (!isGenericBalance && (hasPatientId || hasPhone || hasPatientPossessive || hasPatientPreposition || hasDoesPatient || q.contains('patient balance') || q.contains('patient unpaid') || q.contains('unpaid invoices') || q.contains('does') || q.contains('how much does'))) {
        return AssistantIntent.patientBalance;
      }
    }

    // 4. Patient-Specific Appointments
    if (q.contains('appointment') || q.contains('appointments') || q.contains('booking') || q.contains('bookings') || q.contains('visit') || q.contains('schedule')) {
      final hasSpecificPatientAppointmentCue = hasPatientId ||
          hasPhone ||
          hasPatientPossessive ||
          hasPatientPreposition ||
          hasDoesPatient ||
          hasWhenIsPatient ||
          q.contains('show patient appointments') ||
          q.contains('the patient next appointment') ||
          q.contains('patient next appointment') ||
          q.contains('appointment history for') ||
          q.contains('past appointments for') ||
          (q.contains('appointment history') && !q.contains('clinic'));

      if (hasSpecificPatientAppointmentCue) {
        return AssistantIntent.patientAppointments;
      }
    }

    // Payment history and ledger
    if (q.contains('payment history') ||
        q.contains('payment records') ||
        q.contains('payment record') ||
        q.contains('payment ledger') ||
        q.contains('payments for') ||
        q.contains('payments of') ||
        q.contains('payments from') ||
        q.contains('payments by') ||
        q.contains('past payments') ||
        q.contains('payment transactions') ||
        q.contains('payments made by')) {
      return AssistantIntent.paymentHistory;
    }

    // Collection rate
    if (q.contains('collection rate') ||
        q.contains('collection percentage') ||
        q.contains('collection ratio') ||
        q.contains('collections rate')) {
      return AssistantIntent.collectionRate;
    }

    // Period billing (yesterday, this week)
    if (q.contains('yesterday') || q.contains('this week') || q.contains('last week')) {
      if (q.contains('revenue') ||
          q.contains('billed') ||
          q.contains('billing') ||
          q.contains('collect') ||
          q.contains('collected') ||
          q.contains('collections') ||
          q.contains('income') ||
          q.contains('earnings') ||
          q.contains('financial') ||
          q.contains('ledger')) {
        return AssistantIntent.periodBilling;
      }
    }

    // 5. Revenue & Collections
    if (q.contains('revenue') ||
        q.contains('collect today') ||
        q.contains('collected today') ||
        q.contains('today collection') ||
        q.contains('today collections') ||
        q.contains('collections today') ||
        q.contains('billed today') ||
        q.contains('billing today') ||
        q.contains('today billing') ||
        q.contains('billing total') ||
        q.contains('collections total') ||
        q.contains('today collected') ||
        q.contains('today financial') ||
        q.contains('earnings') ||
        q.contains('income today') ||
        q.contains('money made today') ||
        q.contains('money did we make today') ||
        q.contains('did we collect today') ||
        q.contains('what did we collect') ||
        q.contains('how much did we collect') ||
        q.contains('how much was billed') ||
        q.contains('daily revenue')) {
      return AssistantIntent.todayRevenue;
    }

    // 6. Pending Invoices vs Pending Payments
    if (q.contains('pending invoice') ||
        q.contains('unpaid invoice') ||
        q.contains('pending bill') ||
        q.contains('unpaid bill') ||
        q.contains('due bill') ||
        q.contains('invoices pending') ||
        q.contains('invoices are pending') ||
        q.contains('bills pending')) {
      return AssistantIntent.pendingInvoices;
    }

    if (q.contains('pending payment') ||
        q.contains('payments pending') ||
        q.contains('payments are pending') ||
        q.contains('what payments are pending') ||
        q.contains('who has pending payment') ||
        q.contains('outstanding balance') ||
        q.contains('unpaid payment') ||
        q.contains('payment due') ||
        q.contains('due payment') ||
        q.contains('pending balance') ||
        q.contains('still have a balance') ||
        q.contains('have a balance') ||
        q.contains('has a balance') ||
        q.contains('patient balance') ||
        q.contains('how much money is pending') ||
        q.contains('how much is pending') ||
        q.contains('money is pending') ||
        q.contains('who owes')) {
      return AssistantIntent.pendingPayments;
    }

    // 7. Clinic Summary & Operations Overview
    if (q.contains('clinic summary') ||
        q.contains('summary of clinic') ||
        q.contains('clinic overview') ||
        q.contains('daily summary') ||
        q.contains('operations summary') ||
        q.contains('how is the clinic doing') ||
        q.contains('what is happening in the clinic') ||
        q.contains('clinic stats') ||
        q.contains('clinic status') ||
        q.contains('today clinic status') ||
        q.contains('today overview') ||
        q.contains('overview today') ||
        q.contains('practice summary')) {
      return AssistantIntent.clinicSummary;
    }

    // 8. Follow-ups & Reminders (clinic-wide)
    if (q.contains('follow up') ||
        q.contains('followup') ||
        q.contains('need follow up') ||
        q.contains('needs follow up') ||
        q.contains('who should we call') ||
        q.contains('who do we call') ||
        q.contains('whom should we call') ||
        q.contains('call reminder') ||
        q.contains('reminders') ||
        q.contains('pending reminders') ||
        q.contains('unconfirmed visit') ||
        q.contains('patient call')) {
      return AssistantIntent.followUps;
    }

    // 9. Doctor availability & roster
    if (q.contains('doctor') ||
        q.contains('dentist') ||
        q.contains('who is available') ||
        q.contains('who is free') ||
        q.contains('on duty')) {
      if (q.contains('available') ||
          q.contains('availability') ||
          q.contains('roster') ||
          q.contains('list') ||
          q.contains('free') ||
          q.contains('schedule') ||
          q.contains('on duty') ||
          q.contains('who is available') ||
          q.contains('are any doctors available') ||
          q.contains('is any doctor available')) {
        return AssistantIntent.doctorAvailability;
      }
    }

    // 10. Patient search (natural queries like "find patient John", "search for John", "do we have a patient named John")
    if (q.contains('patient') ||
        q.startsWith('find ') ||
        q.startsWith('search ') ||
        q.startsWith('lookup ') ||
        q.startsWith('show patient')) {
      if (q.contains('do we have a patient') ||
          q.contains('is there a patient') ||
          q.contains('search for') ||
          q.contains('search patient') ||
          q.contains('find patient') ||
          q.contains('lookup patient') ||
          q.contains('show patient') ||
          q.contains('patient named') ||
          q.contains('patient by phone') ||
          q.contains('patient id') ||
          q.contains('patient search') ||
          q.contains('patient directory')) {
        return AssistantIntent.patientSearch;
      }
      if ((q.startsWith('find ') || q.startsWith('search ') || q.startsWith('lookup ')) &&
          !q.contains('appointment') &&
          !q.contains('doctor') &&
          !q.contains('revenue') &&
          !q.contains('invoice') &&
          !q.contains('summary')) {
        return AssistantIntent.patientSearch;
      }
    }

    // 11. Tomorrow's appointments (evaluated before general appointment count)
    if (q.contains('tomorrow') &&
        (q.contains('appointment') ||
         q.contains('booking') ||
         q.contains('schedule') ||
         q.contains('visit') ||
         q.contains('who is coming') ||
         q.contains('who comes'))) {
      return AssistantIntent.tomorrowAppointments;
    }

    // 12. Yesterday's appointments
    if (q.contains('yesterday') &&
        (q.contains('appointment') ||
         q.contains('booking') ||
         q.contains('schedule') ||
         q.contains('visit') ||
         q.contains('who came') ||
         q.contains('who visited'))) {
      return AssistantIntent.yesterdayAppointments;
    }

    // 13. This week's appointments
    if (q.contains('this week') &&
        (q.contains('appointment') ||
         q.contains('booking') ||
         q.contains('schedule') ||
         q.contains('visit'))) {
      return AssistantIntent.thisWeekAppointments;
    }

    // 14. Appointment count
    if (q.contains('how many appointment') ||
        q.contains('how many appointments') ||
        q.contains('appointment count') ||
        q.contains('appointments count') ||
        q.contains('number of appointment') ||
        q.contains('total appointments') ||
        q.contains('count of appointment')) {
      return AssistantIntent.appointmentCount;
    }

    // 15. Today's appointments (wide natural phrasing)
    if ((q.contains('today') &&
         (q.contains('appointment') ||
          q.contains('booking') ||
          q.contains('schedule') ||
          q.contains('visit') ||
          q.contains('who is coming') ||
          q.contains('who comes'))) ||
        q == 'appointments' ||
        q == 'show appointments' ||
        q == 'today appointments' ||
        q.contains('appointments today') ||
        q.contains('today bookings') ||
        q.contains('do we have appointments today') ||
        q.contains('what appointments do we have today') ||
        q.contains('what is the appointment schedule for today')) {
      return AssistantIntent.todayAppointments;
    }

    return AssistantIntent.unsupported;
  }

  /// Extracts the target search string for patient queries handling natural sentence prefixes.
  static String extractPatientSearchTerm(String query) {
    var text = query.trim();
    final lower = text.toLowerCase();

    // Natural sentence prefixes in order from longest to shortest
    final prefixes = [
      'do we have a patient by phone number',
      'find patient by phone number',
      'search patient by phone number',
      'search for patient by phone number',
      'do we have a patient named',
      'do we have a patient name',
      'is there a patient named',
      'is there a patient name',
      'find patient named',
      'find patient name',
      'search patient named',
      'search patient name',
      'search for patient named',
      'search for patient name',
      'search for patient',
      'search patient id',
      'find patient id',
      'lookup patient id',
      'do we have a patient',
      'is there a patient',
      'search for',
      'show patient',
      'find patient',
      'search patient',
      'lookup patient',
      'patient search',
      'find',
      'search',
      'lookup',
      'show',
    ];

    for (final p in prefixes) {
      if (lower.startsWith(p)) {
        text = text.substring(p.length).trim();
        break;
      }
    }

    // Strip common punctuation (e.g. trailing question mark)
    return text.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '').trim();
  }

  /// Safely resolves a query term against ClinicState patients with disambiguation support.
  static PatientLookupResult resolvePatient(String rawTerm, ClinicState clinicState) {
    final term = rawTerm.trim().replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
    if (term.isEmpty) {
      return PatientLookupResult(matches: const [], searchTerm: rawTerm);
    }

    final lowerTerm = term.toLowerCase();

    // 1. Exact ID match (case-insensitive) takes highest priority
    final exactIdMatches = clinicState.patients.where((p) => p.id.toLowerCase() == lowerTerm).toList();
    if (exactIdMatches.isNotEmpty) {
      return PatientLookupResult(matches: exactIdMatches, searchTerm: term);
    }

    // 2. Exact Phone match
    final digitsOnly = term.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 7) {
      final phoneMatches = clinicState.patients.where((p) {
        final pDigits = p.phone.replaceAll(RegExp(r'\D'), '');
        return pDigits == digitsOnly || p.phone == term;
      }).toList();
      if (phoneMatches.isNotEmpty) {
        return PatientLookupResult(matches: phoneMatches, searchTerm: term);
      }
    }

    // 3. Exact full name match
    final exactNameMatches = clinicState.patients.where((p) => p.name.toLowerCase() == lowerTerm).toList();
    if (exactNameMatches.length == 1) {
      return PatientLookupResult(matches: exactNameMatches, searchTerm: term);
    }

    // 4. Substring / partial name / ID / phone match
    final partialMatches = clinicState.patients.where((p) {
      final pNameLower = p.name.toLowerCase();
      final pIdLower = p.id.toLowerCase();
      final parts = pNameLower.split(RegExp(r'\s+'));
      return pNameLower.contains(lowerTerm) ||
          lowerTerm.contains(pNameLower) ||
          parts.any((part) => part == lowerTerm) ||
          pIdLower.contains(lowerTerm);
    }).toList();

    return PatientLookupResult(matches: partialMatches, searchTerm: term);
  }

  /// Extracts the target patient search identifier from natural language.
  static String extractPatientQueryTerm(String query) {
    final trimmed = query.trim();

    // 1. Check for Patient ID (e.g. P-1001, PT-01)
    final idMatch = RegExp(r'\b(?:P|PT)-\d+\b', caseSensitive: false).firstMatch(trimmed);
    if (idMatch != null) {
      return idMatch.group(0)!;
    }

    // 2. Check for 10-digit phone
    final phoneMatch = RegExp(r'\b\d{10}\b').firstMatch(trimmed);
    if (phoneMatch != null) {
      return phoneMatch.group(0)!;
    }

    // 3. Possessive match (e.g. "Rahul's balance", "Rahul Sharma's appointments")
    final possessiveMatch = RegExp(r"([A-Za-z0-9\-_]+(?:\s+[A-Za-z0-9\-_]+)?)\s*'(?:s)?\b", caseSensitive: false).firstMatch(trimmed);
    if (possessiveMatch != null) {
      final candidate = possessiveMatch.group(1)!.trim();
      final lowerCandidate = candidate.toLowerCase();
      const reserved = {
        'today', 'tomorrow', 'yesterday', 'who', 'what', 'how', 'there',
        'clinic', 'doctor', 'dentist', 'here',
      };
      if (lowerCandidate == 'patient' || lowerCandidate == 'the patient') {
        return ''; // Ambiguous
      }
      if (!reserved.contains(lowerCandidate)) {
        return _cleanExtractedName(candidate);
      }
    }

    // 4. "patient summary for X", "summary of X", "summary for X", "profile of X", "details for X"
    final summaryMatch = RegExp(
      r'(?:patient\s+summary\s+for|summary\s+of|summary\s+for|profile\s+of|profile\s+for|details\s+of|details\s+for|information\s+about|info\s+about)\s+(?:patient\s+)?([A-Za-z0-9\-_]+(?:\s+[A-Za-z0-9\-_]+)?)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (summaryMatch != null) {
      return _cleanExtractedName(summaryMatch.group(1)!);
    }

    // 5. "tell me about X", "who is X"
    final tellMeMatch = RegExp(
      r'(?:tell\s+me\s+about|who\s+is)\s+(?:patient\s+)?([A-Za-z0-9\-_]+(?:\s+[A-Za-z0-9\-_]+)?)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (tellMeMatch != null) {
      return _cleanExtractedName(tellMeMatch.group(1)!);
    }

    // 6. "does X have", "how much does X owe", "what does X owe"
    final doesHaveMatch = RegExp(
      r'(?:does|how\s+much\s+does|what\s+does)\s+(?:patient\s+)?([A-Za-z0-9\-_]+(?:\s+[A-Za-z0-9\-_]+)?)\s+(?:have|need|owe)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (doesHaveMatch != null) {
      return _cleanExtractedName(doesHaveMatch.group(1)!);
    }

    // 7. Prepositional: "appointments for X", "balance of X", "payments for X", "follow-up for X", "tooth records for X"
    final prepMatch = RegExp(
      r'(?:appointments?\s+(?:for|of)|balance\s+(?:for|of)|payments?\s+(?:for|of|by|from)|follow\-?ups?\s+(?:for|with)|reminders?\s+(?:for|of)|history\s+(?:for|of)|tooth\s+records?\s+(?:for|of)|teeth\s+records?\s+(?:for|of)|tooth\s+charts?\s+(?:for|of)|dental\s+charts?\s+(?:for|of))\s+(?:patient\s+)?([A-Za-z0-9\-_]+(?:\s+[A-Za-z0-9\-_]+)?)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (prepMatch != null) {
      return _cleanExtractedName(prepMatch.group(1)!);
    }

    // 8. "patient <Name> <keyword>"
    final patientPrefixMatch = RegExp(
      r'\bpatient\s+([A-Za-z0-9\-_]+(?:\s+[A-Za-z0-9\-_]+)?)\s+(?:balance|appointments?|follow\-?up|summary|profile|invoices?|billing|payments?|tooth\s+records?|tooth\s+chart|dental\s+chart)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (patientPrefixMatch != null) {
      return _cleanExtractedName(patientPrefixMatch.group(1)!);
    }

    // 9. Simple "<Name> balance", "<Name> appointments", "<Name> tooth records"
    final simpleMatch = RegExp(
      r'^([A-Za-z0-9\-_]+(?:\s+[A-Za-z0-9\-_]+)?)\s+(?:balance|appointments?|follow\-?up|summary|profile|invoices?|unpaid\s+invoices?|billing|payments?|payment\s+history|appointment\s+history|history|tooth\s+records?|teeth\s+records?|tooth\s+chart|dental\s+chart)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (simpleMatch != null) {
      return _cleanExtractedName(simpleMatch.group(1)!);
    }

    // 10. Fallback
    final searchFallback = extractPatientSearchTerm(trimmed);
    return _cleanExtractedName(searchFallback);
  }

  /// Extracts the target invoice number or ID from a query string.
  static String extractInvoiceNumberOrId(String query) {
    final invMatch = RegExp(r'\b(?:inv|bill)[\w-]*-\d+\b', caseSensitive: false).firstMatch(query) ??
        RegExp(r'\binv-[\w-]+\b', caseSensitive: false).firstMatch(query);
    if (invMatch != null) {
      return invMatch.group(0)!;
    }
    final numMatch = RegExp(r'\binvoice\s+([A-Za-z0-9\-_]+)\b', caseSensitive: false).firstMatch(query);
    if (numMatch != null) {
      return numMatch.group(1)!;
    }
    return '';
  }

  static String _cleanExtractedName(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
    final prefixesToStrip = [
      'what is the ', 'what is ', 'what was ', 'when is ', 'how is ', 'where is ',
      'who is ', 'tell me about ', 'show me ', 'show ', 'the ', 'a ', 'an ',
      'is ', 'was ', 'does ',
    ];
    bool strippedAny = true;
    while (strippedAny) {
      strippedAny = false;
      for (final p in prefixesToStrip) {
        if (s.toLowerCase().startsWith(p)) {
          s = s.substring(p.length).trim();
          strippedAny = true;
        }
      }
    }
    s = s.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '').trim();
    final lower = s.toLowerCase();
    if (lower == 'patient' ||
        lower == 'the patient' ||
        lower == 'a patient' ||
        lower == 'patient appointments' ||
        lower == 'patient appointment' ||
        lower == 'patient balance' ||
        lower == 'patient follow up' ||
        lower == 'appointments' ||
        lower == 'appointment' ||
        lower == 'balance' ||
        lower == 'follow up' ||
        lower == 'followup' ||
        lower == 'payments' ||
        lower == 'payment' ||
        lower == 'payment history' ||
        lower == 'tooth records' ||
        lower == 'tooth record' ||
        lower == 'teeth records' ||
        lower == 'tooth chart' ||
        lower == 'dental chart' ||
        lower.isEmpty) {
      return '';
    }
    return s;
  }

  /// Returns the specific domain error message if the data required for this intent is unavailable.
  static String? getDomainErrorForIntent(AssistantIntent intent, ClinicState clinicState) {
    switch (intent) {
      case AssistantIntent.dentalKnowledge:
        return null;

      case AssistantIntent.todayAppointments:
      case AssistantIntent.tomorrowAppointments:
      case AssistantIntent.yesterdayAppointments:
      case AssistantIntent.thisWeekAppointments:
      case AssistantIntent.appointmentCount:
        return clinicState.appointmentsError;

      case AssistantIntent.patientAppointments:
        return clinicState.patientsError ?? clinicState.appointmentsError;

      case AssistantIntent.patientSearch:
        return clinicState.patientsError;

      case AssistantIntent.doctorAvailability:
        return clinicState.doctorsError ?? clinicState.appointmentsError;

      case AssistantIntent.pendingInvoices:
      case AssistantIntent.invoiceDetails:
        return clinicState.billingError;

      case AssistantIntent.pendingPayments:
      case AssistantIntent.todayRevenue:
      case AssistantIntent.collectionRate:
      case AssistantIntent.periodBilling:
      case AssistantIntent.paymentHistory:
        return clinicState.paymentsError;

      case AssistantIntent.patientBalance:
        return clinicState.patientsError ?? clinicState.billingError;

      case AssistantIntent.patientFollowUp:
      case AssistantIntent.followUps:
        return clinicState.remindersError ?? clinicState.patientsError;

      case AssistantIntent.clinicSummary:
        return clinicState.appointmentsError ??
            clinicState.patientsError ??
            clinicState.billingError;

      case AssistantIntent.patientSummary:
        return clinicState.patientsError;

      case AssistantIntent.patientToothRecords:
        return clinicState.toothRecordsError;

      case AssistantIntent.unsupported:
        return null;
    }
  }

  /// Processes user message deterministically against real clinic state.
  static Future<AssistantResponse> processQuery(
    String query, {
    required ClinicState clinicState,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const AssistantResponse(
        text: 'Please enter a query or question regarding clinic operations.',
        intent: AssistantIntent.unsupported,
        success: false,
      );
    }

    final intent = parseIntent(trimmed);

    // Dental educational knowledge queries operate completely offline and do not require Supabase database
    if (intent == AssistantIntent.dentalKnowledge) {
      return await _handleDentalKnowledge(trimmed, clinicState);
    }

    // Domain-aware data availability validation
    final domainError = getDomainErrorForIntent(intent, clinicState);
    if (domainError != null && domainError.isNotEmpty) {
      if (intent == AssistantIntent.patientToothRecords) {
        return AssistantResponse(
          text: "I can't retrieve tooth records right now because the Tooth Records database is unavailable.",
          intent: intent,
          success: false,
          errorMessage: domainError,
        );
      }
      return AssistantResponse(
        text: 'Database error: $domainError. Cannot retrieve live clinic data.',
        intent: intent,
        success: false,
        errorMessage: domainError,
      );
    }

    try {
      switch (intent) {
        case AssistantIntent.todayAppointments:
          return await _handleTodayAppointments(clinicState);

        case AssistantIntent.tomorrowAppointments:
          return await _handleTomorrowAppointments(clinicState);

        case AssistantIntent.yesterdayAppointments:
          return await _handleYesterdayAppointments(clinicState);

        case AssistantIntent.thisWeekAppointments:
          return await _handleThisWeekAppointments(clinicState);

        case AssistantIntent.appointmentCount:
          return await _handleAppointmentCount(clinicState);

        case AssistantIntent.patientSearch:
          final term = extractPatientSearchTerm(trimmed);
          return await _handlePatientSearch(term, clinicState);

        case AssistantIntent.doctorAvailability:
          return await _handleDoctorAvailability(clinicState);

        case AssistantIntent.pendingInvoices:
          return await _handlePendingInvoices(clinicState);

        case AssistantIntent.pendingPayments:
          return await _handlePendingPayments(clinicState);

        case AssistantIntent.todayRevenue:
          return await _handleTodayRevenue(clinicState, trimmed);

        case AssistantIntent.invoiceDetails:
          return await _handleInvoiceDetails(trimmed, clinicState);

        case AssistantIntent.collectionRate:
          return await _handleCollectionRate(trimmed, clinicState);

        case AssistantIntent.periodBilling:
          return await _handlePeriodBilling(trimmed, clinicState);

        case AssistantIntent.paymentHistory:
          return await _handlePaymentHistory(trimmed, clinicState);

        case AssistantIntent.clinicSummary:
          return await _handleClinicSummary(clinicState);

        case AssistantIntent.followUps:
          return await _handleFollowUps(clinicState);

        case AssistantIntent.patientAppointments:
          return await _handlePatientAppointments(trimmed, clinicState);

        case AssistantIntent.patientBalance:
          return await _handlePatientBalance(trimmed, clinicState);

        case AssistantIntent.patientFollowUp:
          return await _handlePatientFollowUp(trimmed, clinicState);

        case AssistantIntent.patientSummary:
          return await _handlePatientSummary(trimmed, clinicState);

        case AssistantIntent.patientToothRecords:
          return await _handlePatientToothRecords(trimmed, clinicState);

        case AssistantIntent.dentalKnowledge:
          return await _handleDentalKnowledge(trimmed, clinicState);

        case AssistantIntent.unsupported:
          return const AssistantResponse(
            text: 'I can currently help with appointments (today, tomorrow, yesterday, this week), patients, doctors, billing, payments, follow-ups, tooth records, and clinic summaries. Please let me know what clinic information you need.',
            intent: AssistantIntent.unsupported,
            success: true,
          );
      }
    } catch (e, st) {
      debugPrint('[LocalAssistantEngine] Error processing query "$trimmed": $e\n$st');
      return AssistantResponse(
        text: 'An error occurred while retrieving clinic data: $e',
        intent: intent,
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // --- Handlers for each intent ---

  static Future<AssistantResponse> _handleTodayAppointments(ClinicState clinicState) async {
    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getTodaysAppointments',
      arguments: {},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error retrieving today\'s appointments: ${data['error']}',
        intent: AssistantIntent.todayAppointments,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final total = data['totalAppointmentsToday'] as int? ?? 0;
    final appointments = (data['appointments'] as List<dynamic>?) ?? [];

    if (total == 0 || appointments.isEmpty) {
      return AssistantResponse(
        text: 'There are no appointments scheduled for today.',
        intent: AssistantIntent.todayAppointments,
        data: data,
      );
    }

    final buffer = StringBuffer('There are $total appointment(s) scheduled for today:\n');
    for (int i = 0; i < appointments.length; i++) {
      final a = appointments[i] as Map<String, dynamic>;
      final treatment = a['treatment'] != null && a['treatment'].toString().isNotEmpty
          ? ' (${a['treatment']})'
          : '';
      buffer.writeln('${i + 1}. ${a['time']} - ${a['patientName']} with ${a['doctorName']}$treatment [Status: ${a['status']}]');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.todayAppointments,
      data: data,
    );
  }

  static Future<AssistantResponse> _handleTomorrowAppointments(ClinicState clinicState) async {
    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getTomorrowAppointments',
      arguments: {},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error retrieving tomorrow\'s appointments: ${data['error']}',
        intent: AssistantIntent.tomorrowAppointments,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final total = data['totalAppointmentsTomorrow'] as int? ?? 0;
    final appointments = (data['appointments'] as List<dynamic>?) ?? [];

    if (total == 0 || appointments.isEmpty) {
      return AssistantResponse(
        text: 'There are no appointments scheduled for tomorrow.',
        intent: AssistantIntent.tomorrowAppointments,
        data: data,
      );
    }

    final buffer = StringBuffer('There are $total appointment(s) scheduled for tomorrow:\n');
    for (int i = 0; i < appointments.length; i++) {
      final a = appointments[i] as Map<String, dynamic>;
      final treatment = a['treatment'] != null && a['treatment'].toString().isNotEmpty
          ? ' (${a['treatment']})'
          : '';
      buffer.writeln('${i + 1}. ${a['time']} - ${a['patientName']} with ${a['doctorName']}$treatment [Status: ${a['status']}]');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.tomorrowAppointments,
      data: data,
    );
  }

  static Future<AssistantResponse> _handleYesterdayAppointments(ClinicState clinicState) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final appointments = clinicState.getAppointmentsForDate(yesterday);
    final dateStr = DateFormat('dd MMM yyyy').format(yesterday);

    if (appointments.isEmpty) {
      return AssistantResponse(
        text: 'There were no appointments scheduled for yesterday ($dateStr).',
        intent: AssistantIntent.yesterdayAppointments,
        data: {'date': dateStr, 'count': 0},
      );
    }

    final buffer = StringBuffer('Yesterday ($dateStr) had ${appointments.length} appointment(s):\n');
    for (int i = 0; i < appointments.length; i++) {
      final a = appointments[i];
      buffer.writeln('${i + 1}. ${a.timeString} - ${a.patientName} with ${a.doctorName} [Status: ${a.status.label}]');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.yesterdayAppointments,
      data: {'date': dateStr, 'count': appointments.length},
    );
  }

  static Future<AssistantResponse> _handleThisWeekAppointments(ClinicState clinicState) async {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final thisWeekList = clinicState.appointments.where((a) {
      return a.dateTime.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          a.dateTime.isBefore(endOfWeek);
    }).toList();

    if (thisWeekList.isEmpty) {
      return const AssistantResponse(
        text: 'There are no appointments scheduled for this week.',
        intent: AssistantIntent.thisWeekAppointments,
        data: {'count': 0},
      );
    }

    final startStr = DateFormat('dd MMM').format(startOfWeek);
    final endStr = DateFormat('dd MMM yyyy').format(endOfWeek.subtract(const Duration(days: 1)));

    final text = 'This week ($startStr - $endStr) has ${thisWeekList.length} appointment(s) scheduled across all doctors.';
    return AssistantResponse(
      text: text,
      intent: AssistantIntent.thisWeekAppointments,
      data: {'count': thisWeekList.length},
    );
  }

  static Future<AssistantResponse> _handleAppointmentCount(ClinicState clinicState) async {
    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getTodaysAppointments',
      arguments: {},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error counting appointments: ${data['error']}',
        intent: AssistantIntent.appointmentCount,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final total = data['totalAppointmentsToday'] as int? ?? 0;
    final appointments = (data['appointments'] as List<dynamic>?) ?? [];

    int completed = 0;
    int inProgress = 0;
    int waiting = 0;
    int scheduled = 0;

    for (final a in appointments) {
      final status = (a['status'] ?? '').toString().toLowerCase();
      if (status.contains('completed')) {
        completed++;
      } else if (status.contains('progress') || status.contains('consultation')) {
        inProgress++;
      } else if (status.contains('waiting') || status.contains('arrived') || status.contains('checked in')) {
        waiting++;
      } else {
        scheduled++;
      }
    }

    if (total == 0) {
      return AssistantResponse(
        text: 'There are 0 appointments scheduled for today.',
        intent: AssistantIntent.appointmentCount,
        data: data,
      );
    }

    final text = 'There are $total appointment(s) scheduled for today:\n'
        '• Completed: $completed\n'
        '• In Consultation: $inProgress\n'
        '• Waiting Room: $waiting\n'
        '• Scheduled / Upcoming: $scheduled';

    return AssistantResponse(
      text: text,
      intent: AssistantIntent.appointmentCount,
      data: data,
    );
  }

  static Future<AssistantResponse> _handlePatientSearch(String term, ClinicState clinicState) async {
    if (term.isEmpty) {
      return const AssistantResponse(
        text: 'Please specify a patient name, phone number, or ID to search for.',
        intent: AssistantIntent.patientSearch,
        success: true,
      );
    }

    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'searchPatients',
      arguments: {'query': term},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error searching patients: ${data['error']}',
        intent: AssistantIntent.patientSearch,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final matchCount = data['matchCount'] as int? ?? 0;
    final patients = (data['patients'] as List<dynamic>?) ?? [];

    if (matchCount == 0 || patients.isEmpty) {
      return AssistantResponse(
        text: 'No patient matching "$term" was found.',
        intent: AssistantIntent.patientSearch,
        data: data,
      );
    }

    if (matchCount > 1) {
      final buffer = StringBuffer('I found $matchCount patients matching "$term":\n');
      for (int i = 0; i < patients.length; i++) {
        final p = patients[i] as Map<String, dynamic>;
        buffer.writeln('${i + 1}. ${p['name']} (ID: ${p['id']}, Phone: ${p['phone']})');
      }
      buffer.write('Please specify the patient ID or phone number.');
      return AssistantResponse(
        text: buffer.toString().trim(),
        intent: AssistantIntent.patientSearch,
        data: data,
      );
    }

    final p = patients.first as Map<String, dynamic>;
    final buffer = StringBuffer('Found 1 patient matching "$term":\n');
    buffer.writeln('1. ${p['name']} (ID: ${p['id']}) — Phone: ${p['phone']}, Age: ${p['age']}, Gender: ${p['gender']}');

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.patientSearch,
      data: data,
    );
  }

  static Future<AssistantResponse> _handleDoctorAvailability(ClinicState clinicState) async {
    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getDoctorAvailability',
      arguments: {},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error retrieving doctor availability: ${data['error']}',
        intent: AssistantIntent.doctorAvailability,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final doctors = (data['doctors'] as List<dynamic>?) ?? [];
    final totalAvailable = data['totalAvailable'] as int? ?? 0;

    if (doctors.isEmpty) {
      return AssistantResponse(
        text: 'No doctors are registered in the clinic roster.',
        intent: AssistantIntent.doctorAvailability,
        data: data,
      );
    }

    final buffer = StringBuffer('Doctor Availability ($totalAvailable of ${doctors.length} available now):\n');
    for (int i = 0; i < doctors.length; i++) {
      final d = doctors[i] as Map<String, dynamic>;
      final statusLabel = d['isAvailableNow'] == true ? 'Available Now' : d['status'];
      final count = d['appointmentsTodayCount'] ?? 0;
      buffer.writeln('${i + 1}. ${d['name']} (${d['specialization']}) — Status: $statusLabel, Appointments Today: $count');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.doctorAvailability,
      data: data,
    );
  }

  static Future<AssistantResponse> _handlePendingInvoices(ClinicState clinicState) async {
    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getPendingPayments',
      arguments: {},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error retrieving pending invoices: ${data['error']}',
        intent: AssistantIntent.pendingInvoices,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final totalCount = data['totalPendingCount'] as int? ?? 0;
    final totalAmount = (data['totalPendingAmount'] as num?)?.toDouble() ?? 0.0;
    final invoices = (data['invoices'] as List<dynamic>?) ?? [];

    if (totalCount == 0 || invoices.isEmpty) {
      return AssistantResponse(
        text: 'There are no pending or partially paid invoices. All accounts are settled.',
        intent: AssistantIntent.pendingInvoices,
        data: data,
      );
    }

    final buffer = StringBuffer('Found $totalCount pending invoice(s) with total balance due of ₹${totalAmount.toStringAsFixed(0)}:\n');
    for (int i = 0; i < invoices.length; i++) {
      final inv = invoices[i] as Map<String, dynamic>;
      buffer.writeln('${i + 1}. ${inv['invoiceNumber']} (${inv['patientName']}) — Balance: ₹${inv['balanceAmount']} [Total: ₹${inv['totalAmount']}, Paid: ₹${inv['paidAmount']}]');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.pendingInvoices,
      data: data,
    );
  }

  static Future<AssistantResponse> _handlePendingPayments(ClinicState clinicState) async {
    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getPendingPayments',
      arguments: {},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error retrieving pending payments: ${data['error']}',
        intent: AssistantIntent.pendingPayments,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final totalCount = data['totalPendingCount'] as int? ?? 0;
    final totalAmount = (data['totalPendingAmount'] as num?)?.toDouble() ?? 0.0;

    if (totalCount == 0) {
      return AssistantResponse(
        text: 'No pending payments were found. All patient invoices are fully settled.',
        intent: AssistantIntent.pendingPayments,
        data: data,
      );
    }

    final invoices = (data['invoices'] as List<dynamic>?) ?? [];
    final buffer = StringBuffer('Outstanding pending payments total ₹${totalAmount.toStringAsFixed(0)} across $totalCount invoice(s):\n');
    for (int i = 0; i < invoices.length; i++) {
      final inv = invoices[i] as Map<String, dynamic>;
      buffer.writeln('• ${inv['patientName']} (${inv['invoiceNumber']}): ₹${inv['balanceAmount']} remaining');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.pendingPayments,
      data: data,
    );
  }

  static Future<AssistantResponse> _handleTodayRevenue(
    ClinicState clinicState, [
    String? rawQuery,
  ]) async {
    final payError = clinicState.paymentsError;
    if (payError != null) {
      return AssistantResponse(
        text: 'Database error retrieving today\'s revenue: $payError',
        intent: AssistantIntent.todayRevenue,
        success: false,
        errorMessage: payError,
      );
    }

    final collected = clinicState.todayCollectedTotal;
    final billed = clinicState.todayBillingTotal;
    final pendingInvoices = clinicState.invoices
        .where((inv) => inv.status == PaymentStatus.pending || inv.status == PaymentStatus.partial)
        .toList();
    final outstanding = pendingInvoices.fold(0.0, (sum, inv) => sum + inv.balanceAmount);

    final q = rawQuery != null ? normalizeQuery(rawQuery) : '';
    final isSpecificBilling = (q.contains('billed') || q.contains('billing')) &&
        !q.contains('collect') &&
        !q.contains('revenue') &&
        !q.contains('summary');
    final isSpecificCollection = (q.contains('collect') || q.contains('collected') || q.contains('collection')) &&
        !q.contains('billed') &&
        !q.contains('billing') &&
        !q.contains('revenue') &&
        !q.contains('summary');

    final rateStr = billed > 0
        ? '${((collected / billed) * 100).toStringAsFixed(1)}%'
        : 'N/A (No billing)';

    String text;
    if (isSpecificBilling) {
      if (billed == 0.0 && clinicState.invoices.isEmpty) {
        text = 'No invoices were recorded today. Total billed today is ₹0.';
      } else {
        text = 'Today\'s total billing is ₹${billed.toStringAsFixed(0)} across clinic invoices.';
      }
    } else if (isSpecificCollection) {
      if (collected == 0.0 && clinicState.invoices.isEmpty) {
        text = 'No collections were recorded today. Total collected today is ₹0.';
      } else {
        text = 'Today\'s total collections are ₹${collected.toStringAsFixed(0)}.';
      }
    } else {
      if (billed == 0.0 && collected == 0.0 && clinicState.invoices.isEmpty) {
        text = 'No invoices or billing transactions were recorded today.\n'
            '• Total Billed Today: ₹${billed.toStringAsFixed(0)}\n'
            '• Total Collected Today: ₹${collected.toStringAsFixed(0)}\n'
            '• Outstanding Receivables: ₹${outstanding.toStringAsFixed(0)}';
      } else {
        text = 'Today\'s Revenue Summary:\n'
            '• Total Collected Today: ₹${collected.toStringAsFixed(0)}\n'
            '• Total Billed Today: ₹${billed.toStringAsFixed(0)}\n'
            '• Total Outstanding Receivables: ₹${outstanding.toStringAsFixed(0)} (${pendingInvoices.length} pending)\n'
            '• Collection Rate: $rateStr';
      }
    }

    return AssistantResponse(
      text: text,
      intent: AssistantIntent.todayRevenue,
      data: {
        'collected': collected,
        'billed': billed,
        'outstanding': outstanding,
        'pendingCount': pendingInvoices.length,
      },
    );
  }

  static Future<AssistantResponse> _handleInvoiceDetails(
    String rawQuery,
    ClinicState clinicState,
  ) async {
    final billError = clinicState.billingError;
    if (billError != null) {
      return AssistantResponse(
        text: 'Database error retrieving invoice details: $billError',
        intent: AssistantIntent.invoiceDetails,
        success: false,
        errorMessage: billError,
      );
    }

    final invId = extractInvoiceNumberOrId(rawQuery);
    if (invId.isEmpty) {
      return const AssistantResponse(
        text: 'Please specify the invoice number or ID (e.g. INV-2026-0042).',
        intent: AssistantIntent.invoiceDetails,
        success: true,
      );
    }

    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getInvoiceDetails',
      arguments: {'invoiceNumberOrId': invId},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error') || data['found'] != true) {
      return AssistantResponse(
        text: 'No invoice matching "$invId" was found in clinic records.',
        intent: AssistantIntent.invoiceDetails,
        success: true,
        data: data,
      );
    }

    final buffer = StringBuffer('Invoice ${data['invoiceNumber']} Details:\n');
    buffer.writeln('• Patient: ${data['patientName']} (ID: ${data['patientId']})');
    buffer.writeln('• Doctor: ${data['doctorName']}');
    buffer.writeln('• Date: ${data['date']}');
    buffer.writeln('• Status: ${data['status'].toString().toUpperCase()}');
    buffer.writeln('• Subtotal: ₹${(data['subtotal'] as num).toStringAsFixed(0)}');
    if ((data['discount'] as num) > 0) {
      buffer.writeln('• Discount: ₹${(data['discount'] as num).toStringAsFixed(0)}');
    }
    if ((data['tax'] as num) > 0) {
      buffer.writeln('• Tax: ₹${(data['tax'] as num).toStringAsFixed(0)}');
    }
    buffer.writeln('• Total Amount: ₹${(data['totalAmount'] as num).toStringAsFixed(0)}');
    buffer.writeln('• Paid Amount: ₹${(data['paidAmount'] as num).toStringAsFixed(0)}');
    buffer.writeln('• Balance Due: ₹${(data['balanceAmount'] as num).toStringAsFixed(0)}');
    buffer.writeln('• Payment Method: ${data['paymentMethod']}');
    if (data['receiptNumber'] != null && data['receiptNumber'].toString().isNotEmpty) {
      buffer.writeln('• Receipt: ${data['receiptNumber']}');
    }

    final items = (data['items'] as List<dynamic>?) ?? [];
    if (items.isEmpty) {
      buffer.write('• Line Items: No itemized items recorded.');
    } else {
      buffer.writeln('• Line Items:');
      for (int i = 0; i < items.length; i++) {
        final it = items[i] as Map<String, dynamic>;
        buffer.writeln('  ${i + 1}. ${it['description']} — Qty: ${it['quantity']} × ₹${(it['unitPrice'] as num).toStringAsFixed(0)} = ₹${(it['amount'] as num).toStringAsFixed(0)}');
      }
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.invoiceDetails,
      success: true,
      data: data,
    );
  }

  static Future<AssistantResponse> _handleCollectionRate(
    String rawQuery,
    ClinicState clinicState,
  ) async {
    final payError = clinicState.paymentsError;
    if (payError != null) {
      return AssistantResponse(
        text: 'Database error: $payError. Cannot retrieve live clinic data.',
        intent: AssistantIntent.collectionRate,
        success: false,
        errorMessage: payError,
      );
    }

    final q = normalizeQuery(rawQuery);
    String period = 'today';
    String periodLabel = 'today';

    if (q.contains('yesterday')) {
      period = 'yesterday';
      periodLabel = 'yesterday';
    } else if (q.contains('this week') || q.contains('week')) {
      period = 'this_week';
      periodLabel = 'this week';
    }

    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getBillingSummary',
      arguments: {'period': period},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error calculating collection rate: ${data['error']}',
        intent: AssistantIntent.collectionRate,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final billed = (data['totalBilled'] as num?)?.toDouble() ?? 0.0;
    final collected = (data['totalCollected'] as num?)?.toDouble() ?? 0.0;
    final rate = (data['collectionRate'] as num?)?.toDouble();

    if (billed == 0.0) {
      return AssistantResponse(
        text: 'The collection rate cannot be calculated because there is no billing recorded for $periodLabel.',
        intent: AssistantIntent.collectionRate,
        success: true,
        data: {'billed': 0.0, 'collected': collected, 'rate': null},
      );
    }

    final rateStr = rate != null ? rate.toStringAsFixed(1) : ((collected / billed) * 100).toStringAsFixed(1);
    final text = 'The collection rate for $periodLabel is $rateStr% (Collected: ₹${collected.toStringAsFixed(0)} out of Billed: ₹${billed.toStringAsFixed(0)}).';

    return AssistantResponse(
      text: text,
      intent: AssistantIntent.collectionRate,
      success: true,
      data: {'billed': billed, 'collected': collected, 'rate': rate ?? (collected / billed) * 100},
    );
  }

  static Future<AssistantResponse> _handlePeriodBilling(
    String rawQuery,
    ClinicState clinicState,
  ) async {
    final billError = clinicState.billingError;
    if (billError != null) {
      return AssistantResponse(
        text: 'Database error retrieving billing summary: $billError',
        intent: AssistantIntent.periodBilling,
        success: false,
        errorMessage: billError,
      );
    }

    final q = normalizeQuery(rawQuery);
    String period = 'today';
    String periodLabel = 'Today';

    if (q.contains('yesterday')) {
      period = 'yesterday';
      periodLabel = 'Yesterday';
    } else if (q.contains('this week') || q.contains('week')) {
      period = 'this_week';
      periodLabel = 'This Week';
    } else if (q.contains('month') || q.contains('last week') || q.contains('year')) {
      return const AssistantResponse(
        text: 'I can only provide deterministic billing and collection summaries for today, yesterday, and this week.',
        intent: AssistantIntent.periodBilling,
        success: true,
      );
    }

    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getBillingSummary',
      arguments: {'period': period},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error retrieving billing summary: ${data['error']}',
        intent: AssistantIntent.periodBilling,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final totalInvoices = data['totalInvoices'] as int? ?? 0;
    final totalBilled = (data['totalBilled'] as num?)?.toDouble() ?? 0.0;
    final totalCollected = (data['totalCollected'] as num?)?.toDouble() ?? 0.0;
    final outstanding = (data['outstandingBalance'] as num?)?.toDouble() ?? 0.0;
    final collectionRate = (data['collectionRate'] as num?)?.toDouble();

    if (totalInvoices == 0 && totalBilled == 0.0 && totalCollected == 0.0) {
      return AssistantResponse(
        text: 'No invoices or transactions were recorded for $periodLabel.',
        intent: AssistantIntent.periodBilling,
        success: true,
        data: data,
      );
    }

    final rateStr = collectionRate != null
        ? '${collectionRate.toStringAsFixed(1)}%'
        : 'N/A (No billing recorded)';

    final text = '$periodLabel\'s Billing & Collections Summary:\n'
        '• Total Invoices: $totalInvoices\n'
        '• Total Billed: ₹${totalBilled.toStringAsFixed(0)}\n'
        '• Total Collected: ₹${totalCollected.toStringAsFixed(0)}\n'
        '• Outstanding Receivables: ₹${outstanding.toStringAsFixed(0)}\n'
        '• Collection Rate: $rateStr';

    return AssistantResponse(
      text: text,
      intent: AssistantIntent.periodBilling,
      success: true,
      data: data,
    );
  }

  static Future<AssistantResponse> _handlePaymentHistory(
    String rawQuery,
    ClinicState clinicState,
  ) async {
    final payError = clinicState.paymentsError;
    if (payError != null) {
      return AssistantResponse(
        text: 'Database error: $payError. Cannot retrieve live clinic data.',
        intent: AssistantIntent.paymentHistory,
        success: false,
        errorMessage: payError,
      );
    }

    final term = extractPatientQueryTerm(rawQuery);
    if (term.isNotEmpty) {
      final lookup = resolvePatient(term, clinicState);
      if (lookup.isEmpty) {
        return AssistantResponse(
          text: 'No patient matching "$term" was found.',
          intent: AssistantIntent.paymentHistory,
          success: true,
          data: const {'found': false},
        );
      }

      if (lookup.isMultiple) {
        final buffer = StringBuffer('I found ${lookup.matches.length} patients matching "$term":\n');
        for (int i = 0; i < lookup.matches.length; i++) {
          final p = lookup.matches[i];
          buffer.writeln('${i + 1}. ${p.name} (ID: ${p.id}, Phone: ${p.phone})');
        }
        buffer.write('Please specify the patient ID or phone number.');
        return AssistantResponse(
          text: buffer.toString().trim(),
          intent: AssistantIntent.paymentHistory,
          success: true,
          data: {'disambiguation': true, 'matchCount': lookup.matches.length},
        );
      }

      final p = lookup.single!;
      final records = clinicState.paymentRecords.where((r) {
        return r.patientId.toLowerCase() == p.id.toLowerCase() ||
            r.patientName.toLowerCase() == p.name.toLowerCase();
      }).toList();

      if (records.isEmpty) {
        final paidInvoices = clinicState.invoices.where((inv) {
          return (inv.patientId.toLowerCase() == p.id.toLowerCase() ||
                  inv.patientName.toLowerCase() == p.name.toLowerCase()) &&
              inv.paidAmount > 0;
        }).toList();

        if (paidInvoices.isEmpty) {
          return AssistantResponse(
            text: 'No payment transactions or receipts found for ${p.name} (ID: ${p.id}).',
            intent: AssistantIntent.paymentHistory,
            success: true,
            data: {'patientId': p.id, 'count': 0},
          );
        }

        final buffer = StringBuffer('Payment History for ${p.name} (ID: ${p.id}):\n');
        double totalPaid = 0.0;
        for (int i = 0; i < paidInvoices.length; i++) {
          final inv = paidInvoices[i];
          totalPaid += inv.paidAmount;
          final dStr = DateFormat('dd MMM yyyy').format(inv.date);
          buffer.writeln('${i + 1}. ₹${inv.paidAmount.toStringAsFixed(0)} on $dStr via ${inv.paymentMethod} (Invoice: ${inv.invoiceNumber})');
        }
        buffer.writeln('Total Payments: ₹${totalPaid.toStringAsFixed(0)}');
        return AssistantResponse(
          text: buffer.toString().trim(),
          intent: AssistantIntent.paymentHistory,
          success: true,
          data: {'patientId': p.id, 'count': paidInvoices.length, 'totalPaid': totalPaid},
        );
      }

      records.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      final buffer = StringBuffer('Payment History for ${p.name} (ID: ${p.id}):\n');
      double totalPaid = 0.0;
      for (int i = 0; i < records.length; i++) {
        final r = records[i];
        totalPaid += r.amount;
        final dStr = DateFormat('dd MMM yyyy').format(r.paymentDate);
        final receiptStr = r.receiptNumber.isNotEmpty ? ' [Receipt: ${r.receiptNumber}]' : '';
        buffer.writeln('${i + 1}. ₹${r.amount.toStringAsFixed(0)} on $dStr via ${r.paymentMethod}$receiptStr');
      }
      buffer.writeln('Total Payments: ₹${totalPaid.toStringAsFixed(0)}');

      return AssistantResponse(
        text: buffer.toString().trim(),
        intent: AssistantIntent.paymentHistory,
        success: true,
        data: {'patientId': p.id, 'count': records.length, 'totalPaid': totalPaid},
      );
    }

    final records = clinicState.paymentRecords;
    if (records.isEmpty) {
      return const AssistantResponse(
        text: 'No payment transactions or ledger entries recorded.',
        intent: AssistantIntent.paymentHistory,
        success: true,
        data: {'count': 0},
      );
    }

    final buffer = StringBuffer('Recent Payment Ledger Entries (${records.length} records):\n');
    for (int i = 0; i < records.length && i < 10; i++) {
      final r = records[i];
      final dStr = DateFormat('dd MMM yyyy').format(r.paymentDate);
      buffer.writeln('${i + 1}. ₹${r.amount.toStringAsFixed(0)} from ${r.patientName} on $dStr via ${r.paymentMethod}');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.paymentHistory,
      success: true,
      data: {'count': records.length},
    );
  }

  static Future<AssistantResponse> _handleClinicSummary(ClinicState clinicState) async {
    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getClinicSummary',
      arguments: {},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error retrieving clinic summary: ${data['error']}',
        intent: AssistantIntent.clinicSummary,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final text = 'Clinic Operations Summary (${data['date']}):\n'
        '• Total Appointments Today: ${data['totalAppointmentsToday']}\n'
        '• Waiting Room Queue: ${data['waitingRoomQueue']} patient(s)\n'
        '• Consultations in Progress: ${data['inProgressCount']}\n'
        '• Completed Today: ${data['completedCount']}\n'
        '• Cancelled Today: ${data['cancelledCount']}\n'
        '• Available Doctors: ${data['availableDoctorsCount']}\n'
        '• Busiest Doctor: ${data['busiestDoctorToday']} (${data['busiestDoctorAppointments']} appts)\n'
        '• Today\'s Billed: ₹${(data['todayBillingTotal'] as num?)?.toStringAsFixed(0) ?? '0'}\n'
        '• Today\'s Collections: ₹${(data['todayCollectedTotal'] as num?)?.toStringAsFixed(0) ?? '0'}\n'
        '• Pending Call Reminders: ${data['pendingRemindersCount']}';

    return AssistantResponse(
      text: text,
      intent: AssistantIntent.clinicSummary,
      data: data,
    );
  }

  static Future<AssistantResponse> _handleFollowUps(ClinicState clinicState) async {
    final raw = await ClinicToolsRegistry.executeTool(
      toolName: 'getFollowUps',
      arguments: {},
      clinicState: clinicState,
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      return AssistantResponse(
        text: 'Database error retrieving follow-ups: ${data['error']}',
        intent: AssistantIntent.followUps,
        success: false,
        errorMessage: data['error']?.toString(),
        data: data,
      );
    }

    final count = data['remindersCount'] as int? ?? 0;
    final pendingCount = data['pendingCount'] as int? ?? 0;
    final followUps = (data['followUps'] as List<dynamic>?) ?? [];

    if (count == 0 || followUps.isEmpty) {
      return AssistantResponse(
        text: 'There are no pending follow-up call reminders.',
        intent: AssistantIntent.followUps,
        data: data,
      );
    }

    final buffer = StringBuffer('Found $count follow-up reminder(s) ($pendingCount pending):\n');
    for (int i = 0; i < followUps.length; i++) {
      final f = followUps[i] as Map<String, dynamic>;
      buffer.writeln('${i + 1}. ${f['patientName']} (${f['phoneNumber']}) — ${f['appointmentType']} [Status: ${f['status']}]');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.followUps,
      data: data,
    );
  }

  static Future<AssistantResponse> _handlePatientSummary(
    String rawQuery,
    ClinicState clinicState,
  ) async {
    final patError = clinicState.patientsError;
    if (patError != null) {
      return AssistantResponse(
        text: 'Database error: $patError. Cannot retrieve live clinic data.',
        intent: AssistantIntent.patientSummary,
        success: false,
        errorMessage: patError,
      );
    }

    final term = extractPatientQueryTerm(rawQuery);
    if (term.isEmpty) {
      return const AssistantResponse(
        text: "Please specify the patient's name, ID, or phone number.",
        intent: AssistantIntent.patientSummary,
        success: true,
      );
    }

    final lookup = resolvePatient(term, clinicState);
    if (lookup.isEmpty) {
      return AssistantResponse(
        text: 'No patient matching "$term" was found.',
        intent: AssistantIntent.patientSummary,
        success: true,
        data: const {'found': false},
      );
    }

    if (lookup.isMultiple) {
      final buffer = StringBuffer('I found ${lookup.matches.length} patients matching "$term":\n');
      for (int i = 0; i < lookup.matches.length; i++) {
        final p = lookup.matches[i];
        buffer.writeln('${i + 1}. ${p.name} (ID: ${p.id}, Phone: ${p.phone})');
      }
      buffer.write('Please specify the patient ID or phone number.');
      return AssistantResponse(
        text: buffer.toString().trim(),
        intent: AssistantIntent.patientSummary,
        success: true,
        data: {'disambiguation': true, 'matchCount': lookup.matches.length},
      );
    }

    final p = lookup.single!;
    final regDateStr = DateFormat('dd MMM yyyy').format(p.registrationDate);
    final nextAptStr = (p.nextAppointment != null && p.nextAppointment!.isNotEmpty)
        ? p.nextAppointment!
        : 'None scheduled';
    final alertsStr = p.medicalAlerts.isNotEmpty ? p.medicalAlerts.join(', ') : 'None recorded';
    final allergiesStr = p.allergies.isNotEmpty ? p.allergies.join(', ') : 'None recorded';
    final notesStr = p.notes.isNotEmpty ? p.notes : 'None recorded';
    final docStr = p.assignedDoctorName.isNotEmpty ? p.assignedDoctorName : 'None assigned';

    final buffer = StringBuffer('Patient Summary for ${p.name} (ID: ${p.id}):\n');
    buffer.writeln('• Age: ${p.age.isNotEmpty ? p.age : 'Not recorded'} | Gender: ${p.gender.isNotEmpty ? p.gender : 'Not recorded'}');
    buffer.writeln('• Phone: ${p.phone.isNotEmpty ? p.phone : 'Not recorded'}');
    buffer.writeln('• Registered: $regDateStr | Last Visit: ${p.lastVisit.isNotEmpty ? p.lastVisit : 'None recorded'}');
    buffer.writeln('• Total Visits: ${p.totalVisits}');
    buffer.writeln('• Next Appointment: $nextAptStr');
    buffer.writeln('• Outstanding Balance: ₹${p.balanceDue.toStringAsFixed(0)}');
    buffer.writeln('• Assigned Doctor: $docStr');
    buffer.writeln('• Medical Alerts: $alertsStr');
    buffer.writeln('• Allergies: $allergiesStr');
    buffer.write('• Clinical Notes: $notesStr');

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.patientSummary,
      success: true,
      data: {
        'patientId': p.id,
        'name': p.name,
        'phone': p.phone,
        'age': p.age,
        'gender': p.gender,
        'balanceDue': p.balanceDue,
        'nextAppointment': p.nextAppointment,
      },
    );
  }

  static Future<AssistantResponse> _handlePatientAppointments(
    String rawQuery,
    ClinicState clinicState,
  ) async {
    final patAptError = clinicState.patientsError ?? clinicState.appointmentsError;
    if (patAptError != null) {
      return AssistantResponse(
        text: 'Database error: $patAptError. Cannot retrieve live clinic data.',
        intent: AssistantIntent.patientAppointments,
        success: false,
        errorMessage: patAptError,
      );
    }

    final term = extractPatientQueryTerm(rawQuery);
    if (term.isEmpty) {
      return const AssistantResponse(
        text: "Please specify the patient's name, ID, or phone number.",
        intent: AssistantIntent.patientAppointments,
        success: true,
      );
    }

    final lookup = resolvePatient(term, clinicState);
    if (lookup.isEmpty) {
      return AssistantResponse(
        text: 'No patient matching "$term" was found.',
        intent: AssistantIntent.patientAppointments,
        success: true,
        data: const {'found': false},
      );
    }

    if (lookup.isMultiple) {
      final buffer = StringBuffer('I found ${lookup.matches.length} patients matching "$term":\n');
      for (int i = 0; i < lookup.matches.length; i++) {
        final p = lookup.matches[i];
        buffer.writeln('${i + 1}. ${p.name} (ID: ${p.id}, Phone: ${p.phone})');
      }
      buffer.write('Please specify the patient ID or phone number.');
      return AssistantResponse(
        text: buffer.toString().trim(),
        intent: AssistantIntent.patientAppointments,
        success: true,
        data: {'disambiguation': true, 'matchCount': lookup.matches.length},
      );
    }

    final p = lookup.single!;
    final apts = clinicState.appointments.where((a) {
      return a.patientId.toLowerCase() == p.id.toLowerCase() ||
          a.patientName.toLowerCase() == p.name.toLowerCase();
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final now = DateTime.now();
    final lowerQ = rawQuery.toLowerCase();
    final isNextQuery = lowerQ.contains('next') || lowerQ.contains('upcoming');
    final isHistoryQuery = lowerQ.contains('history') || lowerQ.contains('past');

    final upcoming = apts.where((a) => a.dateTime.isAfter(now) && a.status != AppointmentStatus.completed && a.status != AppointmentStatus.cancelled).toList();
    final past = apts.where((a) => a.dateTime.isBefore(now) || a.status == AppointmentStatus.completed).toList();

    if (isNextQuery) {
      if (upcoming.isNotEmpty) {
        final nextApt = upcoming.first;
        final timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(nextApt.dateTime);
        final treatment = nextApt.appointmentType.isNotEmpty ? ' (${nextApt.appointmentType})' : '';
        return AssistantResponse(
          text: 'Next appointment for ${p.name} (ID: ${p.id}):\n• $timeStr with ${nextApt.doctorName}$treatment [Status: ${nextApt.status.label}]',
          intent: AssistantIntent.patientAppointments,
          success: true,
          data: {'nextAppointment': nextApt.id, 'patientId': p.id},
        );
      } else {
        return AssistantResponse(
          text: '${p.name} (ID: ${p.id}) has no upcoming appointments scheduled.',
          intent: AssistantIntent.patientAppointments,
          success: true,
          data: {'patientId': p.id, 'hasUpcoming': false},
        );
      }
    }

    if (isHistoryQuery) {
      if (past.isNotEmpty) {
        final buffer = StringBuffer('Appointment history for ${p.name} (ID: ${p.id}) (${past.length} past visit(s)):\n');
        for (int i = 0; i < past.length; i++) {
          final a = past[i];
          final timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(a.dateTime);
          final treatment = a.appointmentType.isNotEmpty ? ' (${a.appointmentType})' : '';
          buffer.writeln('${i + 1}. $timeStr — ${a.doctorName}$treatment [Status: ${a.status.label}]');
        }
        return AssistantResponse(
          text: buffer.toString().trim(),
          intent: AssistantIntent.patientAppointments,
          success: true,
          data: {'historyCount': past.length, 'patientId': p.id},
        );
      } else {
        return AssistantResponse(
          text: '${p.name} (ID: ${p.id}) has no past appointment history recorded.',
          intent: AssistantIntent.patientAppointments,
          success: true,
          data: {'patientId': p.id, 'historyCount': 0},
        );
      }
    }

    if (apts.isEmpty) {
      return AssistantResponse(
        text: 'No appointments found for ${p.name} (ID: ${p.id}).',
        intent: AssistantIntent.patientAppointments,
        success: true,
        data: {'count': 0, 'patientId': p.id},
      );
    }

    final buffer = StringBuffer('Found ${apts.length} appointment(s) for ${p.name} (ID: ${p.id}):\n');
    for (int i = 0; i < apts.length; i++) {
      final a = apts[i];
      final timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(a.dateTime);
      final treatment = a.appointmentType.isNotEmpty ? ' (${a.appointmentType})' : '';
      buffer.writeln('${i + 1}. $timeStr — ${a.doctorName}$treatment [Status: ${a.status.label}]');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.patientAppointments,
      success: true,
      data: {'count': apts.length, 'patientId': p.id},
    );
  }

  static Future<AssistantResponse> _handlePatientBalance(
    String rawQuery,
    ClinicState clinicState,
  ) async {
    final balError = clinicState.patientsError ?? clinicState.billingError;
    if (balError != null) {
      return AssistantResponse(
        text: 'Database error: $balError. Cannot retrieve live clinic data.',
        intent: AssistantIntent.patientBalance,
        success: false,
        errorMessage: balError,
      );
    }

    final term = extractPatientQueryTerm(rawQuery);
    if (term.isEmpty) {
      return const AssistantResponse(
        text: "Please specify the patient's name, ID, or phone number.",
        intent: AssistantIntent.patientBalance,
        success: true,
      );
    }

    final lookup = resolvePatient(term, clinicState);
    if (lookup.isEmpty) {
      return AssistantResponse(
        text: 'No patient matching "$term" was found.',
        intent: AssistantIntent.patientBalance,
        success: true,
        data: const {'found': false},
      );
    }

    if (lookup.isMultiple) {
      final buffer = StringBuffer('I found ${lookup.matches.length} patients matching "$term":\n');
      for (int i = 0; i < lookup.matches.length; i++) {
        final p = lookup.matches[i];
        buffer.writeln('${i + 1}. ${p.name} (ID: ${p.id}, Phone: ${p.phone})');
      }
      buffer.write('Please specify the patient ID or phone number.');
      return AssistantResponse(
        text: buffer.toString().trim(),
        intent: AssistantIntent.patientBalance,
        success: true,
        data: {'disambiguation': true, 'matchCount': lookup.matches.length},
      );
    }

    final p = lookup.single!;
    final invoices = clinicState.invoices.where((inv) {
      return inv.patientId.toLowerCase() == p.id.toLowerCase() ||
          inv.patientName.toLowerCase() == p.name.toLowerCase();
    }).toList();

    double totalBilled = 0.0;
    double totalPaid = 0.0;
    double totalBalance = 0.0;

    for (final inv in invoices) {
      totalBilled += inv.totalAmount;
      totalPaid += inv.paidAmount;
      totalBalance += inv.balanceAmount;
    }

    final balanceDue = totalBalance > 0 ? totalBalance : p.balanceDue;
    final unpaidInvoices = invoices.where((i) => i.balanceAmount > 0).toList();

    if (balanceDue <= 0.0 && unpaidInvoices.isEmpty) {
      return AssistantResponse(
        text: '${p.name} (ID: ${p.id}) has no outstanding balance. All accounts are settled.',
        intent: AssistantIntent.patientBalance,
        success: true,
        data: {
          'patientId': p.id,
          'balanceDue': 0.0,
          'totalBilled': totalBilled,
          'totalPaid': totalPaid,
        },
      );
    }

    final buffer = StringBuffer('${p.name} (ID: ${p.id}) has an outstanding balance of ₹${balanceDue.toStringAsFixed(0)}.\n');
    buffer.writeln('• Total Billed: ₹${totalBilled.toStringAsFixed(0)} | Total Paid: ₹${totalPaid.toStringAsFixed(0)}');

    if (unpaidInvoices.isNotEmpty) {
      buffer.writeln('• Unpaid / Partial Invoice(s):');
      for (int i = 0; i < unpaidInvoices.length; i++) {
        final inv = unpaidInvoices[i];
        final dateStr = DateFormat('dd MMM yyyy').format(inv.date);
        buffer.writeln('  ${i + 1}. ${inv.invoiceNumber} ($dateStr): ₹${inv.balanceAmount.toStringAsFixed(0)} due [Status: ${inv.status.label}]');
      }
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.patientBalance,
      success: true,
      data: {
        'patientId': p.id,
        'balanceDue': balanceDue,
        'unpaidCount': unpaidInvoices.length,
        'totalBilled': totalBilled,
        'totalPaid': totalPaid,
      },
    );
  }

  static Future<AssistantResponse> _handlePatientFollowUp(
    String rawQuery,
    ClinicState clinicState,
  ) async {
    final fuError = clinicState.remindersError ?? clinicState.patientsError;
    if (fuError != null) {
      return AssistantResponse(
        text: 'Database error: $fuError. Cannot retrieve live clinic data.',
        intent: AssistantIntent.patientFollowUp,
        success: false,
        errorMessage: fuError,
      );
    }

    final term = extractPatientQueryTerm(rawQuery);
    if (term.isEmpty) {
      return const AssistantResponse(
        text: "Please specify the patient's name, ID, or phone number.",
        intent: AssistantIntent.patientFollowUp,
        success: true,
      );
    }

    final lookup = resolvePatient(term, clinicState);
    if (lookup.isEmpty) {
      return AssistantResponse(
        text: 'No patient matching "$term" was found.',
        intent: AssistantIntent.patientFollowUp,
        success: true,
        data: const {'found': false},
      );
    }

    if (lookup.isMultiple) {
      final buffer = StringBuffer('I found ${lookup.matches.length} patients matching "$term":\n');
      for (int i = 0; i < lookup.matches.length; i++) {
        final p = lookup.matches[i];
        buffer.writeln('${i + 1}. ${p.name} (ID: ${p.id}, Phone: ${p.phone})');
      }
      buffer.write('Please specify the patient ID or phone number.');
      return AssistantResponse(
        text: buffer.toString().trim(),
        intent: AssistantIntent.patientFollowUp,
        success: true,
        data: {'disambiguation': true, 'matchCount': lookup.matches.length},
      );
    }

    final p = lookup.single!;
    final reminders = clinicState.callReminders.where((r) {
      return r.patientName.toLowerCase() == p.name.toLowerCase() ||
          (r.phoneNumber.isNotEmpty && r.phoneNumber.replaceAll(RegExp(r'\D'), '') == p.phone.replaceAll(RegExp(r'\D'), ''));
    }).toList();

    if (reminders.isEmpty) {
      return AssistantResponse(
        text: 'No pending follow-ups or call reminders found for ${p.name} (ID: ${p.id}).',
        intent: AssistantIntent.patientFollowUp,
        success: true,
        data: {'patientId': p.id, 'remindersCount': 0},
      );
    }

    final buffer = StringBuffer('Found ${reminders.length} follow-up reminder(s) for ${p.name} (ID: ${p.id}):\n');
    for (int i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      buffer.writeln('${i + 1}. ${r.appointmentType} — Date: ${r.appointmentDate} ${r.appointmentTime} [Status: ${r.status.label}]');
      if (r.nextAttempt.isNotEmpty) {
        buffer.writeln('   Next Call Attempt: ${r.nextAttempt}');
      }
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.patientFollowUp,
      success: true,
      data: {'patientId': p.id, 'remindersCount': reminders.length},
    );
  }

  static Future<AssistantResponse> _handlePatientToothRecords(
    String rawQuery,
    ClinicState clinicState,
  ) async {
    final toothError = clinicState.toothRecordsError;
    if (toothError != null) {
      return AssistantResponse(
        text: "I can't retrieve tooth records right now because the Tooth Records database is unavailable.",
        intent: AssistantIntent.patientToothRecords,
        success: false,
        errorMessage: toothError,
      );
    }

    final term = extractPatientQueryTerm(rawQuery);
    if (term.isEmpty) {
      final allRecords = clinicState.toothRecords;
      if (allRecords.isEmpty) {
        return const AssistantResponse(
          text: 'There are currently no tooth records on file in the clinic database.',
          intent: AssistantIntent.patientToothRecords,
          success: true,
          data: {'count': 0, 'records': []},
        );
      }
      final buffer = StringBuffer('Found ${allRecords.length} tooth record(s) on file in the clinic database:\n');
      final displayCount = allRecords.length > 5 ? 5 : allRecords.length;
      for (int i = 0; i < displayCount; i++) {
        final r = allRecords[i];
        buffer.writeln('${i + 1}. Tooth #${r.toothNumber} (${r.toothName}): ${r.status.label} [${r.completionStatus.label}]');
      }
      if (allRecords.length > 5) {
        buffer.write('...and ${allRecords.length - 5} more records.');
      }
      return AssistantResponse(
        text: buffer.toString().trim(),
        intent: AssistantIntent.patientToothRecords,
        success: true,
        data: {'count': allRecords.length},
      );
    }

    final lookup = resolvePatient(term, clinicState);
    if (lookup.isEmpty) {
      return AssistantResponse(
        text: 'No patient matching "$term" was found.',
        intent: AssistantIntent.patientToothRecords,
        success: true,
        data: const {'found': false},
      );
    }

    if (lookup.isMultiple) {
      final buffer = StringBuffer('I found ${lookup.matches.length} patients matching "$term":\n');
      for (int i = 0; i < lookup.matches.length; i++) {
        final p = lookup.matches[i];
        buffer.writeln('${i + 1}. ${p.name} (ID: ${p.id}, Phone: ${p.phone})');
      }
      buffer.write('Please specify the patient ID or phone number.');
      return AssistantResponse(
        text: buffer.toString().trim(),
        intent: AssistantIntent.patientToothRecords,
        success: true,
        data: {'disambiguation': true, 'matchCount': lookup.matches.length},
      );
    }

    final p = lookup.single!;
    final records = clinicState.getToothRecordsForPatient(p.id);
    if (records.isEmpty) {
      return AssistantResponse(
        text: '${p.name} (ID: ${p.id}) has no recorded tooth treatments or dental chart entries.',
        intent: AssistantIntent.patientToothRecords,
        success: true,
        data: {'patientId': p.id, 'count': 0, 'records': []},
      );
    }

    final buffer = StringBuffer('Tooth records for ${p.name} (ID: ${p.id}) — ${records.length} record(s):\n');
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final dateStr = DateFormat('dd MMM yyyy').format(r.treatmentDate);
      buffer.writeln('${i + 1}. Tooth #${r.toothNumber} (${r.toothName}) — ${r.status.label}: ${r.procedure.isNotEmpty ? r.procedure : "Exam"} [${r.completionStatus.label}] on $dateStr');
    }

    return AssistantResponse(
      text: buffer.toString().trim(),
      intent: AssistantIntent.patientToothRecords,
      success: true,
      data: {'patientId': p.id, 'count': records.length, 'records': records.map((r) => r.toJson()).toList()},
    );
  }

  static Future<AssistantResponse> _handleDentalKnowledge(
    String query,
    ClinicState clinicState,
  ) async {
    final result = LocalDentalKnowledge.query(query);
    return AssistantResponse(
      text: result.content,
      intent: AssistantIntent.dentalKnowledge,
      success: true,
      data: {
        'topic': result.topic,
        'title': result.title,
        'isSupported': result.isSupported,
        'isPatientDiagnosisAttempt': result.isPatientDiagnosisAttempt,
        if (result.patientName != null) 'patientName': result.patientName,
      },
    );
  }
}
