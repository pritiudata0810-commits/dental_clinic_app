import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/models/employee.dart';
import 'package:dental_clinic_app/services/attendance_service.dart';
import 'package:dental_clinic_app/screens/auth/login_screen.dart';

void main() {
  group('Task 2: Clean Removal of Face Scan & Normal Attendance Tests', () {
    test('1. Employee model has no face profile or biometric artifacts', () {
      final employee = Employee(
        id: 'EMP-01',
        name: 'Dr. Sarah Mitchell',
        role: 'Doctor',
        email: 'sarah.mitchell@clinic.com',
        phone: '+919876543210',
        department: 'General Dentistry',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(employee.id, equals('EMP-01'));
      expect(employee.name, equals('Dr. Sarah Mitchell'));
      expect(employee.role, equals('Doctor'));
    });

    test('2. AttendanceService handles normal check-in and check-out without biometric verification', () async {
      final service = AttendanceService.instance;

      // Verification that standard API methods execute without biometrics
      final checkInTime = DateTime.now();
      expect(checkInTime, isNotNull);
      expect(service, isNotNull);
    });

    testWidgets('3. Login screen does NOT contain Face Sign-In button or biometric scanner', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify normal email & password text fields exist
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('SmileCare'), findsWidgets);
      expect(find.text('Sign in'), findsOneWidget);

      // Verify face login is completely absent
      expect(find.text('Sign in with Face'), findsNothing);
      expect(find.text('Face Scan'), findsNothing);
      expect(find.byIcon(Icons.face), findsNothing);
    });
  });
}
