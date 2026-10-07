import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/models/ai_chat_message.dart';
import 'package:dental_clinic_app/services/ai/ai_config.dart';
import 'package:dental_clinic_app/services/ai/ai_chat_service.dart';
import 'package:dental_clinic_app/services/ai/ai_system_prompts.dart';
import 'package:dental_clinic_app/services/ai/clinic_tools_registry.dart';
import 'package:dental_clinic_app/state/clinic_scope.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/widgets/chat/ai_chat_panel.dart';
import 'package:dental_clinic_app/widgets/chat/ai_floating_button.dart';
import 'package:dental_clinic_app/widgets/chat/ai_config_dialog.dart';

void main() {
  group('AI Chatbot Config & State Unit Tests', () {
    test('AiConfig detects unconfigured state by default when API key is empty', () {
      final config = AiConfig();
      config.update(apiKey: '', baseUrl: 'https://api.openai.com/v1', model: 'gpt-4o-mini', useProxy: false);
      expect(config.isConfigured, isFalse);
    });

    test('AiConfig becomes configured when API key or proxy is provided', () {
      final config = AiConfig();
      config.update(apiKey: 'sk-test-key-12345');
      expect(config.isConfigured, isTrue);
      expect(config.providerDisplayName, contains('OpenAI'));

      config.update(apiKey: '', useProxy: true, proxyUrl: 'http://localhost:3000/api/chat');
      expect(config.isConfigured, isTrue);
      expect(config.providerDisplayName, contains('Proxy'));
    });
  });

  group('Clinic Tools Registry & Ground Truth Unit Tests', () {
    late ClinicState clinicState;

    setUp(() {
      clinicState = ClinicState();
    });

    test('getTodaysAppointments returns actual appointments from clinic state', () async {
      final jsonStr = await ClinicToolsRegistry.executeTool(
        toolName: 'getTodaysAppointments',
        arguments: {},
        clinicState: clinicState,
      );

      final result = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(result.containsKey('appointments'), isTrue);
      expect(result['totalAppointmentsToday'], equals(clinicState.todayAppointments.length));
    });

    test('searchPatients queries real registered patients and returns safe fields only', () async {
      final jsonStr = await ClinicToolsRegistry.executeTool(
        toolName: 'searchPatients',
        arguments: {'query': 'Rahul'},
        clinicState: clinicState,
      );

      final result = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(result.containsKey('patients'), isTrue);
      final patientsList = result['patients'] as List<dynamic>;
      if (patientsList.isNotEmpty) {
        final p = patientsList.first as Map<String, dynamic>;
        expect(p['name'], contains('Rahul'));
        // Verify privacy safety: no passwords or biometric data
        expect(p.containsKey('password'), isFalse);
        expect(p.containsKey('biometricVector'), isFalse);
      }
    });

    test('getDoctorAvailability returns availability statuses', () async {
      final jsonStr = await ClinicToolsRegistry.executeTool(
        toolName: 'getDoctorAvailability',
        arguments: {},
        clinicState: clinicState,
      );

      final result = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(result.containsKey('doctors'), isTrue);
      expect(result['totalAvailable'], greaterThanOrEqualTo(0));
    });

    test('getPendingPayments accurately calculates outstanding clinic balances', () async {
      final jsonStr = await ClinicToolsRegistry.executeTool(
        toolName: 'getPendingPayments',
        arguments: {},
        clinicState: clinicState,
      );

      final result = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(result.containsKey('invoices'), isTrue);
      expect(result['currency'], contains('INR'));
    });

    test('getClinicSummary aggregates operational statistics', () async {
      final jsonStr = await ClinicToolsRegistry.executeTool(
        toolName: 'getClinicSummary',
        arguments: {},
        clinicState: clinicState,
      );

      final result = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(result['totalAppointmentsToday'], equals(clinicState.todayAppointments.length));
      expect(result['waitingRoomQueue'], equals(clinicState.waitingRoomCount));
      expect(result['availableDoctorsCount'], equals(clinicState.availableDoctorsCount));
    });
  });

  group('AI System Prompts & Roles Unit Tests', () {
    late ClinicState clinicState;

    setUp(() {
      clinicState = ClinicState();
    });

    test('Receptionist system prompt instructs tool usage and injects live grounding', () {
      final prompt = AiSystemPrompts.getSystemPrompt(AiRoleMode.receptionist, clinicState);
      expect(prompt, contains('SmileCare Dental Clinic Receptionist AI Assistant'));
      expect(prompt, contains('NEVER INVENT OR GUESS CLINIC DATA'));
      expect(prompt, contains('LIVE GROUND-TRUTH CLINIC DATA'));
    });

    test('Patient system prompt contains medical safety non-diagnostic disclaimer', () {
      final prompt = AiSystemPrompts.getSystemPrompt(AiRoleMode.patient, clinicState);
      expect(prompt, contains('SmileCare Dental Patient Health & Care Advisor'));
      expect(prompt, contains('YOU ARE NOT A DENTIST'));
      expect(prompt, contains('DENTAL EMERGENCIES'));
    });

    test('Dentist system prompt supports clinical documentation & SOAP notes', () {
      final prompt = AiSystemPrompts.getSystemPrompt(AiRoleMode.dentist, clinicState);
      expect(prompt, contains('SmileCare Clinical Dentist Copilot'));
      expect(prompt, contains('SOAP'));
    });
  });

  group('AiChatService Workflow & Safety Tests', () {
    late AiChatService service;
    late ClinicState clinicState;

    setUp(() {
      service = AiChatService.instance;
      service.useLocalAssistant = true;
      clinicState = ClinicState();
      service.clearConversation();
    });

    test('Initial conversation contains role welcome greeting', () {
      expect(service.messages.length, equals(1));
      expect(service.messages.first.isAssistant, isTrue);
      expect(service.messages.first.content, contains('SmileCare'));
    });

    test('Unconfigured remote AI service (when local engine disabled) rejects fake responses and displays configuration message', () async {
      service.useLocalAssistant = false;
      // Ensure API key is empty
      service.config.update(apiKey: '', useProxy: false);
      expect(service.isConfigured, isFalse);

      await service.sendMessage('How many appointments today?', clinicState: clinicState);

      // Verify user message was recorded
      expect(service.messages.any((m) => m.isUser && m.content == 'How many appointments today?'), isTrue);

      // Verify unconfigured error message is displayed (NO fake answer returned)
      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isTrue);
      expect(lastMsg.content, contains('not configured yet'));
    });

    test('Active chat uses LocalAssistantEngine without API key', () async {
      // Ensure API key is empty
      service.config.update(apiKey: '', useProxy: false);
      expect(service.useLocalAssistant, isTrue);

      await service.sendMessage('How many appointments today?', clinicState: clinicState);

      expect(service.messages.any((m) => m.isUser && m.content == 'How many appointments today?'), isTrue);
      final lastMsg = service.messages.last;
      expect(lastMsg.isAssistant, isTrue);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.content, contains('appointment'));
      expect(lastMsg.content, contains('today'));
    });

    test('Switching roles updates greeting and resets conversation memory', () {
      service.setRole(AiRoleMode.patient);
      expect(service.activeRole, equals(AiRoleMode.patient));
      expect(service.messages.first.content, contains('SmileCare Dental Assistant'));

      service.setRole(AiRoleMode.receptionist);
      expect(service.activeRole, equals(AiRoleMode.receptionist));
      expect(service.messages.first.content, contains('Front-Desk'));
    });
  });

  group('AI Chatbot Widget & UI Tests', () {
    testWidgets('AiChatPanel renders header, starter prompts, and input section', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('SmileCare AI Assistant'), findsOneWidget);
      expect(find.text('Receptionist Assistant'), findsOneWidget);
      expect(find.text("Show today's appointments"), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AiFloatingChatbot toggles panel on click', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: Scaffold(
              body: AiFloatingChatbot(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final trigger = find.text('Ask AI Assistant');
      expect(trigger, findsOneWidget);

      // Tap trigger to open
      await tester.tap(trigger);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AiChatPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AiConfigDialog renders preset buttons and API configuration inputs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: Scaffold(
              body: AiConfigDialog(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('AI Assistant Configuration'), findsOneWidget);
      expect(find.text('OpenAI (gpt-4o-mini)'), findsOneWidget);
      expect(find.text('Groq Cloud (Fast)'), findsOneWidget);
      expect(find.text('API Key'), findsOneWidget);
      expect(find.text('Save & Apply'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
