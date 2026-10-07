import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/models/user_profile.dart';
import 'package:dental_clinic_app/services/auth_service.dart';
import 'package:dental_clinic_app/widgets/auth/auth_gate.dart';

void main() {
  group('UserProfile Model & Role Authorization Tests', () {
    test('Correctly deserializes doctor profile map', () {
      final map = {
        'id': 'a2c46130-268f-480d-a455-8178ae623d95',
        'email': 'dr.sharma@smilecare.com',
        'full_name': 'Dr. Rahul Sharma',
        'role': 'doctor',
        'clinic_id': 'CLINIC-01',
        'created_at': '2026-09-20T10:06:22.000Z',
        'updated_at': '2026-09-20T10:06:22.000Z',
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.id, 'a2c46130-268f-480d-a455-8178ae623d95');
      expect(profile.email, 'dr.sharma@smilecare.com');
      expect(profile.fullName, 'Dr. Rahul Sharma');
      expect(profile.role, UserRole.doctor);
      expect(profile.isDoctor, isTrue);
      expect(profile.isReceptionist, isFalse);
      expect(profile.clinicId, 'CLINIC-01');
    });

    test('Correctly deserializes receptionist profile map', () {
      final map = {
        'id': '112d0617-1428-4ed7-8452-c1ae2316d963',
        'email': 'receptionist@smilecare.com',
        'full_name': 'Alfiya Shaikh',
        'role': 'receptionist',
        'clinic_id': 'CLINIC-01',
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.role, UserRole.receptionist);
      expect(profile.isReceptionist, isTrue);
      expect(profile.isDoctor, isFalse);
      expect(profile.role.displayName, 'Receptionist');
    });

    test('Role parsing handles case insensitivity and defaults gracefully', () {
      expect(UserRoleExtension.fromString('DOCTOR'), UserRole.doctor);
      expect(UserRoleExtension.fromString('Receptionist'), UserRole.receptionist);
      expect(UserRoleExtension.fromString('admin'), UserRole.admin);
      expect(UserRoleExtension.fromString('patient'), UserRole.patient);
      expect(UserRoleExtension.fromString('unknown_role'), UserRole.receptionist);
      expect(UserRoleExtension.fromString(null), UserRole.receptionist);
    });

    test('UserProfile toMap serialization produces consistent database structure', () {
      final profile = UserProfile(
        id: 'user-123',
        email: 'test@clinic.com',
        fullName: 'Test User',
        role: UserRole.doctor,
        clinicId: 'CLINIC-01',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final map = profile.toMap();
      expect(map['id'], 'user-123');
      expect(map['role'], 'doctor');
      expect(map['clinic_id'], 'CLINIC-01');
      expect(map['email'], 'test@clinic.com');
    });

    test('AuthService exception classes preserve descriptive error messages', () {
      const notFound = ProfileNotFoundException('No profile configured.');
      expect(notFound.toString(), 'No profile configured.');

      const serverErr = AuthServerException('Invalid credentials.');
      expect(serverErr.toString(), 'Invalid credentials.');

      const unauth = UnauthorizedException('Access denied.');
      expect(unauth.toString(), 'Access denied.');
    });
  });

  group('Route Protection Widget Tests', () {
    testWidgets('RoleGuardedRoute redirects unauthenticated users to login', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/guarded',
          routes: {
            '/login': (context) => const Scaffold(body: Text('Login Screen Mock')),
            '/guarded': (context) => const RoleGuardedRoute(
                  allowedRoles: [UserRole.doctor],
                  child: Scaffold(body: Text('Protected Clinical Screen')),
                ),
          },
        ),
      );

      // Trigger frame for redirect
      await tester.pumpAndSettle();

      // Must be redirected to /login because no user is authenticated
      expect(find.text('Login Screen Mock'), findsOneWidget);
      expect(find.text('Protected Clinical Screen'), findsNothing);
    });
  });
}
