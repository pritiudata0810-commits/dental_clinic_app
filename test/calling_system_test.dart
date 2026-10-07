import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/models/communication.dart';
import 'package:dental_clinic_app/services/telephony/phone_number_util.dart';
import 'package:dental_clinic_app/services/telephony/telephony_provider.dart';
import 'package:dental_clinic_app/services/telephony/call_service.dart';
import 'package:dental_clinic_app/widgets/communication/quick_comm_dialogs.dart';

class MockTestTelephonyProvider implements TelephonyProvider {
  final bool shouldSucceed;
  final String? mockError;
  String? lastLaunchedPhone;
  String? lastPatientName;

  MockTestTelephonyProvider({
    this.shouldSucceed = true,
    this.mockError,
  });

  @override
  String get providerName => 'Mock Test Telephony Provider';

  @override
  TelephonyLevel get capabilityLevel => TelephonyLevel.level1NativeDialer;

  @override
  Future<CallLaunchResult> launchCall({
    required String normalizedPhone,
    required String patientName,
  }) async {
    lastLaunchedPhone = normalizedPhone;
    lastPatientName = patientName;

    if (shouldSucceed) {
      return CallLaunchResult.success(
        status: CallStatus.dialerOpened,
        message: 'Mock dialer opened for $patientName ($normalizedPhone)',
      );
    } else {
      return CallLaunchResult.failed(
        mockError ?? 'Mock carrier failure',
        errorCode: 'MOCK_ERROR',
      );
    }
  }
}

void main() {
  group('PhoneNumberUtil Validation & Normalization Tests', () {
    test('Standard 10-digit Indian numbers starting with 6, 7, 8, 9 are normalized to E.164 (+91)', () {
      final res1 = PhoneNumberUtil.validateAndNormalize('9876543210');
      expect(res1.isValid, isTrue);
      expect(res1.normalizedNumber, '+919876543210');
      expect(res1.formattedDisplay, '+91 98765 43210');

      final res2 = PhoneNumberUtil.validateAndNormalize('8123456789');
      expect(res2.isValid, isTrue);
      expect(res2.normalizedNumber, '+918123456789');

      final res3 = PhoneNumberUtil.validateAndNormalize('7012345678');
      expect(res3.isValid, isTrue);
      expect(res3.normalizedNumber, '+917012345678');

      final res4 = PhoneNumberUtil.validateAndNormalize('6912345678');
      expect(res4.isValid, isTrue);
      expect(res4.normalizedNumber, '+916912345678');
    });

    test('Formatted phone numbers with spaces, dashes, brackets, and prefixes are normalized cleanly', () {
      final res1 = PhoneNumberUtil.validateAndNormalize('+91 98765 43210');
      expect(res1.isValid, isTrue);
      expect(res1.normalizedNumber, '+919876543210');

      final res2 = PhoneNumberUtil.validateAndNormalize('+91-98765-43210');
      expect(res2.isValid, isTrue);
      expect(res2.normalizedNumber, '+919876543210');

      final res3 = PhoneNumberUtil.validateAndNormalize('09876543210');
      expect(res3.isValid, isTrue);
      expect(res3.normalizedNumber, '+919876543210');

      final res4 = PhoneNumberUtil.validateAndNormalize('919876543210');
      expect(res4.isValid, isTrue);
      expect(res4.normalizedNumber, '+919876543210');
    });

    test('Invalid numbers are rejected with informative error messages', () {
      final resEmpty = PhoneNumberUtil.validateAndNormalize('');
      expect(resEmpty.isValid, isFalse);
      expect(resEmpty.normalizedNumber, isNull);
      expect(resEmpty.errorMessage, contains('missing'));

      final resNull = PhoneNumberUtil.validateAndNormalize(null);
      expect(resNull.isValid, isFalse);
      expect(resNull.normalizedNumber, isNull);

      final resShort = PhoneNumberUtil.validateAndNormalize('98765');
      expect(resShort.isValid, isFalse);
      expect(resShort.normalizedNumber, isNull);
      expect(resShort.errorMessage, contains('No valid phone number is available'));

      final resInvalidLeading = PhoneNumberUtil.validateAndNormalize('5876543210');
      expect(resInvalidLeading.isValid, isFalse);
      expect(resInvalidLeading.errorMessage, contains('No valid phone number is available'));

      final resAlphabetic = PhoneNumberUtil.validateAndNormalize('abcdefghij');
      expect(resAlphabetic.isValid, isFalse);
    });

    test('Masking and display helpers format securely', () {
      expect(PhoneNumberUtil.maskPhoneNumber('+919876543210'), '+91 98765 •••••');
      expect(PhoneNumberUtil.maskPhoneNumber('9876543210'), '+91 98765 •••••');
      expect(PhoneNumberUtil.maskPhoneNumber(''), '••••••••••');
      expect(PhoneNumberUtil.formatForDisplay('+919876543210'), '+91 98765 43210');
    });
  });

  group('CallRecord Model & Telephony Domain Tests', () {
    test('CallRecord serializes and deserializes accurately with dialer_opened status', () {
      final now = DateTime(2026, 9, 25, 14, 30);
      final record = CallRecord(
        id: 'CALL-101',
        patientId: 'PAT-42',
        patientName: 'Aarav Mehta',
        phoneNumber: '+919876543210',
        timestamp: now,
        durationSeconds: 0,
        direction: CallDirection.outgoing,
        status: CallStatus.dialerOpened,
        staffUserId: 'USER-STAFF-1',
        staffName: 'Alfiya Shaikh',
        clinicId: 'CLINIC-01',
        callType: 'voice',
        note: 'Appointment reminder follow-up',
      );

      final map = record.toMap();
      expect(map['id'], 'CALL-101');
      expect(map['patient_id'], 'PAT-42');
      expect(map['patient_name'], 'Aarav Mehta');
      expect(map['phone_number'], '+919876543210');
      expect(map['status'], 'dialer_opened');
      expect(map['direction'], 'outgoing');
      expect(map['staff_user_id'], 'USER-STAFF-1');
      expect(map['staff_name'], 'Alfiya Shaikh');
      expect(map['clinic_id'], 'CLINIC-01');

      final reconstructed = CallRecord.fromMap(map);
      expect(reconstructed.id, 'CALL-101');
      expect(reconstructed.patientName, 'Aarav Mehta');
      expect(reconstructed.phoneNumber, '+919876543210');
      expect(reconstructed.status, CallStatus.dialerOpened);
      expect(reconstructed.direction, CallDirection.outgoing);
      expect(reconstructed.staffName, 'Alfiya Shaikh');
      expect(reconstructed.note, 'Appointment reminder follow-up');
    });

    test('CallStatus enum maps cleanly to display names, database strings, and colors', () {
      expect(CallStatus.dialerOpened.value, 'dialer_opened');
      expect(CallStatus.dialerOpened.displayName, 'Dialer Opened');
      expect(CallStatus.dialerOpened.badgeColor, isNotNull);

      expect(CallStatus.completed.value, 'completed');
      expect(CallStatus.completed.displayName, 'Completed');

      expect(CallStatus.failed.value, 'failed');
      expect(CallStatus.failed.displayName, 'Failed');

      expect(CallStatusExtension.fromString('dialer_opened'), CallStatus.dialerOpened);
      expect(CallStatusExtension.fromString('failed'), CallStatus.failed);
      expect(CallStatusExtension.fromString('initiated'), CallStatus.initiated);
      expect(CallStatusExtension.fromString('unknown_status'), CallStatus.dialerOpened);
    });
  });

  group('CallService Authentication & Validation Guard Tests', () {
    test('Rejects call initiation when unauthenticated without launching dialer', () async {
      final callService = CallService.instance;

      final result = await callService.initiateCall(
        patientId: 'PAT-1',
        patientName: 'Kavita Iyer',
        rawPhoneNumber: '9876543210',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'UNAUTHENTICATED');
      expect(result.message, contains('Authentication required'));
    });
  });

  group('Call Confirmation Dialog Widget Tests', () {
    testWidgets('Renders call confirmation dialog with patient info and normalized number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    QuickCommDialogs.showCallDialog(
                      context,
                      patientId: 'PAT-001',
                      patientName: 'Rohan Sharma',
                      phoneNumber: '9876543210',
                    );
                  },
                  child: const Text('Open Call Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Call Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Call Patient?'), findsOneWidget);
      expect(find.text('Rohan Sharma'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.textContaining('Calling as:'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Call'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Displays warning banner when phone number is missing or invalid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    QuickCommDialogs.showCallDialog(
                      context,
                      patientId: 'PAT-002',
                      patientName: 'Sunita Patel',
                      phoneNumber: '1234',
                    );
                  },
                  child: const Text('Open Invalid Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Invalid Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Phone Number'), findsOneWidget);
      expect(find.textContaining('No valid phone number is available for this patient.'), findsOneWidget);
    });
  });
}
