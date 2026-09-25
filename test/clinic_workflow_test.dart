import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/app/app.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/state/clinic_scope.dart';
import 'package:dental_clinic_app/screens/receptionist/call_reminders_screen.dart';
import 'package:dental_clinic_app/screens/receptionist/waiting_room_screen.dart';
import 'package:dental_clinic_app/screens/receptionist/patients_screen.dart';
import 'package:dental_clinic_app/screens/receptionist/appointments_screen.dart';
import 'package:dental_clinic_app/screens/receptionist/doctor_availability_screen.dart';
import 'package:dental_clinic_app/screens/receptionist/settings_screen.dart';
import 'package:dental_clinic_app/screens/doctor/main_shell.dart';
import 'package:dental_clinic_app/widgets/patients/add_patient_dialog.dart';

void main() {
  group('Clinic Multi-Role and Responsive Tests', () {
    testWidgets('Smoke test: Login screen displays branding and quick fill accounts', (WidgetTester tester) async {
      await tester.pumpWidget(const DentalClinicApp());
      await tester.pumpAndSettle();

      expect(find.text('SmileCare OS'), findsWidgets);
      expect(find.text('Clinic Staff Sign In'), findsOneWidget);
      expect(find.text('Receptionist Account'), findsOneWidget);
      expect(find.text('Doctor Account'), findsOneWidget);
    });

    testWidgets('CallRemindersScreen is the dedicated place with CALL, SMS, WHATSAPP buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: Scaffold(body: CallRemindersScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Call Reminders Queue'), findsOneWidget);
      expect(find.textContaining('Reminders Pending'), findsOneWidget);
      expect(find.textContaining('Patients Confirmed'), findsOneWidget);
      expect(find.textContaining('Missed Calls'), findsOneWidget);
      expect(find.textContaining('Total Remaining'), findsOneWidget);
      expect(find.text('CALL'), findsWidgets);
      expect(find.text('SMS'), findsWidgets);
      expect(find.text('WHATSAPP'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WaitingRoomScreen has NO call/whatsapp buttons (workflow buttons only)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: Scaffold(body: WaitingRoomScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Waiting Room & Patient Queue'), findsOneWidget);
      // Comm buttons are strictly removed from waiting room
      expect(find.text('CALL'), findsNothing);
      expect(find.text('WHATSAPP'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PatientsScreen has NO comm buttons and renders clean list', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: Scaffold(body: PatientsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patients'), findsOneWidget);
      expect(find.text('CALL'), findsNothing);
      expect(find.text('SMS'), findsNothing);
      expect(find.text('WHATSAPP'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppointmentsScreen has fluid date navigation and NO comm buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: Scaffold(body: AppointmentsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appointment Scheduling & Roster'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Tomorrow'), findsWidgets);
      expect(find.text('CALL'), findsNothing);
      expect(find.text('SMS'), findsNothing);
      expect(find.text('WHATSAPP'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DoctorAvailabilityScreen renders clean operatory roster without overflows', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: Scaffold(body: DoctorAvailabilityScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Doctor Operatory & Availability'), findsOneWidget);
      expect(find.text('Total Doctors'), findsOneWidget);
      expect(find.text('Available Now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Receptionist SettingsScreen renders application workstation preferences', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Application & Workstation Settings'), findsOneWidget);
      expect(find.text('Appearance & Display'), findsOneWidget);
      expect(find.text('Regional & Date / Time Formats'), findsOneWidget);
      expect(find.text('Audio & Real-time Alerts'), findsOneWidget);
      expect(find.text('Apply Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Doctor Portal MainShell renders responsive DoctorShell with desktop sidebar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: MainShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SmileCare OS'), findsWidgets);
      expect(find.text('Doctor Clinical Portal'), findsOneWidget);
      expect(find.text('Clinical Dashboard'), findsWidgets);
      expect(find.text('Clinical Consultation'), findsOneWidget);
      expect(find.text('Doctor Profile'), findsOneWidget);
      expect(find.text('Clinic Profile'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      final exc = tester.takeException();
      if (exc != null) {
        debugPrint('DOCTOR TEST EXCEPTION: $exc');
      }
      expect(exc, isNull);
    });

    testWidgets('Doctor consultation workflow screens render without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: MainShell(initialIndex: 3), // Consultation
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Visit Notes'), findsWidgets);
      expect(find.textContaining('Clinical Examination'), findsWidgets);
      expect(find.textContaining('Continue to Treatment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive DoctorShell at 600px width renders with zero overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ClinicScope(
          state: ClinicState(),
          child: const MaterialApp(
            home: MainShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Clinic Queue & Token Monitor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddPatientDialog renders all fields and buttons with zero RenderFlex overflow across viewports', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final clinicState = ClinicState();

      await tester.pumpWidget(
        ClinicScope(
          state: clinicState,
          child: const MaterialApp(
            home: Scaffold(
              body: AddPatientDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and fields exist
      expect(find.text('Register New Patient'), findsOneWidget);
      expect(find.text('1. PERSONAL INFORMATION'), findsOneWidget);
      expect(find.text('2. CLINIC ASSIGNMENT & MEDICAL NOTES'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Register Patient'), findsOneWidget);

      // Select Dr. Amit Shah (longest name: Endodontist (Root Canal Specialist))
      final doctorDropdownFinder = find.byType(DropdownButtonFormField<String>).at(2);
      await tester.tap(doctorDropdownFinder);
      await tester.pumpAndSettle();

      final doctorItem = find.textContaining('Dr. Amit Shah').last;
      await tester.tap(doctorItem);
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow exception
      expect(tester.takeException(), isNull);

      // Also test smaller viewport (768x600)
      tester.view.physicalSize = const Size(768, 600);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
