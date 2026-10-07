import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/services/ai/local_assistant_engine.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/models/patient.dart';
import 'package:dental_clinic_app/models/appointment.dart';
import 'package:dental_clinic_app/models/billing.dart';
import 'package:dental_clinic_app/models/call_reminder.dart';
import 'package:dental_clinic_app/models/payment_record.dart';

void main() {
  group('Local Assistant Core & Natural Language Intent Expansion Tests', () {
    late ClinicState clinicState;

    setUp(() {
      clinicState = ClinicState();
    });

    test('1. Normalization: handles casing, punctuation, and extra whitespace', () {
      const raw = "   WHAT'S   TODAY'S   APPOINTMENTS???   ";
      final normalized = LocalAssistantEngine.normalizeQuery(raw);
      expect(normalized, equals("what is today appointments"));

      const rawPunctuation = "Who is available right now?!,.;:";
      expect(LocalAssistantEngine.normalizeQuery(rawPunctuation), equals("who is available right now"));
    });

    test('2. Today appointments: natural phrasing variations', () {
      final queries = [
        "What appointments do we have today?",
        "Show today's appointments",
        "Today's schedule",
        "Who is coming today?",
        "What is the appointment schedule for today?",
        "Do we have appointments today?",
        "TODAY'S BOOKINGS",
        "  appointments today  ",
      ];

      for (final q in queries) {
        final intent = LocalAssistantEngine.parseIntent(q);
        expect(intent, equals(AssistantIntent.todayAppointments), reason: 'Failed for query: "$q"');
      }
    });

    test('3. Tomorrow appointments: natural phrasing variations', () {
      final queries = [
        "What appointments are tomorrow?",
        "Show tomorrow's appointments",
        "Who is coming tomorrow?",
        "Tomorrow's schedule",
        "How many appointments are scheduled for tomorrow?",
        "tomorrow bookings",
      ];

      for (final q in queries) {
        final intent = LocalAssistantEngine.parseIntent(q);
        expect(intent, equals(AssistantIntent.tomorrowAppointments), reason: 'Failed for query: "$q"');
      }
    });

    test('4. Patient search: natural phrasing and prefix extraction', () {
      final expectations = {
        "Find patient John": "john",
        "Search for John": "john",
        "Do we have a patient named John?": "john",
        "Show patient John": "john",
        "Find patient by phone number 9876543210": "9876543210",
        "Search patient ID PT-01": "pt-01",
        "Lookup patient Rahul": "rahul",
      };

      expectations.forEach((query, expectedTerm) {
        final intent = LocalAssistantEngine.parseIntent(query);
        expect(intent, equals(AssistantIntent.patientSearch), reason: 'Intent failed for: "$query"');

        final extracted = LocalAssistantEngine.extractPatientSearchTerm(query).toLowerCase();
        expect(extracted, equals(expectedTerm), reason: 'Extraction failed for: "$query"');
      });
    });

    test('5. Doctor availability: natural phrasing variations', () {
      final queries = [
        "Which doctors are available?",
        "Who is available right now?",
        "Show available doctors",
        "Which doctor is free?",
        "Are any doctors available?",
        "Who is on duty?",
        "doctor roster",
      ];

      for (final q in queries) {
        final intent = LocalAssistantEngine.parseIntent(q);
        expect(intent, equals(AssistantIntent.doctorAvailability), reason: 'Failed for query: "$q"');
      }
    });

    test('6. Pending payments & invoices: natural phrasing variations', () {
      final invoiceQueries = [
        "Show unpaid invoices",
        "Show pending invoices",
        "unpaid bills",
        "pending bills",
      ];
      for (final q in invoiceQueries) {
        expect(LocalAssistantEngine.parseIntent(q), equals(AssistantIntent.pendingInvoices), reason: 'Failed for: "$q"');
      }

      final paymentQueries = [
        "Who has pending payments?",
        "What payments are pending?",
        "Which patients still have a balance?",
        "How much money is pending?",
        "outstanding balance",
        "who owes",
      ];
      for (final q in paymentQueries) {
        expect(LocalAssistantEngine.parseIntent(q), equals(AssistantIntent.pendingPayments), reason: 'Failed for: "$q"');
      }
    });

    test('7. Today revenue: natural phrasing variations', () {
      final queries = [
        "How much did we collect today?",
        "Today's revenue",
        "How much was billed today?",
        "What did we collect today?",
        "What are today's collections?",
        "How much money did we make today?",
      ];

      for (final q in queries) {
        expect(LocalAssistantEngine.parseIntent(q), equals(AssistantIntent.todayRevenue), reason: 'Failed for query: "$q"');
      }
    });

    test('8. Clinic summary: natural phrasing variations', () {
      final queries = [
        "Give me a clinic summary",
        "How is the clinic doing today?",
        "Show today's clinic status",
        "Give me today's overview",
        "What is happening in the clinic today?",
        "daily summary",
      ];

      for (final q in queries) {
        expect(LocalAssistantEngine.parseIntent(q), equals(AssistantIntent.clinicSummary), reason: 'Failed for query: "$q"');
      }
    });

    test('9. Follow-ups: natural phrasing variations', () {
      final queries = [
        "Which patients need follow-up?",
        "Show pending follow-ups",
        "Who should we call?",
        "Show today's follow-up reminders",
        "Which follow-ups are pending?",
        "pending reminders",
      ];

      for (final q in queries) {
        expect(LocalAssistantEngine.parseIntent(q), equals(AssistantIntent.followUps), reason: 'Failed for query: "$q"');
      }
    });

    test('10. Date handling: yesterday and this week support', () async {
      // Yesterday's appointments
      const yQuery = "What appointments were yesterday?";
      expect(LocalAssistantEngine.parseIntent(yQuery), equals(AssistantIntent.yesterdayAppointments));
      final yResponse = await LocalAssistantEngine.processQuery(yQuery, clinicState: clinicState);
      expect(yResponse.success, isTrue);
      expect(yResponse.intent, equals(AssistantIntent.yesterdayAppointments));

      // This week's appointments
      const wQuery = "Show appointments for this week";
      expect(LocalAssistantEngine.parseIntent(wQuery), equals(AssistantIntent.thisWeekAppointments));
      final wResponse = await LocalAssistantEngine.processQuery(wQuery, clinicState: clinicState);
      expect(wResponse.success, isTrue);
      expect(wResponse.intent, equals(AssistantIntent.thisWeekAppointments));
    });

    test('11. Appointment count: natural phrasing variations', () {
      final queries = [
        "How many appointments today?",
        "How many appointments do we have?",
        "Total appointments today",
        "appointment count",
      ];

      for (final q in queries) {
        expect(LocalAssistantEngine.parseIntent(q), equals(AssistantIntent.appointmentCount), reason: 'Failed for: "$q"');
      }
    });

    test('12. Unsupported queries return safe guidance without guessing', () async {
      final queries = [
        "What is the capital of Australia?",
        "Can you write a poem about teeth?",
        "Tell me a joke",
      ];

      for (final q in queries) {
        expect(LocalAssistantEngine.parseIntent(q), equals(AssistantIntent.unsupported));
        final response = await LocalAssistantEngine.processQuery(q, clinicState: clinicState);
        expect(response.success, isTrue);
        expect(response.intent, equals(AssistantIntent.unsupported));
        expect(response.text, contains('appointments'));
        expect(response.text, contains('patients'));
        expect(response.text, contains('billing'));
      }
    });

    test('13. Empty queries produce graceful response', () async {
      final response = await LocalAssistantEngine.processQuery('   ', clinicState: clinicState);
      expect(response.success, isFalse);
      expect(response.intent, equals(AssistantIntent.unsupported));
      expect(response.text, contains('Please enter a query'));
    });

    test('14. Database error propagation preserves failure and does not invent fake records', () async {
      clinicState.setRemoteErrorForTesting('Supabase connection lost');

      final queries = [
        "What appointments do we have today?",
        "Who is available right now?",
        "How much did we collect today?",
        "Give me a clinic summary",
      ];

      for (final q in queries) {
        final response = await LocalAssistantEngine.processQuery(q, clinicState: clinicState);
        expect(response.success, isFalse, reason: 'Failed for query: "$q"');
        expect(response.errorMessage, contains('Supabase connection lost'));
        expect(response.text, contains('Database error'));
      }
    });

    test('15. Real data fidelity matches live ClinicState collections', () async {
      clinicState.clearRemoteError();

      // Today's appointments match clinicState.todayAppointments
      final aptResponse = await LocalAssistantEngine.processQuery("Show today's appointments", clinicState: clinicState);
      expect(aptResponse.success, isTrue);
      if (clinicState.todayAppointments.isNotEmpty) {
        expect(aptResponse.text, contains(clinicState.todayAppointments.first.patientName));
      }

      // Today's revenue matches clinicState.todayCollectedTotal and todayBillingTotal
      final revResponse = await LocalAssistantEngine.processQuery("How much did we collect today?", clinicState: clinicState);
      expect(revResponse.success, isTrue);
      expect(revResponse.text, contains('₹${clinicState.todayCollectedTotal.toStringAsFixed(0)}'));
    });
  });

  group('Phase 4: Patient-Specific Assistance & Safe Disambiguation Tests', () {
    late ClinicState clinicState;

    setUp(() {
      clinicState = ClinicState();
      // Seed test patients
      final testPatients = [
        Patient(
          id: 'P-1001',
          name: 'Aarav Sharma',
          phone: '9876543210',
          email: 'aarav@example.com',
          dateOfBirth: '14 May 1994',
          gender: 'Male',
          age: '32',
          address: 'Bengaluru',
          emergencyContact: 'Sunita Sharma 9876543219',
          assignedDoctorId: 'DOC-02',
          assignedDoctorName: 'Dr. Priya Mehta',
          lastVisit: '05 Sep 2026',
          nextAppointment: 'Today, 10:00 AM',
          totalVisits: 4,
          balanceDue: 1500.0,
          bloodGroup: 'B+',
          allergies: const ['Penicillin'],
          medicalAlerts: const ['Hypertension'],
          notes: 'Patient prefers topical anesthetic first.',
          registrationDate: DateTime(2025, 3, 12),
        ),
        Patient(
          id: 'P-1002',
          name: 'Neha Kapoor',
          phone: '9811234567',
          email: 'neha@example.com',
          dateOfBirth: '22 Aug 1988',
          gender: 'Female',
          age: '36',
          address: 'Bengaluru',
          emergencyContact: 'Rajesh Kapoor 9811234568',
          assignedDoctorId: 'DOC-03',
          assignedDoctorName: 'Dr. Amit Shah',
          lastVisit: '12 Sep 2026',
          nextAppointment: null,
          totalVisits: 6,
          balanceDue: 0.0,
          bloodGroup: 'O+',
          allergies: const [],
          medicalAlerts: const [],
          notes: '',
          registrationDate: DateTime(2024, 11, 20),
        ),
        Patient(
          id: 'P-2001',
          name: 'Rahul Sharma',
          phone: '9900011111',
          email: 'rahul.s@example.com',
          dateOfBirth: '01 Jan 1990',
          gender: 'Male',
          age: '34',
          address: 'Bengaluru',
          emergencyContact: 'Meena 9900011112',
          assignedDoctorId: 'DOC-01',
          assignedDoctorName: 'Dr. Rahul Sharma',
          lastVisit: '10 Aug 2026',
          totalVisits: 2,
          balanceDue: 500.0,
          registrationDate: DateTime(2025, 1, 10),
        ),
        Patient(
          id: 'P-2002',
          name: 'Rahul Verma',
          phone: '9900022222',
          email: 'rahul.v@example.com',
          dateOfBirth: '02 Feb 1985',
          gender: 'Male',
          age: '39',
          address: 'Bengaluru',
          emergencyContact: 'Rohit 9900022223',
          assignedDoctorId: 'DOC-01',
          assignedDoctorName: 'Dr. Rahul Sharma',
          lastVisit: '15 Aug 2026',
          totalVisits: 3,
          balanceDue: 1200.0,
          registrationDate: DateTime(2025, 2, 15),
        ),
      ];

      clinicState.setPatientsForTesting(testPatients);

      final List<Appointment> testAppointments = [
        Appointment(
          id: 'APT-101',
          patientId: 'P-1001',
          patientName: 'Aarav Sharma',
          patientPhone: '9876543210',
          doctorId: 'DOC-02',
          doctorName: 'Dr. Priya Mehta',
          dateTime: DateTime.now().add(const Duration(hours: 2)),
          timeString: '10:00 AM',
          appointmentType: 'Dental Scaling',
          status: AppointmentStatus.scheduled,
          tokenNumber: '1',
        ),
        Appointment(
          id: 'APT-100',
          patientId: 'P-1001',
          patientName: 'Aarav Sharma',
          patientPhone: '9876543210',
          doctorId: 'DOC-02',
          doctorName: 'Dr. Priya Mehta',
          dateTime: DateTime.now().subtract(const Duration(days: 30)),
          timeString: '11:00 AM',
          appointmentType: 'Initial Consultation',
          status: AppointmentStatus.completed,
          tokenNumber: '5',
        ),
      ];
      clinicState.setAppointmentsForTesting(testAppointments);

      final List<Invoice> testInvoices = [
        Invoice(
          id: 'INV-101',
          invoiceNumber: 'INV-2026-001',
          patientId: 'P-1001',
          patientName: 'Aarav Sharma',
          patientPhone: '9876543210',
          doctorId: 'DOC-02',
          doctorName: 'Dr. Priya Mehta',
          items: const [],
          subtotal: 2500.0,
          totalAmount: 2500.0,
          paidAmount: 1000.0,
          balanceAmount: 1500.0,
          status: PaymentStatus.partial,
          paymentMethod: 'Cash',
          date: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Invoice(
          id: 'INV-102',
          invoiceNumber: 'INV-2026-002',
          patientId: 'P-1002',
          patientName: 'Neha Kapoor',
          patientPhone: '9811234567',
          doctorId: 'DOC-03',
          doctorName: 'Dr. Amit Shah',
          items: const [],
          subtotal: 3000.0,
          totalAmount: 3000.0,
          paidAmount: 3000.0,
          balanceAmount: 0.0,
          status: PaymentStatus.paid,
          paymentMethod: 'UPI',
          date: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];
      clinicState.setInvoicesForTesting(testInvoices);

      final testReminders = [
        CallReminder(
          id: 'REM-101',
          patientId: 'P-1001',
          patientName: 'Aarav Sharma',
          phoneNumber: '9876543210',
          appointmentDate: '25 Oct 2026',
          appointmentTime: '11:00 AM',
          doctorName: 'Dr. Priya Mehta',
          status: ReminderStatus.pending,
          lastAttempt: 'Not called yet',
          nextAttempt: 'Today before 12:00 PM',
          appointmentType: 'Scaling Follow-up',
        ),
      ];
      clinicState.setCallRemindersForTesting(testReminders);
    });

    test('16. Scenario 1: Unique patient lookup by name', () async {
      final res = await LocalAssistantEngine.processQuery("Tell me about Aarav Sharma", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.patientSummary));
      expect(res.text, contains('Aarav Sharma'));
      expect(res.text, contains('P-1001'));
      expect(res.text, contains('9876543210'));
      expect(res.text, contains('32'));
      expect(res.text, contains('Male'));
    });

    test('17. Scenario 2: Patient lookup by patient ID', () async {
      final res = await LocalAssistantEngine.processQuery("Tell me about P-1001", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.patientSummary));
      expect(res.text, contains('Aarav Sharma'));
      expect(res.text, contains('P-1001'));
    });

    test('18. Scenario 3: Patient lookup by phone', () async {
      final res = await LocalAssistantEngine.processQuery("Tell me about 9876543210", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.patientSummary));
      expect(res.text, contains('Aarav Sharma'));
      expect(res.text, contains('9876543210'));
    });

    test('19. Scenario 4: Multiple patients with same name triggers safe disambiguation', () async {
      final queries = [
        "Tell me about Rahul",
        "Rahul's balance",
        "Rahul's appointments",
        "Does Rahul have a follow-up?",
      ];

      for (final q in queries) {
        final res = await LocalAssistantEngine.processQuery(q, clinicState: clinicState);
        expect(res.success, isTrue, reason: 'Failed for query: "$q"');
        expect(res.text, contains('I found 2 patients matching "Rahul":'));
        expect(res.text, contains('Rahul Sharma (ID: P-2001'));
        expect(res.text, contains('Rahul Verma (ID: P-2002'));
        expect(res.text, contains('Please specify the patient ID or phone number.'));
      }
    });

    test('20. Scenario 5: Truthful no-match handling when patient does not exist', () async {
      final res = await LocalAssistantEngine.processQuery("Tell me about Vikramaditya Singh", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, equals('No patient matching "Vikramaditya Singh" was found.'));
    });

    test('21. Scenario 6: Patient appointment query returns scheduled & past records', () async {
      final res = await LocalAssistantEngine.processQuery("Aarav Sharma's appointments", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.patientAppointments));
      expect(res.text, contains('Found 2 appointment(s) for Aarav Sharma (ID: P-1001)'));
      expect(res.text, contains('Dr. Priya Mehta (Dental Scaling)'));
      expect(res.text, contains('Initial Consultation'));
    });

    test('22. Scenario 7: Patient next appointment highlights upcoming scheduled visit', () async {
      final res = await LocalAssistantEngine.processQuery("When is Aarav Sharma's next appointment?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.patientAppointments));
      expect(res.text, contains('Next appointment for Aarav Sharma (ID: P-1001)'));
      expect(res.text, contains('Dr. Priya Mehta (Dental Scaling)'));
    });

    test('23. Scenario 8: Patient appointment history displays chronological past visits', () async {
      final res = await LocalAssistantEngine.processQuery("Appointment history for Aarav Sharma", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.patientAppointments));
      expect(res.text, contains('Appointment history for Aarav Sharma (ID: P-1001) (1 past visit(s))'));
      expect(res.text, contains('Initial Consultation'));
    });

    test('24. Scenario 9: Patient pending balance shows receivables & settled status', () async {
      // With balance due
      final resBalance = await LocalAssistantEngine.processQuery("What is Aarav Sharma's balance?", clinicState: clinicState);
      expect(resBalance.success, isTrue);
      expect(resBalance.intent, equals(AssistantIntent.patientBalance));
      expect(resBalance.text, contains('Aarav Sharma (ID: P-1001) has an outstanding balance of ₹1500'));
      expect(resBalance.text, contains('INV-2026-001'));
      expect(resBalance.text, contains('Total Billed: ₹2500'));
      expect(resBalance.text, contains('Total Paid: ₹1000'));

      // Fully settled
      final resSettled = await LocalAssistantEngine.processQuery("What is Neha Kapoor's balance?", clinicState: clinicState);
      expect(resSettled.success, isTrue);
      expect(resSettled.intent, equals(AssistantIntent.patientBalance));
      expect(resSettled.text, contains('Neha Kapoor (ID: P-1002) has no outstanding balance. All accounts are settled.'));
    });

    test('25. Scenario 10: Patient follow-up displays pending reminders truthfully', () async {
      // With pending reminder
      final resWithRem = await LocalAssistantEngine.processQuery("Does Aarav Sharma have a follow-up?", clinicState: clinicState);
      expect(resWithRem.success, isTrue);
      expect(resWithRem.intent, equals(AssistantIntent.patientFollowUp));
      expect(resWithRem.text, contains('Found 1 follow-up reminder(s) for Aarav Sharma (ID: P-1001)'));
      expect(resWithRem.text, contains('Scaling Follow-up'));
      expect(resWithRem.text, contains('Today before 12:00 PM'));

      // With no reminder
      final resNoRem = await LocalAssistantEngine.processQuery("Does Neha Kapoor have a follow-up?", clinicState: clinicState);
      expect(resNoRem.success, isTrue);
      expect(resNoRem.intent, equals(AssistantIntent.patientFollowUp));
      expect(resNoRem.text, contains('No pending follow-ups or call reminders found for Neha Kapoor (ID: P-1002).'));
    });

    test('26. Scenario 11: Patient summary returns complete structured overview', () async {
      final res = await LocalAssistantEngine.processQuery("Patient summary for Aarav Sharma", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.patientSummary));
      expect(res.text, contains('Patient Summary for Aarav Sharma (ID: P-1001):'));
      expect(res.text, contains('Age: 32 | Gender: Male'));
      expect(res.text, contains('Phone: 9876543210'));
      expect(res.text, contains('Registered: 12 Mar 2025 | Last Visit: 05 Sep 2026'));
      expect(res.text, contains('Total Visits: 4'));
      expect(res.text, contains('Next Appointment: Today, 10:00 AM'));
      expect(res.text, contains('Outstanding Balance: ₹1500'));
      expect(res.text, contains('Assigned Doctor: Dr. Priya Mehta'));
      expect(res.text, contains('Medical Alerts: Hypertension'));
      expect(res.text, contains('Allergies: Penicillin'));
      expect(res.text, contains('Clinical Notes: Patient prefers topical anesthetic first.'));
    });

    test('27. Scenario 12: Missing clinical information explicitly reports "None recorded" without hallucination', () async {
      final res = await LocalAssistantEngine.processQuery("Patient summary for Neha Kapoor", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('Medical Alerts: None recorded'));
      expect(res.text, contains('Allergies: None recorded'));
      expect(res.text, contains('Clinical Notes: None recorded'));
    });

    test('28. Scenario 13: Database error propagation halts patient queries safely', () async {
      clinicState.setRemoteErrorForTesting('Connection timed out on Supabase endpoint');

      final queries = [
        "Tell me about Aarav Sharma",
        "Aarav Sharma's balance",
        "Aarav Sharma's appointments",
        "Does Aarav Sharma have a follow-up?",
      ];

      for (final q in queries) {
        final res = await LocalAssistantEngine.processQuery(q, clinicState: clinicState);
        expect(res.success, isFalse);
        expect(res.errorMessage, equals('Connection timed out on Supabase endpoint'));
        expect(res.text, contains('Database error: Connection timed out on Supabase endpoint'));
      }
    });

    test('29. Scenario 14: Ambiguous patient query asks user for patient identifier', () async {
      final ambiguousQueries = [
        "What is the patient's balance?",
        "Show patient appointments",
        "Tell me about the patient",
        "Does the patient have a follow up?",
      ];

      for (final q in ambiguousQueries) {
        final res = await LocalAssistantEngine.processQuery(q, clinicState: clinicState);
        expect(res.success, isTrue);
        expect(res.text, equals("Please specify the patient's name, ID, or phone number."));
      }
    });

    test('30. Scenario 15: Security-sensitive fields are never exposed in assistant output', () async {
      final queries = [
        "Patient summary for Aarav Sharma",
        "Aarav Sharma's appointments",
        "Aarav Sharma's balance",
        "Does Aarav Sharma have a follow-up?",
        "Search for Rahul",
      ];

      for (final q in queries) {
        final res = await LocalAssistantEngine.processQuery(q, clinicState: clinicState);
        final lower = res.text.toLowerCase();
        expect(lower.contains('password'), isFalse);
        expect(lower.contains('token'), isFalse);
        expect(lower.contains('secret'), isFalse);
        expect(lower.contains('auth_user'), isFalse);
        expect(lower.contains('embedding'), isFalse);
        expect(lower.contains('biometric'), isFalse);
        expect(lower.contains('pin'), isFalse);
      }
    });

    test('31. Scenario 16: Verification that all regression tests pass', () {
      expect(LocalAssistantEngine.parseIntent("What appointments do we have today?"), equals(AssistantIntent.todayAppointments));
      expect(LocalAssistantEngine.parseIntent("Who is available right now?"), equals(AssistantIntent.doctorAvailability));
      expect(LocalAssistantEngine.parseIntent("How much did we collect today?"), equals(AssistantIntent.todayRevenue));
      expect(LocalAssistantEngine.parseIntent("Show unpaid invoices"), equals(AssistantIntent.pendingInvoices));
      expect(LocalAssistantEngine.parseIntent("Give me a clinic summary"), equals(AssistantIntent.clinicSummary));
    });
  });

  group('Phase 5: Billing & Ledger Intelligence Tests', () {
    late ClinicState clinicState;

    setUp(() {
      clinicState = ClinicState();
      final now = DateTime.now();

      final p1 = Patient(
        id: 'P-501',
        name: 'Rahul Sharma',
        phone: '9876543210',
        email: 'rahul@example.com',
        dateOfBirth: '15 Jan 1990',
        age: '34',
        gender: 'Male',
        address: 'Pune',
        emergencyContact: 'Anita Sharma 9876543211',
        assignedDoctorId: 'DOC-1',
        assignedDoctorName: 'Dr. Priya Sharma',
        lastVisit: '10 Sep 2026',
        registrationDate: DateTime.now().subtract(const Duration(days: 30)),
        balanceDue: 2500.0,
      );
      final p2 = Patient(
        id: 'P-502',
        name: 'Pooja Patel',
        phone: '9123456789',
        email: 'pooja.p@example.com',
        dateOfBirth: '20 Mar 1996',
        age: '28',
        gender: 'Female',
        address: 'Pune',
        emergencyContact: 'Kishore Patel 9123456780',
        assignedDoctorId: 'DOC-1',
        assignedDoctorName: 'Dr. Priya Sharma',
        lastVisit: '15 Sep 2026',
        registrationDate: DateTime.now().subtract(const Duration(days: 15)),
        balanceDue: 1500.0,
      );
      final p3 = Patient(
        id: 'P-503',
        name: 'Pooja Roy',
        phone: '9988776655',
        email: 'pooja.r@example.com',
        dateOfBirth: '05 May 1984',
        age: '40',
        gender: 'Female',
        address: 'Pune',
        emergencyContact: 'Subhash Roy 9988776650',
        assignedDoctorId: 'DOC-1',
        assignedDoctorName: 'Dr. Priya Sharma',
        lastVisit: '20 Sep 2026',
        registrationDate: DateTime.now().subtract(const Duration(days: 10)),
        balanceDue: 3000.0,
      );
      clinicState.setPatientsForTesting([p1, p2, p3]);

      final invPaid = Invoice(
        id: 'INV-001',
        invoiceNumber: 'INV-2026-001',
        patientId: 'P-501',
        patientName: 'Rahul Sharma',
        patientPhone: '9876543210',
        doctorId: 'DOC-1',
        doctorName: 'Dr. Priya Sharma',
        date: now,
        items: const [
          InvoiceItem(description: 'Dental Consultation', quantity: 1, unitPrice: 500, amount: 500),
          InvoiceItem(description: 'Root Canal Treatment', quantity: 1, unitPrice: 3500, amount: 3500),
        ],
        subtotal: 4000.0,
        discount: 0.0,
        tax: 0.0,
        totalAmount: 4000.0,
        paidAmount: 4000.0,
        balanceAmount: 0.0,
        status: PaymentStatus.paid,
        paymentMethod: 'UPI',
        receiptNumber: 'REC-001',
      );

      final invPartial = Invoice(
        id: 'INV-002',
        invoiceNumber: 'INV-2026-002',
        patientId: 'P-501',
        patientName: 'Rahul Sharma',
        patientPhone: '9876543210',
        doctorId: 'DOC-2',
        doctorName: 'Dr. Amit Patel',
        date: now,
        items: const [
          InvoiceItem(description: 'Crown Placement', quantity: 1, unitPrice: 5000, amount: 5000),
        ],
        subtotal: 5000.0,
        discount: 0.0,
        tax: 0.0,
        totalAmount: 5000.0,
        paidAmount: 2500.0,
        balanceAmount: 2500.0,
        status: PaymentStatus.partial,
        paymentMethod: 'Cash',
        receiptNumber: 'REC-002',
      );

      final invPending = Invoice(
        id: 'INV-003',
        invoiceNumber: 'INV-2026-003',
        patientId: 'P-502',
        patientName: 'Pooja Patel',
        patientPhone: '9123456789',
        doctorId: 'DOC-1',
        doctorName: 'Dr. Priya Sharma',
        date: now,
        items: const [
          InvoiceItem(description: 'Teeth Whitening', quantity: 1, unitPrice: 1500, amount: 1500),
        ],
        subtotal: 1500.0,
        discount: 0.0,
        tax: 0.0,
        totalAmount: 1500.0,
        paidAmount: 0.0,
        balanceAmount: 1500.0,
        status: PaymentStatus.pending,
        paymentMethod: 'Unpaid',
      );

      final yesterday = now.subtract(const Duration(days: 1));
      final invYesterday = Invoice(
        id: 'INV-004',
        invoiceNumber: 'INV-2026-004',
        patientId: 'P-503',
        patientName: 'Pooja Roy',
        patientPhone: '9988776655',
        doctorId: 'DOC-1',
        doctorName: 'Dr. Priya Sharma',
        date: yesterday,
        items: const [
          InvoiceItem(description: 'Dental Filling', quantity: 2, unitPrice: 1500, amount: 3000),
        ],
        subtotal: 3000.0,
        discount: 0.0,
        tax: 0.0,
        totalAmount: 3000.0,
        paidAmount: 1000.0,
        balanceAmount: 2000.0,
        status: PaymentStatus.partial,
        paymentMethod: 'Card',
        receiptNumber: 'REC-004',
      );

      clinicState.setInvoicesForTesting([invPaid, invPartial, invPending, invYesterday]);

      final payRecord1 = PaymentRecord(
        id: 'PAY-001',
        invoiceId: 'INV-001',
        patientId: 'P-501',
        patientName: 'Rahul Sharma',
        amount: 4000.0,
        paymentMethod: 'UPI',
        receiptNumber: 'REC-001',
        paymentDate: now,
        createdAt: now,
      );
      final payRecord2 = PaymentRecord(
        id: 'PAY-002',
        invoiceId: 'INV-002',
        patientId: 'P-501',
        patientName: 'Rahul Sharma',
        amount: 2500.0,
        paymentMethod: 'Cash',
        receiptNumber: 'REC-002',
        paymentDate: now,
        createdAt: now,
      );
      clinicState.setPaymentRecordsForTesting([payRecord1, payRecord2]);
    });

    test('1. Today billing total answers with exact billed amount', () async {
      final res = await LocalAssistantEngine.processQuery("How much was billed today?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('₹${clinicState.todayBillingTotal.toStringAsFixed(0)}'));
      expect(res.text.toLowerCase(), contains('billing'));
    });

    test('2. Today collection total answers with exact collected amount', () async {
      final res = await LocalAssistantEngine.processQuery("How much did we collect today?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('₹${clinicState.todayCollectedTotal.toStringAsFixed(0)}'));
      expect(res.text.toLowerCase(), contains('collection'));
    });

    test('3. Pending payment total distinguishes balance vs total billed', () async {
      final res = await LocalAssistantEngine.processQuery("What payments are pending?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('₹6000')); // 2500 (partial) + 1500 (pending) + 2000 (yesterday partial) = 6000
    });

    test('4. Pending invoices lists unpaid and partial invoices only', () async {
      final res = await LocalAssistantEngine.processQuery("Show unpaid invoices", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('INV-2026-002'));
      expect(res.text, contains('INV-2026-003'));
      expect(res.text, contains('INV-2026-004'));
      expect(res.text.contains('INV-2026-001'), isFalse); // Fully settled invoice is excluded
    });

    test('5. Status handling correctly reflects paid, partial, and pending', () async {
      final res = await LocalAssistantEngine.processQuery("Show unpaid invoices", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('INV-2026-002'));
      expect(res.text, contains('Rahul Sharma'));
      expect(res.text, contains('₹2500'));
    });

    test('6. Patient billing lookup resolves Rahul Sharma and returns ledger', () async {
      final res = await LocalAssistantEngine.processQuery("Rahul Sharma's balance", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('Rahul Sharma'));
      expect(res.text, contains('₹2500'));
      expect(res.text, contains('INV-2026-002'));
    });

    test('7. Patient payment history retrieves payment records and ledger', () async {
      final res = await LocalAssistantEngine.processQuery("Payment history for Rahul Sharma", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('Rahul Sharma'));
      expect(res.text, contains('₹4000'));
      expect(res.text, contains('₹2500'));
      expect(res.text, contains('UPI'));
      expect(res.text, contains('Cash'));
      expect(res.text, contains('REC-001'));
      expect(res.text, contains('REC-002'));
    });

    test('8. Invoice details by ID/number returns line items and financial breakdown', () async {
      final res = await LocalAssistantEngine.processQuery("Details for invoice INV-2026-001", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('INV-2026-001'));
      expect(res.text, contains('Rahul Sharma'));
      expect(res.text, contains('Dr. Priya Sharma'));
      expect(res.text, contains('PAID'));
      expect(res.text, contains('Dental Consultation'));
      expect(res.text, contains('Root Canal Treatment'));
      expect(res.text, contains('₹4000'));
    });

    test('9. Today billing and collection summary provides complete breakdown', () async {
      final res = await LocalAssistantEngine.processQuery("Today's revenue summary", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('Total Billed Today: ₹${clinicState.todayBillingTotal.toStringAsFixed(0)}'));
      expect(res.text, contains('Total Collected Today: ₹${clinicState.todayCollectedTotal.toStringAsFixed(0)}'));
      expect(res.text, contains('Collection Rate: 55.6%'));
    });

    test('10. Collection-rate calculation computes accurate percentage', () async {
      final res = await LocalAssistantEngine.processQuery("What is our collection rate?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('55.6%'));
      expect(res.text, contains('₹7500'));
      expect(res.text, contains('₹13500'));
    });

    test('11. Zero-billing collection-rate handles division by zero safely', () async {
      final emptyState = ClinicState();
      emptyState.setInvoicesForTesting([]);
      final res = await LocalAssistantEngine.processQuery("What is our collection rate?", clinicState: emptyState);
      expect(res.success, isTrue);
      expect(res.text, contains('The collection rate cannot be calculated because there is no billing recorded'));
      expect(res.text.contains('NaN'), isFalse);
    });

    test('12. Yesterday billing retrieves deterministic yesterday summary', () async {
      final res = await LocalAssistantEngine.processQuery("How much was billed yesterday?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('Yesterday'));
      expect(res.text, contains('₹3000'));
      expect(res.text, contains('₹1000'));
    });

    test('13. This-week billing aggregates invoices for the current week', () async {
      final res = await LocalAssistantEngine.processQuery("Revenue this week", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text, contains('This Week'));
      expect(res.text, contains('Billing & Collections Summary'));
    });

    test('14. Empty billing dataset returns friendly settled/empty messages', () async {
      final emptyState = ClinicState();
      emptyState.setInvoicesForTesting([]);
      final resPending = await LocalAssistantEngine.processQuery("Show unpaid invoices", clinicState: emptyState);
      expect(resPending.success, isTrue);
      expect(resPending.text, contains('All accounts are settled'));

      final resRev = await LocalAssistantEngine.processQuery("Today's revenue", clinicState: emptyState);
      expect(resRev.success, isTrue);
      expect(resRev.text, contains('No invoices or billing transactions were recorded today'));
    });

    test('15. Database error propagates failure with exact error message', () async {
      clinicState.setRemoteErrorForTesting('Supabase connection timed out');
      final res = await LocalAssistantEngine.processQuery("How much was billed today?", clinicState: clinicState);
      expect(res.success, isFalse);
      expect(res.errorMessage, equals('Supabase connection timed out'));
      expect(res.text, contains('Database error: Supabase connection timed out'));
      clinicState.clearRemoteError();
    });

    test('16. Multiple patient disambiguation for billing queries', () async {
      final resBal = await LocalAssistantEngine.processQuery("What is Pooja's balance?", clinicState: clinicState);
      expect(resBal.success, isTrue);
      expect(resBal.text, contains('I found 2 patients matching "Pooja"'));
      expect(resBal.text, contains('Pooja Patel'));
      expect(resBal.text, contains('Pooja Roy'));
      expect(resBal.text, contains('Please specify the patient ID or phone number.'));

      final resPay = await LocalAssistantEngine.processQuery("Payment history for Pooja", clinicState: clinicState);
      expect(resPay.success, isTrue);
      expect(resPay.text, contains('I found 2 patients matching "Pooja"'));
      expect(resPay.text, contains('Pooja Patel'));
      expect(resPay.text, contains('Pooja Roy'));
    });

    test('17. No fabricated billing values or unrecorded tax fields', () async {
      final res = await LocalAssistantEngine.processQuery("Details for invoice INV-2026-002", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.text.toLowerCase().contains('gst'), isFalse);
      expect(res.text, contains('Crown Placement'));
      expect(res.text, contains('₹5000'));
      expect(res.text, contains('₹2500'));
    });

    test('18. Strictly read-only: queries do not mutate clinicState', () async {
      final initialCount = clinicState.invoices.length;
      final initialPaymentsCount = clinicState.paymentRecords.length;
      final initialBalance = clinicState.invoices.first.balanceAmount;

      await LocalAssistantEngine.processQuery("Details for invoice INV-2026-001", clinicState: clinicState);
      await LocalAssistantEngine.processQuery("How much was billed today?", clinicState: clinicState);
      await LocalAssistantEngine.processQuery("What is Rahul Sharma's balance?", clinicState: clinicState);
      await LocalAssistantEngine.processQuery("Payment history for Rahul Sharma", clinicState: clinicState);

      expect(clinicState.invoices.length, equals(initialCount));
      expect(clinicState.paymentRecords.length, equals(initialPaymentsCount));
      expect(clinicState.invoices.first.balanceAmount, equals(initialBalance));
    });

    test('19. Backward compatibility: Phase 1-4 intents continue to work perfectly', () async {
      expect(LocalAssistantEngine.parseIntent("What appointments do we have today?"), equals(AssistantIntent.todayAppointments));
      expect(LocalAssistantEngine.parseIntent("Who is available right now?"), equals(AssistantIntent.doctorAvailability));
      expect(LocalAssistantEngine.parseIntent("Search patient Rahul"), equals(AssistantIntent.patientSearch));
      expect(LocalAssistantEngine.parseIntent("Tell me about Rahul Sharma"), equals(AssistantIntent.patientSummary));
      expect(LocalAssistantEngine.parseIntent("Rahul Sharma's appointments"), equals(AssistantIntent.patientAppointments));
      expect(LocalAssistantEngine.parseIntent("Give me a clinic summary"), equals(AssistantIntent.clinicSummary));
    });
  });

  group('Phase 6: Local Dental Knowledge Base Integration Tests', () {
    late ClinicState clinicState;

    setUp(() {
      clinicState = ClinicState();
    });

    test('1. Dental knowledge intent parsing and topic response', () async {
      final res = await LocalAssistantEngine.processQuery("What is plaque?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.dentalKnowledge));
      expect(res.text, contains('Dental Plaque'));
      expect(res.text, contains('film of bacteria'));
    });

    test('2. Medical diagnosis guard prevents diagnosing patient', () async {
      final res = await LocalAssistantEngine.processQuery("Does Rahul have gingivitis?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.dentalKnowledge));
      expect(res.text, contains('I cannot diagnose Rahul'));
      expect(res.text, contains('qualified dentist'));
    });

    test('3. Dental knowledge works during database errors', () async {
      clinicState.setRemoteErrorForTesting('Supabase unavailable');
      final res = await LocalAssistantEngine.processQuery("Why do dentists take X-rays?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.dentalKnowledge));
      expect(res.text, contains('Dental Radiographs (X-rays)'));
      clinicState.clearRemoteError();
    });

    test('4. Unsupported dental topic returns educational guidance without hallucination', () async {
      final res = await LocalAssistantEngine.processQuery("Explain wisdom teeth extraction", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.dentalKnowledge));
      expect(res.text, contains("I don't have a verified local knowledge entry for that dental topic yet"));
    });
  });
}
