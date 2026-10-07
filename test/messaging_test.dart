import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dental_clinic_app/services/telephony/phone_number_util.dart';
import 'package:dental_clinic_app/services/telephony/messaging_service.dart';
import 'package:dental_clinic_app/widgets/communication/quick_comm_dialogs.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/state/clinic_scope.dart';

void main() {
  group('Phone Number Normalization for WhatsApp & SMS', () {
    test('10-digit Indian mobile is normalized to 91XXXXXXXXXX for WhatsApp', () {
      final formatted = PhoneNumberUtil.formatForWhatsApp('9876543210');
      expect(formatted, '919876543210');
    });

    test('+91 prefixed Indian mobile has + stripped for WhatsApp', () {
      final formatted = PhoneNumberUtil.formatForWhatsApp('+919876543210');
      expect(formatted, '919876543210');
    });

    test('0-prefixed Indian mobile trunk is normalized for WhatsApp', () {
      final formatted = PhoneNumberUtil.formatForWhatsApp('09876543210');
      expect(formatted, '919876543210');
    });

    test('91-prefixed Indian mobile without plus is normalized for WhatsApp', () {
      final formatted = PhoneNumberUtil.formatForWhatsApp('919876543210');
      expect(formatted, '919876543210');
    });

    test('Valid international number strips + for WhatsApp wa.me link', () {
      final formatted = PhoneNumberUtil.formatForWhatsApp('+14155552671');
      expect(formatted, '14155552671');
    });

    test('Invalid phone number returns null for formatForWhatsApp', () {
      expect(PhoneNumberUtil.formatForWhatsApp('12345'), isNull);
      expect(PhoneNumberUtil.formatForWhatsApp(''), isNull);
      expect(PhoneNumberUtil.formatForWhatsApp(null), isNull);
      expect(PhoneNumberUtil.formatForWhatsApp('abcdefghij'), isNull);
    });
  });

  group('MessagingService Unit Tests', () {
    final service = MessagingService.instance;

    tearDown(() {
      service.resetLauncherOverrides();
    });

    test('buildWhatsAppUri creates correct wa.me URI with percent-encoded text', () {
      final uri = MessagingService.buildWhatsAppUri('919876543210', 'Hello Dr. Rahul! Your appointment is ready.');
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919876543210');
      expect(uri.queryParameters['text'], 'Hello Dr. Rahul! Your appointment is ready.');
      expect(uri.toString(), contains('https://wa.me/919876543210?text='));
    });

    test('buildSmsUri creates standard sms: URI with body parameter', () {
      final uri = MessagingService.buildSmsUri('+919876543210', 'Dental appointment reminder');
      expect(uri.scheme, 'sms');
      expect(uri.path, '+919876543210');
      expect(uri.queryParameters['body'], 'Dental appointment reminder');
    });

    test('openWhatsApp succeeds when launcher succeeds and reports WhatsApp opened (never message sent)', () async {
      Uri? capturedUri;
      LaunchMode? capturedMode;

      service.setLauncherOverrides(
        canLaunch: (uri) async => true,
        launcher: (uri, {mode = LaunchMode.platformDefault}) async {
          capturedUri = uri;
          capturedMode = mode;
          return true;
        },
      );

      final result = await service.openWhatsApp(
        rawPhoneNumber: '9876543210',
        patientName: 'Aarav Patel',
        message: 'Reminder for tomorrow',
      );

      expect(result.isSuccess, isTrue);
      expect(result.message, 'WhatsApp opened for Aarav Patel.');
      expect(result.message, isNot(contains('sent')));
      expect(capturedUri, isNotNull);
      expect(capturedUri!.scheme, 'https');
      expect(capturedUri!.host, 'wa.me');
      expect(capturedUri!.path, '/919876543210');
      expect(capturedMode, LaunchMode.externalApplication);
    });

    test('openSmsComposer succeeds and reports SMS composer opened (never message sent)', () async {
      Uri? capturedUri;
      LaunchMode? capturedMode;

      service.setLauncherOverrides(
        canLaunch: (uri) async => true,
        launcher: (uri, {mode = LaunchMode.platformDefault}) async {
          capturedUri = uri;
          capturedMode = mode;
          return true;
        },
      );

      final result = await service.openSmsComposer(
        rawPhoneNumber: '9876543210',
        patientName: 'Priya Sharma',
        message: 'Your appointment is confirmed.',
      );

      expect(result.isSuccess, isTrue);
      expect(result.message, 'SMS composer opened for Priya Sharma.');
      expect(result.message, isNot(contains('sent')));
      expect(capturedUri, isNotNull);
      expect(capturedUri!.scheme, 'sms');
      expect(capturedUri!.path, '+919876543210');
      expect(capturedMode, LaunchMode.externalApplication);
    });

    test('openWhatsApp rejects invalid phone number honestly without crashing', () async {
      final result = await service.openWhatsApp(
        rawPhoneNumber: '12345',
        patientName: 'Test Patient',
        message: 'Test message',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'INVALID_PHONE_NUMBER');
      expect(result.message, contains('No valid phone number is available'));
    });

    test('openSmsComposer rejects invalid phone number honestly without crashing', () async {
      final result = await service.openSmsComposer(
        rawPhoneNumber: '',
        patientName: 'Test Patient',
        message: 'Test message',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'INVALID_PHONE_NUMBER');
      expect(result.message, contains('missing'));
    });

    test('openWhatsApp handles launcher failure honestly', () async {
      service.setLauncherOverrides(
        canLaunch: (uri) async => true,
        launcher: (uri, {mode = LaunchMode.platformDefault}) async => false,
      );

      final result = await service.openWhatsApp(
        rawPhoneNumber: '9876543210',
        patientName: 'Test Patient',
        message: 'Test',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'LAUNCH_FAILED');
      expect(result.message, contains('Could not launch WhatsApp'));
    });

    test('openSmsComposer handles launcher failure honestly', () async {
      service.setLauncherOverrides(
        canLaunch: (uri) async => true,
        launcher: (uri, {mode = LaunchMode.platformDefault}) async => false,
      );

      final result = await service.openSmsComposer(
        rawPhoneNumber: '9876543210',
        patientName: 'Test Patient',
        message: 'Test',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'LAUNCH_FAILED');
      expect(result.message, contains('Could not open SMS composer'));
    });
  });

  group('QuickCommDialogs Widget Tests', () {
    final service = MessagingService.instance;

    setUp(() {
      service.setLauncherOverrides(
        canLaunch: (uri) async => true,
        launcher: (uri, {mode = LaunchMode.platformDefault}) async => true,
      );
    });

    tearDown(() {
      service.resetLauncherOverrides();
    });

    testWidgets('SMS dialog renders with patient details, templates, and opens SMS composer on send',
        (tester) async {
      final clinic = ClinicState();

      await tester.pumpWidget(
        MaterialApp(
          home: ClinicScope(
            state: clinic,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => QuickCommDialogs.showSmsDialog(
                    context,
                    patientId: 'PT-01',
                    patientName: 'Rohan Mehra',
                    phoneNumber: '9876543210',
                    appointmentDate: 'Tomorrow, 10:00 AM',
                    doctorName: 'Dr. Rahul Sharma',
                  ),
                  child: const Text('Open SMS'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open SMS dialog
      await tester.tap(find.text('Open SMS'));
      await tester.pumpAndSettle();

      expect(find.text('Send SMS Message'), findsOneWidget);
      expect(find.text('To: Rohan Mehra (9876543210)'), findsOneWidget);
      expect(find.text('Template Category'), findsOneWidget);

      // Verify that appointment context is embedded in the default text
      expect(find.byType(TextField), findsOneWidget);
      final TextField field = tester.widget(find.byType(TextField));
      expect(field.controller?.text, contains('Rohan Mehra'));
      expect(field.controller?.text, contains('Dr. Rahul Sharma'));
      expect(field.controller?.text, contains('Tomorrow, 10:00 AM'));

      // Tap Send SMS
      await tester.tap(find.text('Send SMS'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Send SMS Message'), findsNothing);

      // Verify NO fake sent message was inserted into clinic.messageRecords
      expect(clinic.messageRecords.where((m) => m.patientId == 'PT-01').isEmpty, isTrue);
    });

    testWidgets('WhatsApp dialog renders and opens WhatsApp on send', (tester) async {
      final clinic = ClinicState();

      await tester.pumpWidget(
        MaterialApp(
          home: ClinicScope(
            state: clinic,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => QuickCommDialogs.showWhatsAppDialog(
                    context,
                    patientId: 'PT-02',
                    patientName: 'Ananya Roy',
                    phoneNumber: '9123456780',
                    appointmentDate: '15 Oct, 2:30 PM',
                    doctorName: 'Dr. Priya Mehta',
                  ),
                  child: const Text('Open WA'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open WhatsApp dialog
      await tester.tap(find.text('Open WA'));
      await tester.pumpAndSettle();

      expect(find.text('WhatsApp Patient Notification'), findsOneWidget);
      expect(find.text('Patient: Ananya Roy • 9123456780'), findsOneWidget);
      expect(find.text('Send on WhatsApp'), findsOneWidget);

      // Verify message template has patient & doctor info
      final TextField field = tester.widget(find.byType(TextField));
      expect(field.controller?.text, contains('Ananya Roy'));
      expect(field.controller?.text, contains('Dr. Priya Mehta'));
      expect(field.controller?.text, contains('15 Oct, 2:30 PM'));

      // Tap Send on WhatsApp
      await tester.tap(find.text('Send on WhatsApp'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('WhatsApp Patient Notification'), findsNothing);

      // Verify NO fake sent message was inserted into clinic.messageRecords
      expect(clinic.messageRecords.where((m) => m.patientId == 'PT-02').isEmpty, isTrue);
    });
  });
}
