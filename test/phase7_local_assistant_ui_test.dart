import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/models/appointment.dart';
import 'package:dental_clinic_app/models/billing.dart';
import 'package:dental_clinic_app/models/patient.dart';
import 'package:dental_clinic_app/services/ai/ai_chat_service.dart';
import 'package:dental_clinic_app/state/clinic_scope.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/widgets/chat/ai_chat_panel.dart';

void main() {
  group('Phase 7: AI Assistant UI & Service Connection to LocalAssistantEngine', () {
    late AiChatService service;
    late ClinicState clinicState;

    setUp(() {
      service = AiChatService.instance;
      service.useLocalAssistant = true;
      service.config.update(apiKey: '', baseUrl: 'https://api.openai.com/v1', useProxy: false);
      clinicState = ClinicState();
      service.clearConversation();
    });

    test('1. User message reaches LocalAssistantEngine and is recorded in conversation', () async {
      await service.sendMessage('What is plaque?', clinicState: clinicState);

      expect(service.messages.length, equals(3)); // Initial welcome + user + assistant
      expect(service.messages[1].isUser, isTrue);
      expect(service.messages[1].content, equals('What is plaque?'));
      expect(service.messages[2].isAssistant, isTrue);
      expect(service.messages[2].content, contains('Dental plaque is a soft, sticky'));
    });

    test('2. Successful clinic query produces real assistant message with live clinic data', () async {
      clinicState.setAppointmentsForTesting([
        Appointment(
          id: 'apt-phase7-1',
          patientId: 'P-1001',
          patientName: 'Kavita Verma',
          patientPhone: '9876543210',
          doctorId: 'DOC-01',
          doctorName: 'Dr. John Doe',
          dateTime: DateTime.now(),
          timeString: '10:00 AM',
          appointmentType: 'Root Canal Treatment',
          status: AppointmentStatus.scheduled,
          tokenNumber: '1',
        ),
      ]);

      await service.sendMessage('What appointments do we have today?', clinicState: clinicState);

      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.content, contains('Kavita Verma'));
      expect(lastMsg.content, contains('Root Canal Treatment'));
    });

    test('3. Dental knowledge query works offline and produces educational response', () async {
      await service.sendMessage('What is a root canal?', clinicState: clinicState);

      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.content, contains('Root Canal Treatment'));
      expect(lastMsg.content, contains('relieve pain and save a severely infected'));
    });

    test('4. Billing query works and aggregates real clinic invoice data', () async {
      clinicState.setInvoicesForTesting([
        Invoice(
          id: 'inv-p7-01',
          invoiceNumber: 'INV-2026-0042',
          patientId: 'P-101',
          patientName: 'Sanjay Dutt',
          patientPhone: '9876543210',
          doctorId: 'DOC-01',
          doctorName: 'Dr. John Doe',
          subtotal: 5000.0,
          totalAmount: 5000.0,
          paidAmount: 2000.0,
          balanceAmount: 3000.0,
          status: PaymentStatus.partial,
          paymentMethod: 'Cash',
          items: const [
            InvoiceItem(description: 'Crown Placement', unitPrice: 5000.0, quantity: 1, amount: 5000.0),
          ],
          date: DateTime.now(),
        ),
      ]);

      await service.sendMessage('What invoices are pending?', clinicState: clinicState);

      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.content, contains('INV-2026-0042'));
      expect(lastMsg.content, contains('Sanjay Dutt'));
      expect(lastMsg.content.contains('3,000') || lastMsg.content.contains('3000'), isTrue);
    });

    test('5. Patient query works and searches registered patients safely', () async {
      clinicState.setPatientsForTesting([
        Patient(
          id: 'P-p7-rahul',
          name: 'Rahul Sharma',
          phone: '+91 98765 43210',
          email: 'rahul.sharma@example.com',
          dateOfBirth: '14 May 1994',
          age: '32',
          gender: 'Male',
          address: 'Mumbai',
          emergencyContact: 'Sunita Sharma 9876543219',
          assignedDoctorId: 'DOC-01',
          assignedDoctorName: 'Dr. John Doe',
          lastVisit: '10 Sep 2026',
          registrationDate: DateTime(2025, 1, 1),
          bloodGroup: 'O+',
          medicalAlerts: const ['Hypertension'],
          allergies: const ['Penicillin'],
        ),
      ]);

      await service.sendMessage('Find Rahul Sharma', clinicState: clinicState);

      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.content, contains('Rahul Sharma'));
      expect(lastMsg.content, contains('98765 43210'));
    });

    test('6. Database error is displayed honestly without masking or fake results', () async {
      clinicState.setRemoteErrorForTesting('Supabase connection timed out (HTTP 504)');

      await service.sendMessage('What appointments do we have today?', clinicState: clinicState);

      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isTrue);
      expect(lastMsg.content, contains('Database error: Supabase connection timed out (HTTP 504)'));
      expect(lastMsg.errorMessage, equals('Supabase connection timed out (HTTP 504)'));
    });

    test('7. Dental knowledge query still works even when database has an error', () async {
      clinicState.setRemoteErrorForTesting('PostgreSQL fatal connection drop');

      await service.sendMessage('What is plaque?', clinicState: clinicState);

      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.content, contains('Dental plaque is a soft, sticky'));
    });

    test('8. Unsupported query is handled gracefully with clear assistant guidance', () async {
      await service.sendMessage('Can you order lunch for the clinic?', clinicState: clinicState);

      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.content, contains('I can currently help with appointments'));
      expect(lastMsg.content, contains('Please let me know what clinic information you need.'));
    });

    test('9. Diagnosis guard is preserved for patient condition questions', () async {
      clinicState.setPatientsForTesting([
        Patient(
          id: 'P-p7-rahul-2',
          name: 'Rahul Sharma',
          phone: '+91 98765 43210',
          email: 'rahul@example.com',
          dateOfBirth: '14 May 1994',
          age: '30',
          gender: 'Male',
          address: 'Mumbai',
          emergencyContact: 'Sunita Sharma 9876543219',
          assignedDoctorId: 'DOC-01',
          assignedDoctorName: 'Dr. John Doe',
          lastVisit: '10 Sep 2026',
          registrationDate: DateTime(2025, 1, 1),
        ),
      ]);

      await service.sendMessage('Does Rahul have gingivitis?', clinicState: clinicState);

      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.content, contains('I cannot diagnose Rahul'));
      expect(lastMsg.content, contains('Clinical diagnosis requires an in-person physical examination'));
    });

    test('10. No API key is required and no external HTTP requests are needed', () async {
      service.config.update(apiKey: '', baseUrl: 'http://invalid-external-url.local', useProxy: false);
      expect(service.config.apiKey, isEmpty);
      expect(service.config.isConfigured, isFalse);
      expect(service.isReady, isTrue);

      await service.sendMessage("What is today's billing total?", clinicState: clinicState);

      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.content, contains("Today's total billing is"));
    });

    test('11. Chat conversation history preserves sequential flow across queries', () async {
      await service.sendMessage('What is plaque?', clinicState: clinicState);
      await service.sendMessage('How often should I brush?', clinicState: clinicState);

      // Initial welcome + (user + ai) * 2 = 5 messages
      expect(service.messages.length, equals(5));
      expect(service.messages[1].content, equals('What is plaque?'));
      expect(service.messages[2].content, contains('Dental plaque is a soft, sticky'));
      expect(service.messages[3].content, equals('How often should I brush?'));
      expect(service.messages[4].content, contains('brushing'));
    });

    test('12. Empty or whitespace-only inputs are ignored safely', () async {
      final initialCount = service.messages.length;

      await service.sendMessage('', clinicState: clinicState);
      await service.sendMessage('   ', clinicState: clinicState);

      expect(service.messages.length, equals(initialCount));
    });

    test('13. Duplicate send protection prevents concurrent execution', () async {
      // Simulate loading state
      expect(service.isLoading, isFalse);

      // Start first query
      final future1 = service.sendMessage('What is plaque?', clinicState: clinicState);
      // Attempt second query while first is in flight
      final future2 = service.sendMessage('What is gingivitis?', clinicState: clinicState);

      await Future.wait([future1, future2]);

      // Exactly one user message was processed
      final userMessages = service.messages.where((m) => m.isUser).toList();
      expect(userMessages.length, equals(1));
      expect(userMessages.first.content, equals('What is plaque?'));
    });

    test('14. Loading state is accurately set during processing and cleared after success', () async {
      expect(service.isLoading, isFalse);

      final future = service.sendMessage('What is gingivitis?', clinicState: clinicState);
      expect(service.isLoading, isTrue);

      await future;
      expect(service.isLoading, isFalse);
    });

    test('15. Loading state is cleared after failure and retry succeeds', () async {
      clinicState.setRemoteErrorForTesting('Temporary network drop');

      final future = service.sendMessage('What appointments do we have today?', clinicState: clinicState);
      expect(service.isLoading, isTrue);

      await future;
      expect(service.isLoading, isFalse);
      expect(service.messages.last.isError, isTrue);

      // Clear the error and retry
      clinicState.setRemoteErrorForTesting(null);
      await service.retryLastMessage(clinicState);

      expect(service.isLoading, isFalse);
      expect(service.messages.last.isError, isFalse);
      expect(service.messages.last.content, contains('appointment'));
    });
  });

  group('Phase 7: AI Chatbot UI Widget Integration Tests', () {
    testWidgets('AiChatPanel does NOT display unconfigured banner when local assistant is active', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = AiChatService.instance;
      service.useLocalAssistant = true;
      service.config.update(apiKey: '', useProxy: false);
      service.clearConversation();

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('AI API key is not configured yet.'), findsNothing);
      expect(find.text('Configure Now'), findsNothing);
      expect(find.text('SmileCare AI Assistant'), findsOneWidget);
    });

    testWidgets('AiChatPanel user typing and send triggers real LocalAssistantEngine response', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = AiChatService.instance;
      service.useLocalAssistant = true;
      service.config.update(apiKey: '', useProxy: false);
      service.clearConversation();

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
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

      // Enter question in textfield
      final input = find.byType(TextField);
      expect(input, findsOneWidget);
      await tester.enterText(input, 'What is plaque?');
      await tester.pump();

      // Tap Send button
      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the user bubble and the assistant bubble with real local dental knowledge are displayed
      expect(find.text('What is plaque?'), findsOneWidget);
      expect(find.textContaining('Dental plaque is a soft, sticky'), findsOneWidget);
    });

    testWidgets('AiChatPanel starter chip tap sends query and displays answer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = AiChatService.instance;
      service.useLocalAssistant = true;
      service.config.update(apiKey: '', useProxy: false);
      service.clearConversation();

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
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

      final chip = find.text("Show today's appointments");
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text("Show today's appointments"), findsWidgets); // In chip + in user message bubble
      expect(find.textContaining('appointment'), findsWidgets);
    });

    testWidgets('AiChatBubble displays honest database error and provides Retry Message button', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = AiChatService.instance;
      service.useLocalAssistant = true;
      service.config.update(apiKey: '', useProxy: false);
      service.clearConversation();

      final clinic = ClinicState();
      clinic.setRemoteErrorForTesting('Database offline: Host unreachable');

      await tester.pumpWidget(
        ClinicScope(
          state: clinic,
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
      await tester.enterText(input, "What is today's billing total?");
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Error bubble is shown with honest database error message and retry button
      expect(find.textContaining('Database error: Database offline: Host unreachable'), findsOneWidget);
      expect(find.text('Retry Message'), findsOneWidget);
    });
  });
}
