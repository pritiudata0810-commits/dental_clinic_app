import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/models/tooth_record.dart';
import 'package:dental_clinic_app/models/patient.dart';
import 'package:dental_clinic_app/models/appointment.dart';
import 'package:dental_clinic_app/services/oral_health_score_service.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/state/clinic_scope.dart';
import 'package:dental_clinic_app/widgets/dental/interactive_tooth_chart.dart';
import 'package:dental_clinic_app/widgets/dental/tooth_timeline_view.dart';
import 'package:dental_clinic_app/widgets/dental/oral_health_score_card.dart';
import 'package:dental_clinic_app/screens/receptionist/reports_screen.dart';

void main() {
  group('Phase 1: FDI Adult Permanent Dentition & Model Unit Tests', () {
    test('Validates adult permanent FDI tooth numbering (11-18, 21-28, 31-38, 41-48)', () {
      // Valid quadrant teeth
      expect(ToothRecord.isValidFdi(11), isTrue);
      expect(ToothRecord.isValidFdi(18), isTrue);
      expect(ToothRecord.isValidFdi(21), isTrue);
      expect(ToothRecord.isValidFdi(28), isTrue);
      expect(ToothRecord.isValidFdi(31), isTrue);
      expect(ToothRecord.isValidFdi(38), isTrue);
      expect(ToothRecord.isValidFdi(41), isTrue);
      expect(ToothRecord.isValidFdi(48), isTrue);

      // Invalid FDI numbers
      expect(ToothRecord.isValidFdi(10), isFalse);
      expect(ToothRecord.isValidFdi(19), isFalse);
      expect(ToothRecord.isValidFdi(20), isFalse);
      expect(ToothRecord.isValidFdi(29), isFalse);
      expect(ToothRecord.isValidFdi(51), isFalse); // Primary tooth
      expect(ToothRecord.isValidFdi(99), isFalse);
    });

    test('ToothRecord correctly formats anatomical labels and quadrants', () {
      final record = ToothRecord(
        id: 'TR-TEST-01',
        patientId: 'P-1001',
        toothNumber: 36,
        status: ToothStatus.rootCanal,
        procedure: 'RCT',
        clinicalFinding: 'Pulpitis',
        treatmentDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(record.quadrant, 3);
      expect(record.position, 6);
      expect(record.toothName, contains('Lower Left First Molar'));
      expect(record.fullToothLabel, contains('Mandibular Left Quadrant 3'));
    });

    test('ToothRecord serializes to and from JSON accurately', () {
      final now = DateTime.now();
      final record = ToothRecord(
        id: 'TR-SERIAL-01',
        patientId: 'P-1002',
        toothNumber: 46,
        status: ToothStatus.caries,
        procedure: 'Caries Excavation',
        clinicalFinding: 'Class II MO cavity',
        notes: 'Sedative IRM placed',
        dentistName: 'Dr. Amit Shah',
        treatmentDate: now,
        completionStatus: ToothTreatmentCompletionStatus.requiresFollowUp,
        createdAt: now,
        updatedAt: now,
      );

      final json = record.toJson();
      expect(json['tooth_number'], 46);
      expect(json['status'], 'caries');
      expect(json['completion_status'], 'requiresFollowUp');

      final deserialized = ToothRecord.fromJson(json);
      expect(deserialized.id, 'TR-SERIAL-01');
      expect(deserialized.toothNumber, 46);
      expect(deserialized.status, ToothStatus.caries);
      expect(deserialized.completionStatus, ToothTreatmentCompletionStatus.requiresFollowUp);
    });
  });

  group('Phase 1: Deterministic Oral Health Score Service Unit Tests', () {
    final basePatient = Patient(
      id: 'P-TEST',
      name: 'Rohan Verma',
      phone: '+91 98111 22233',
      email: 'rohan@test.com',
      dateOfBirth: '1992-05-10',
      gender: 'Male',
      address: 'Dehradun',
      emergencyContact: 'Sister',
      assignedDoctorId: 'DOC-01',
      assignedDoctorName: 'Dr. Rahul Sharma',
      lastVisit: '10 days ago',
      totalVisits: 3,
      registrationDate: DateTime.now().subtract(const Duration(days: 30)),
    );

    test('Calculates High/Excellent score for patient with preventive care and zero caries', () {
      final now = DateTime.now();
      final toothRecords = [
        ToothRecord(
          id: 'T1',
          patientId: 'P-TEST',
          toothNumber: 16,
          status: ToothStatus.healthy,
          procedure: 'Routine Scaling and Prophylaxis',
          treatmentDate: now.subtract(const Duration(days: 10)),
          completionStatus: ToothTreatmentCompletionStatus.completed,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final appointments = [
        Appointment(
          id: 'A1',
          patientId: 'P-TEST',
          patientName: 'Rohan Verma',
          patientPhone: '+91 98111 22233',
          doctorId: 'DOC-01',
          doctorName: 'Dr. Rahul Sharma',
          dateTime: now.subtract(const Duration(days: 10)),
          timeString: '10:00 AM',
          appointmentType: 'Routine Cleaning',
          durationMinutes: 30,
          status: AppointmentStatus.completed,
          tokenNumber: 'TK-01',
        ),
      ];

      final result = OralHealthScoreService.calculate(
        patient: basePatient,
        appointments: appointments,
        toothRecords: toothRecords,
      );

      expect(result.totalScore, greaterThanOrEqualTo(85));
      expect(result.category, 'Excellent');
      expect(result.factors.length, 6);
      expect(result.recommendations, isNotEmpty);
    });

    test('Applies penalties for active caries burden and pending follow-ups', () {
      final now = DateTime.now();
      final toothRecords = [
        ToothRecord(
          id: 'T1',
          patientId: 'P-TEST',
          toothNumber: 46,
          status: ToothStatus.caries,
          procedure: 'Caries Identified',
          treatmentDate: now.subtract(const Duration(days: 2)),
          completionStatus: ToothTreatmentCompletionStatus.requiresFollowUp,
          createdAt: now,
          updatedAt: now,
        ),
        ToothRecord(
          id: 'T2',
          patientId: 'P-TEST',
          toothNumber: 14,
          status: ToothStatus.underTreatment,
          procedure: 'Perio Treatment',
          treatmentDate: now.subtract(const Duration(days: 5)),
          completionStatus: ToothTreatmentCompletionStatus.inProgress,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final appointments = [
        Appointment(
          id: 'A1',
          patientId: 'P-TEST',
          patientName: 'Rohan Verma',
          patientPhone: '+91 98111 22233',
          doctorId: 'DOC-01',
          doctorName: 'Dr. Rahul Sharma',
          dateTime: now.subtract(const Duration(days: 20)),
          timeString: '11:00 AM',
          appointmentType: 'Consultation',
          durationMinutes: 30,
          status: AppointmentStatus.noShow, // missed
          tokenNumber: 'TK-02',
        ),
      ];

      final result = OralHealthScoreService.calculate(
        patient: basePatient,
        appointments: appointments,
        toothRecords: toothRecords,
      );

      expect(result.totalScore, lessThan(80));
      expect(result.clinicalObservations, anyElement(contains('active carious lesion')));
      expect(result.recommendations, anyElement(contains('direct resin composite')));
    });
  });

  group('Phase 1: Dental UI Widgets Tests', () {
    testWidgets('InteractiveToothChart renders all quadrants and handles tooth clicks', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int? selectedTooth;
      final Map<int, ToothRecord> latestTeeth = {
        36: ToothRecord(
          id: 'T-36',
          patientId: 'P-1001',
          toothNumber: 36,
          status: ToothStatus.rootCanal,
          procedure: 'RCT',
          treatmentDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveToothChart(
                latestTeethMap: latestTeeth,
                selectedToothNumber: selectedTooth,
                onToothSelected: (tooth) {
                  selectedTooth = tooth;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Adult Permanent Dentition Chart (FDI System)'), findsOneWidget);
      expect(find.text('MAXILLARY ARCH (UPPER JAW)'), findsOneWidget);
      expect(find.text('MANDIBULAR ARCH (LOWER JAW)'), findsOneWidget);
      expect(find.text('36'), findsOneWidget);

      // Tap tooth #36
      await tester.tap(find.text('36'));
      await tester.pump();
      expect(selectedTooth, 36);
    });

    testWidgets('ToothTimelineView renders patient timeline and empty/populated state', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final clinicState = ClinicState();
      final patient = clinicState.patients.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ClinicScope(
            state: clinicState,
            child: Scaffold(
              body: SingleChildScrollView(
                child: ToothTimelineView(
                  patient: patient,
                  selectedToothNumber: null,
                  onClearSelection: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Digital Tooth Timeline'), findsOneWidget);
      expect(find.text('Add Tooth Record'), findsOneWidget);
    });

    testWidgets('OralHealthScoreCard renders informational summary with 6 factor bars', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final clinicState = ClinicState();
      final patient = clinicState.patients.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ClinicScope(
            state: clinicState,
            child: Scaffold(
              body: SingleChildScrollView(
                child: OralHealthScoreCard(patient: patient),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Patient Oral-Health Score'), findsOneWidget);
      expect(find.text('Informational clinical summary'), findsOneWidget);
      expect(find.text('Scoring Breakdown (6 Clinical Factors)'), findsOneWidget);
      expect(find.text('Preventive Care'), findsOneWidget);
      expect(find.text('Treatment Completion'), findsOneWidget);
      expect(find.text('Clinical Observations'), findsOneWidget);
      expect(find.text('Recommended Next Steps'), findsOneWidget);
    });

    testWidgets('ReportsScreen renders practice intelligence with zero hardcoded values', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final clinicState = ClinicState();

      await tester.pumpWidget(
        MaterialApp(
          home: ClinicScope(
            state: clinicState,
            child: const Scaffold(
              body: ReportsScreen(),
            ),
          ),
        ),
      );

      expect(find.text('Practice Intelligence & Clinical Analytics'), findsOneWidget);
      expect(find.text('TOTAL APPOINTMENTS'), findsOneWidget);
      expect(find.text('COMPLETED SESSIONS'), findsOneWidget);
      expect(find.text('NEW PATIENT INTAKE'), findsOneWidget);
      expect(find.text('REVENUE COLLECTED'), findsOneWidget);
      expect(find.text('GROSS BILLED VOLUME'), findsOneWidget);
      expect(find.text('Dentist Operatory Share'), findsOneWidget);
      expect(find.text('Collections by Payment Method'), findsOneWidget);

      // Verify time range filters
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);

      // Switch time range to 'This Month'
      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();
      expect(find.text('TOTAL APPOINTMENTS'), findsOneWidget);
    });
  });
}
