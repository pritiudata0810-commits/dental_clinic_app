import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/models/payment_record.dart';
import 'package:dental_clinic_app/models/employee.dart';
import 'package:dental_clinic_app/models/attendance_record.dart';
import 'package:dental_clinic_app/services/attendance_service.dart';

void main() {
  group('1. Payments Ledger Domain Model Tests', () {
    test('PaymentRecord serializes and deserializes cleanly with all audit fields', () {
      final now = DateTime(2026, 10, 4, 14, 30);
      final payment = PaymentRecord(
        id: 'PAY-2026-0001',
        invoiceId: 'INV-2026-0042',
        patientId: 'P-1001',
        patientName: 'Aarav Sharma',
        amount: 2500.0,
        paymentMethod: 'UPI',
        transactionRef: 'UPI-REF-987654321',
        receiptNumber: 'RCP-89210',
        receivedByUserId: '5575e33e-ffe8-4354-b093-bc32d70ba962',
        receivedByName: 'Dr. Sharma',
        clinicId: 'CLINIC-01',
        notes: 'Root canal first installment',
        paymentDate: now,
        createdAt: now,
      );

      final map = payment.toMap();
      expect(map['id'], 'PAY-2026-0001');
      expect(map['invoice_id'], 'INV-2026-0042');
      expect(map['patient_id'], 'P-1001');
      expect(map['patient_name'], 'Aarav Sharma');
      expect(map['amount'], 2500.0);
      expect(map['payment_method'], 'UPI');
      expect(map['transaction_ref'], 'UPI-REF-987654321');
      expect(map['receipt_number'], 'RCP-89210');
      expect(map['received_by_user_id'], '5575e33e-ffe8-4354-b093-bc32d70ba962');
      expect(map['received_by_name'], 'Dr. Sharma');
      expect(map['clinic_id'], 'CLINIC-01');

      final reconstructed = PaymentRecord.fromMap(map);
      expect(reconstructed.id, 'PAY-2026-0001');
      expect(reconstructed.invoiceId, 'INV-2026-0042');
      expect(reconstructed.patientName, 'Aarav Sharma');
      expect(reconstructed.amount, 2500.0);
      expect(reconstructed.paymentMethod, 'UPI');
      expect(reconstructed.formattedAmount, contains('2,500.00'));
      expect(reconstructed.formattedDate, contains('04 Oct 2026'));
    });

    test('PaymentRecord copyWith preserves immutability', () {
      final now = DateTime(2026, 10, 4, 10, 0);
      final p1 = PaymentRecord(
        id: 'PAY-1',
        invoiceId: 'INV-1',
        patientId: 'P-1',
        patientName: 'Sunita Rao',
        amount: 1000.0,
        paymentMethod: 'Cash',
        receiptNumber: 'RCP-001',
        paymentDate: now,
        createdAt: now,
      );

      final p2 = p1.copyWith(amount: 1500.0, paymentMethod: 'POS Card');
      expect(p1.amount, 1000.0);
      expect(p2.amount, 1500.0);
      expect(p2.paymentMethod, 'POS Card');
      expect(p2.patientName, 'Sunita Rao');
    });
  });

  group('2. Appointment Collision Logic Tests', () {
    test('Simulated doctor collision rule correctly detects overlapping active appointments', () {
      final baseTime = DateTime(2026, 10, 4, 11, 0);
      const doctorId = 'DOC-01';

      // Function representing the database partial unique index rule:
      // uq_appointments_doctor_active_time (doctor_id, date_time) where status not in ('cancelled', 'noShow')
      bool wouldCollide({
        required String existingDoc,
        required DateTime existingTime,
        required String existingStatus,
        required String newDoc,
        required DateTime newTime,
        required String newStatus,
      }) {
        if (newDoc != existingDoc) return false;
        if (newTime != existingTime) return false;

        const inactiveStatuses = ['cancelled', 'noShow'];
        if (inactiveStatuses.contains(existingStatus)) return false;
        if (inactiveStatuses.contains(newStatus)) return false;

        return true;
      }

      // Test 1: Same doctor, same time, both scheduled -> MUST COLLIDE
      expect(
        wouldCollide(
          existingDoc: doctorId,
          existingTime: baseTime,
          existingStatus: 'scheduled',
          newDoc: doctorId,
          newTime: baseTime,
          newStatus: 'scheduled',
        ),
        isTrue,
      );

      // Test 2: Different doctor, same time -> ALLOWED
      expect(
        wouldCollide(
          existingDoc: doctorId,
          existingTime: baseTime,
          existingStatus: 'scheduled',
          newDoc: 'DOC-02',
          newTime: baseTime,
          newStatus: 'scheduled',
        ),
        isFalse,
      );

      // Test 3: Same doctor, different time -> ALLOWED
      expect(
        wouldCollide(
          existingDoc: doctorId,
          existingTime: baseTime,
          existingStatus: 'scheduled',
          newDoc: doctorId,
          newTime: baseTime.add(const Duration(minutes: 30)),
          newStatus: 'scheduled',
        ),
        isFalse,
      );

      // Test 4: Same doctor, same time, but existing is cancelled -> ALLOWED (Slot freed)
      expect(
        wouldCollide(
          existingDoc: doctorId,
          existingTime: baseTime,
          existingStatus: 'cancelled',
          newDoc: doctorId,
          newTime: baseTime,
          newStatus: 'scheduled',
        ),
        isFalse,
      );
    });
  });

  group('3. Secure handle_new_user Role Downgrade Tests', () {
    test('Simulates migration 007 role assignment rule for public signup privilege protection', () {
      // Replicates handle_new_user() SQL function logic
      String resolveAssignedRole({
        required String? requestedRole,
        required bool isAdminSession,
      }) {
        final req = (requestedRole ?? '').toLowerCase().trim();
        if (req == 'doctor' || req == 'admin') {
          if (isAdminSession) {
            return req;
          } else {
            return 'patient'; // Public signup downgrade
          }
        } else if (req == 'receptionist' || req == 'patient') {
          return req;
        } else {
          return 'patient';
        }
      }

      // Public self-signup trying to escalate to admin -> Downgraded to patient
      expect(
        resolveAssignedRole(requestedRole: 'admin', isAdminSession: false),
        'patient',
      );

      // Public self-signup trying to escalate to doctor -> Downgraded to patient
      expect(
        resolveAssignedRole(requestedRole: 'doctor', isAdminSession: false),
        'patient',
      );

      // Admin or service_role session creating a doctor -> Allowed
      expect(
        resolveAssignedRole(requestedRole: 'doctor', isAdminSession: true),
        'doctor',
      );

      // Admin or service_role session creating an admin -> Allowed
      expect(
        resolveAssignedRole(requestedRole: 'admin', isAdminSession: true),
        'admin',
      );

      // Public signup requesting patient -> Allowed
      expect(
        resolveAssignedRole(requestedRole: 'patient', isAdminSession: false),
        'patient',
      );
    });
  });

  group('4. AttendanceService Check-Out Persistence & Integrity Tests', () {
    final testEmployee = Employee(
      id: 'REC001',
      name: 'Alfiya Shaikh',
      role: 'receptionist',
      email: 'alfiya@smilecare.com',
      phone: '+919876543210',
      department: 'Front Desk',
      createdAt: DateTime(2026, 1, 1),
    );

    test('Check-out rejects if location, liveness, or face verification is false', () async {
      final service = AttendanceService.instance;

      final res = await service.recordCheckOut(
        employee: testEmployee,
        isFaceMatched: false,
        isLivenessPassed: true,
        isLocationVerified: true,
      );

      expect(res.isSuccess, isFalse);
      expect(res.errorCode, 'VERIFICATION_FAILED');
    });

    test('Check-out rejects if employee has no active check-in today', () async {
      final service = AttendanceService.instance;
      service.clearDailyRecords();

      final nonExistentEmp = Employee(
        id: 'EMP-999',
        name: 'Unknown Staff',
        role: 'staff',
        email: 'unknown@smilecare.com',
        phone: '+919876500000',
        department: 'General',
        createdAt: DateTime(2026, 1, 1),
      );

      final res = await service.recordCheckOut(
        employee: nonExistentEmp,
        isFaceMatched: true,
        isLivenessPassed: true,
        isLocationVerified: true,
      );

      expect(res.isSuccess, isFalse);
      expect(res.errorCode, 'NO_CHECKIN_FOUND');
    });

    test('Successful check-out updates checkOut timestamp and preserves check-in info', () async {
      final service = AttendanceService.instance;
      service.clearDailyRecords();

      // 1. Record check-in
      final checkInRes = await service.recordCheckIn(
        employee: testEmployee,
        isFaceMatched: true,
        isLivenessPassed: true,
        isLocationVerified: true,
        distanceMeters: 5.2,
      );
      expect(checkInRes.isSuccess, isTrue);
      final checkedInRecord = checkInRes.record!;
      expect(checkedInRecord.isCheckedOut, isFalse);

      // 2. Record check-out
      final checkOutRes = await service.recordCheckOut(
        employee: testEmployee,
        isFaceMatched: true,
        isLivenessPassed: true,
        isLocationVerified: true,
      );

      expect(checkOutRes.isSuccess, isTrue);
      final checkedOutRecord = checkOutRes.record!;
      expect(checkedOutRecord.isCheckedOut, isTrue);
      expect(checkedOutRecord.checkOut, isNotNull);

      // Check-in information must be strictly preserved
      expect(checkedOutRecord.id, checkedInRecord.id);
      expect(checkedOutRecord.employeeId, testEmployee.id);
      expect(checkedOutRecord.checkIn, checkedInRecord.checkIn);
      expect(checkedOutRecord.distanceMeters, 5.2);
      expect(checkedOutRecord.status, AttendanceDayStatus.checkedOut);

      // 3. Duplicate check-out rejected
      final dupRes = await service.recordCheckOut(
        employee: testEmployee,
        isFaceMatched: true,
        isLivenessPassed: true,
        isLocationVerified: true,
      );
      expect(dupRes.isSuccess, isFalse);
      expect(dupRes.errorCode, 'ALREADY_CHECKED_OUT');
    });
  });
}
