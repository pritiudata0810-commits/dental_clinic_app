import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/services/ai/local_assistant_engine.dart';
import 'package:dental_clinic_app/services/ai/clinic_tools_registry.dart';
import 'package:dental_clinic_app/services/ai/ai_chat_service.dart';
import 'package:dental_clinic_app/state/clinic_scope.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/widgets/chat/ai_chat_panel.dart';
import 'package:dental_clinic_app/models/patient.dart';
import 'package:dental_clinic_app/models/appointment.dart';
import 'package:dental_clinic_app/models/billing.dart';
import 'package:dental_clinic_app/models/tooth_record.dart';

void main() {
  group('Domain-Specific Error Isolation & Availability Tests', () {
    late ClinicState clinicState;

    setUp(() {
      clinicState = ClinicState();
      // Populate test clinic state
      final testPatient = Patient(
        id: 'P-1001',
        name: 'Rahul Sharma',
        phone: '9876543210',
        email: 'rahul.sharma@example.com',
        dateOfBirth: '15 May 1992',
        age: '32',
        gender: 'Male',
        address: '123 Park Street',
        emergencyContact: '9876543211',
        registrationDate: DateTime.now().subtract(const Duration(days: 30)),
        lastVisit: '2026-09-20',
        assignedDoctorId: 'DOC-1',
        assignedDoctorName: 'Dr. John Doe',
        notes: 'Regular checkup',
        totalVisits: 2,
        balanceDue: 0.0,
      );
      clinicState.setPatientsForTesting([testPatient]);

      final testAppointment = Appointment(
        id: 'APT-101',
        patientId: 'P-1001',
        patientName: 'Rahul Sharma',
        patientPhone: '9876543210',
        doctorId: 'DOC-1',
        doctorName: 'Dr. John Doe',
        dateTime: DateTime.now(),
        timeString: '10:00 AM',
        status: AppointmentStatus.confirmed,
        appointmentType: 'Cleaning',
        tokenNumber: '1',
      );
      clinicState.setAppointmentsForTesting([testAppointment]);

      final testInvoice = Invoice(
        id: 'INV-101',
        invoiceNumber: 'INV-2026-0001',
        patientId: 'P-1001',
        patientName: 'Rahul Sharma',
        patientPhone: '9876543210',
        doctorId: 'DOC-1',
        doctorName: 'Dr. John Doe',
        date: DateTime.now(),
        items: const [],
        subtotal: 1500.0,
        totalAmount: 1500.0,
        paidAmount: 1500.0,
        balanceAmount: 0.0,
        status: PaymentStatus.paid,
        paymentMethod: 'Cash',
      );
      clinicState.setInvoicesForTesting([testInvoice]);
    });

    test('Scenario A: Tooth Records fails while appointments, patients, and billing remain valid', () async {
      // Simulate Tooth Records domain error only
      clinicState.setDomainErrorForTesting('Tooth Records', 'Failed to load live data from Supabase: Tooth Records');

      expect(clinicState.toothRecordsError, isNotNull);
      expect(clinicState.appointmentsError, isNull);
      expect(clinicState.patientsError, isNull);
      expect(clinicState.billingError, isNull);
      expect(clinicState.paymentsError, isNull);

      // 1. Appointments must succeed
      final aptRes = await LocalAssistantEngine.processQuery(
        'What appointments do we have today?',
        clinicState: clinicState,
      );
      expect(aptRes.success, isTrue);
      expect(aptRes.text, contains('Rahul Sharma'));
      expect(aptRes.text, isNot(contains('Database error')));

      // 2. Patient search must succeed
      final patRes = await LocalAssistantEngine.processQuery(
        'Find Rahul Sharma',
        clinicState: clinicState,
      );
      expect(patRes.success, isTrue);
      expect(patRes.text, contains('Rahul Sharma'));
      expect(patRes.text, contains('P-1001'));
      expect(patRes.text, isNot(contains('Database error')));

      // 3. Billing query must succeed
      final billRes = await LocalAssistantEngine.processQuery(
        "What is today's billing total?",
        clinicState: clinicState,
      );
      expect(billRes.success, isTrue);
      expect(billRes.text, contains('₹1500'));
      expect(billRes.text, isNot(contains('Database error')));

      // 4. Dental Knowledge must succeed (offline)
      final knowRes = await LocalAssistantEngine.processQuery(
        'What is plaque?',
        clinicState: clinicState,
      );
      expect(knowRes.success, isTrue);
      expect(knowRes.intent, equals(AssistantIntent.dentalKnowledge));
      expect(knowRes.text, contains('Plaque'));
      expect(knowRes.text, isNot(contains('Database error')));

      // 5. Tooth records question must return honest domain-specific error
      final toothRes = await LocalAssistantEngine.processQuery(
        "Show Rahul's tooth records",
        clinicState: clinicState,
      );
      expect(toothRes.success, isFalse);
      expect(toothRes.intent, equals(AssistantIntent.patientToothRecords));
      expect(
        toothRes.text,
        equals("I can't retrieve tooth records right now because the Tooth Records database is unavailable."),
      );
    });

    test('Scenario B: Supabase is completely unavailable (global connection drop)', () async {
      // Simulate global connection outage
      clinicState.setRemoteErrorForTesting('Supabase connection lost');

      expect(clinicState.appointmentsError, equals('Supabase connection lost'));
      expect(clinicState.patientsError, equals('Supabase connection lost'));

      // 1. Local Dental knowledge must STILL succeed completely offline
      final knowRes = await LocalAssistantEngine.processQuery(
        'What is plaque?',
        clinicState: clinicState,
      );
      expect(knowRes.success, isTrue);
      expect(knowRes.intent, equals(AssistantIntent.dentalKnowledge));
      expect(knowRes.text, contains('Plaque'));

      // 2. Root canal education query must also succeed offline
      final rootCanalRes = await LocalAssistantEngine.processQuery(
        'What is a root canal?',
        clinicState: clinicState,
      );
      expect(rootCanalRes.success, isTrue);
      expect(rootCanalRes.intent, equals(AssistantIntent.dentalKnowledge));

      // 3. Clinic queries must report honest database connection error without fabricating data
      final aptRes = await LocalAssistantEngine.processQuery(
        'What appointments are today?',
        clinicState: clinicState,
      );
      expect(aptRes.success, isFalse);
      expect(aptRes.text, contains('Database error: Supabase connection lost'));
    });

    test('Scenario C: Empty Tooth Records table is VALID and produces no error', () async {
      // Normal state with 0 tooth records
      clinicState.clearRemoteError();
      clinicState.setToothRecordsForTesting([]);
      expect(clinicState.toothRecordsError, isNull);

      final toothRes = await LocalAssistantEngine.processQuery(
        "Show Rahul's tooth records",
        clinicState: clinicState,
      );
      expect(toothRes.success, isTrue);
      expect(toothRes.intent, equals(AssistantIntent.patientToothRecords));
      expect(toothRes.text, contains('Rahul Sharma (ID: P-1001) has no recorded tooth treatments'));
    });

    test('Scenario D: All clinic data available returns tooth records accurately', () async {
      clinicState.clearRemoteError();

      // Add actual tooth record for Rahul
      final toothRecord = ToothRecord(
        id: 'TR-101',
        patientId: 'P-1001',
        toothNumber: 36,
        status: ToothStatus.filling,
        procedure: 'Composite Restoration',
        clinicalFinding: 'Class I Occlusal Caries',
        treatmentDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      clinicState.setToothRecordsForTesting([toothRecord]);

      final toothRes = await LocalAssistantEngine.processQuery(
        "Show Rahul's tooth records",
        clinicState: clinicState,
      );
      expect(toothRes.success, isTrue);
      expect(toothRes.intent, equals(AssistantIntent.patientToothRecords));
      expect(toothRes.text, contains('Tooth #36'));
      expect(toothRes.text, contains('Composite Restoration'));
    });

    test('ClinicToolsRegistry: Tools are isolated by domain and not blocked by Tooth Records failure', () async {
      clinicState.setDomainErrorForTesting('Tooth Records', 'Tooth Records failed');

      // getTodaysAppointments should succeed through ClinicToolsRegistry
      final aptRaw = await ClinicToolsRegistry.executeTool(
        toolName: 'getTodaysAppointments',
        arguments: {},
        clinicState: clinicState,
      );
      expect(aptRaw, isNot(contains('"error"')));
      expect(aptRaw, contains('Rahul Sharma'));

      // searchPatients should succeed
      final patRaw = await ClinicToolsRegistry.executeTool(
        toolName: 'searchPatients',
        arguments: {'query': 'Rahul'},
        clinicState: clinicState,
      );
      expect(patRaw, isNot(contains('"error"')));
      expect(patRaw, contains('Rahul Sharma'));
    });

    testWidgets('UI Test: AiChatPanel allows unrelated queries when Tooth Records has failed', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = AiChatService.instance;
      service.useLocalAssistant = true;
      service.clearConversation();

      // Tooth Records domain failed
      clinicState.setDomainErrorForTesting('Tooth Records', 'Failed to load live data from Supabase: Tooth Records');

      await tester.pumpWidget(
        ClinicScope(
          state: clinicState,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: AiChatPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final input = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send_rounded);

      // 1. What is plaque?
      await tester.enterText(input, 'What is plaque?');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Dental plaque is a soft, sticky'), findsOneWidget);

      // 2. What appointments do we have today?
      await tester.enterText(input, 'What appointments do we have today?');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Rahul Sharma with Dr. John Doe'), findsOneWidget);

      // 3. What is today's billing total?
      await tester.enterText(input, "What is today's billing total?");
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(find.textContaining("Today's total billing is ₹1500"), findsOneWidget);

      // 4. Find Rahul Sharma
      await tester.enterText(input, 'Find Rahul Sharma');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Rahul Sharma (ID: P-1001)'), findsOneWidget);

      // 5. What is a root canal?
      await tester.enterText(input, 'What is a root canal?');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Root Canal Treatment'), findsOneWidget);

      // 6. Show Rahul's tooth records -> reports honest tooth records error only
      await tester.enterText(input, "Show Rahul's tooth records");
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(find.textContaining("I can't retrieve tooth records right now because the Tooth Records database is unavailable."), findsOneWidget);
    });
  });
}
