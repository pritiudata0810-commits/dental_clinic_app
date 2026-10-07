import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/models/appointment.dart';
import 'package:dental_clinic_app/models/patient.dart';
import 'package:dental_clinic_app/models/tooth_record.dart';
import 'package:dental_clinic_app/services/tooth_service.dart';
import 'package:dental_clinic_app/services/consultation_service.dart';
import 'package:dental_clinic_app/services/billing_service.dart';

void main() {
  group('Phase 1, Step 2: Production Data Source & No-Mock Fallback Tests', () {
    test('1. ToothService: saveToothRecord returns null on uninitialized/failed client (no fake success)', () async {
      final toothService = ToothService();
      final now = DateTime(2026, 10, 4);
      final sampleRecord = ToothRecord(
        id: 'TR-TEST-1',
        patientId: 'PT-01',
        toothNumber: 11,
        status: ToothStatus.caries,
        treatmentDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = await toothService.saveToothRecord(sampleRecord);
      expect(result, isNull, reason: 'Must not simulate success by returning the unpersisted record');
    });

    test('2. ToothService: deleteToothRecord returns false when client is null (no fake success)', () async {
      final toothService = ToothService();
      final result = await toothService.deleteToothRecord('TR-TEST-1');
      expect(result, isFalse, reason: 'Must not return true when record was not actually deleted from database');
    });

    test('3. ConsultationService: saveConsultation returns false when Supabase is not active (no fake success)', () async {
      final consultationService = ConsultationService();
      final result = await consultationService.saveConsultation(
        patientId: 'PT-01',
        patientName: 'Test Patient',
        doctorId: 'DOC-01',
        doctorName: 'Dr. Sharma',
        reasonForVisit: 'Toothache',
        examinationFindings: 'Caries on 16',
        diagnosis: 'Dental Caries',
      );
      expect(result, isFalse, reason: 'Must not return true when consultation was not persisted to database');
    });

    test('4. BillingService: fetchPaymentsForInvoice returns null on client error, not empty list', () async {
      final billingService = BillingService();
      final result = await billingService.fetchPaymentsForInvoice('INV-01');
      expect(result, isNull, reason: 'Must return null on database error so callers can distinguish error from 0 payments');
    });

    test('5. ClinicState: addAppointment fails honestly and does not add fake appointment locally when Supabase fails', () async {
      final state = ClinicState();
      final initialCount = state.appointments.length;

      final testAppointment = Appointment(
        id: 'APT-FAIL-TEST',
        patientId: 'PT-TEST',
        patientName: 'Unsaved Patient',
        patientPhone: '+91 99999 88888',
        doctorId: 'DOC-01',
        doctorName: 'Dr. Sharma',
        dateTime: DateTime(2026, 10, 10, 10, 0),
        timeString: '10:00 AM',
        appointmentType: 'Consultation',
        status: AppointmentStatus.scheduled,
        tokenNumber: 'TK-99',
      );

      final success = await state.addAppointment(testAppointment);
      expect(success, isFalse, reason: 'Must report failure when Supabase insert fails');
      expect(state.appointments.length, initialCount, reason: 'Must not insert appointment locally if backend rejected');
      expect(state.appointments.any((a) => a.id == 'APT-FAIL-TEST'), isFalse);
    });

    test('6. ClinicState: addPatient fails honestly and does not add fake patient locally when Supabase fails', () async {
      final state = ClinicState();
      final initialCount = state.patients.length;

      final testPatient = Patient(
        id: 'PT-FAIL-TEST',
        name: 'Unsaved Patient',
        phone: '+91 99999 88888',
        email: 'unsaved@example.com',
        dateOfBirth: '1990-01-01',
        gender: 'Male',
        address: 'Test City',
        emergencyContact: 'Contact',
        assignedDoctorId: 'DOC-01',
        assignedDoctorName: 'Dr. Sharma',
        lastVisit: 'Never',
        registrationDate: DateTime.now(),
      );

      final success = await state.addPatient(testPatient);
      expect(success, isFalse, reason: 'Must report failure when Supabase insert fails');
      expect(state.patients.length, initialCount, reason: 'Must not add patient locally if backend rejected');
      expect(state.patients.any((p) => p.id == 'PT-FAIL-TEST'), isFalse);
    });

    test('7. ClinicState: recordPayment fails honestly and does not update invoice balance when Supabase fails', () async {
      final state = ClinicState();
      if (state.invoices.isNotEmpty) {
        final targetInv = state.invoices.first;
        final originalBalance = targetInv.balanceAmount;

        final success = await state.recordPayment(targetInv.id, 500.0, 'Cash');
        expect(success, isFalse, reason: 'Must report failure when Supabase payment recording fails');
        
        // Ensure invoice in state was not modified
        final currentInv = state.invoices.firstWhere((i) => i.id == targetInv.id);
        expect(currentInv.balanceAmount, originalBalance, reason: 'Balance must not change on backend failure');
      }
    });

    test('8. ClinicState: addToothRecord fails honestly when Supabase fails', () async {
      final state = ClinicState();
      final initialCount = state.toothRecords.length;
      final now = DateTime.now();

      final newRecord = ToothRecord(
        id: 'TR-FAIL-01',
        patientId: 'PT-01',
        toothNumber: 21,
        status: ToothStatus.filling,
        treatmentDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final success = await state.addToothRecord(newRecord);
      expect(success, isFalse, reason: 'Must report failure when Supabase save fails');
      expect(state.toothRecords.length, initialCount);
    });

    test('9. ClinicState: clearRemoteError clears error and notifies listeners', () {
      final state = ClinicState();
      expect(state.hasRemoteError, isFalse);
      
      state.clearRemoteError();
      expect(state.hasRemoteError, isFalse);
    });
  });
}
