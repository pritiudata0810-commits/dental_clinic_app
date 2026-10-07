import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/employee.dart';
import 'supabase_service.dart';

/// Result of an attendance record attempt
class AttendanceActionResult {
  final bool isSuccess;
  final String message;
  final AttendanceRecord? record;
  final bool isDuplicate;
  final String? errorCode;

  const AttendanceActionResult({
    required this.isSuccess,
    required this.message,
    this.record,
    this.isDuplicate = false,
    this.errorCode,
  });
}

/// Service managing employee biometric check-in, check-out, duplicate prevention, and history.
class AttendanceService extends ChangeNotifier {
  static final AttendanceService instance = AttendanceService._internal();
  factory AttendanceService() => instance;

  AttendanceService._internal() {
    _loadInitialRecords();
  }

  final List<AttendanceRecord> _records = [];

  List<AttendanceRecord> get records => List.unmodifiable(_records);

  String get todayDateStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<AttendanceRecord> getTodayRecords() =>
      _records.where((r) => r.date == todayDateStr).toList();

  void clearDailyRecords() {
    _records.clear();
    notifyListeners();
  }

  void _loadInitialRecords() {
    // Standard initial seed records for demo/display
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    _records.addAll([
      AttendanceRecord(
        id: 'ATT-DEMO-001',
        employeeId: 'REC001',
        employeeName: 'Alfiya Shaikh',
        employeeRole: 'Front-Desk Receptionist',
        date: todayStr,
        checkIn: DateTime(now.year, now.month, now.day, 8, 55),
        verificationMethod: VerificationMethod.faceBiometric,
        faceVerificationStatus: VerificationStatus.verified,
        livenessStatus: VerificationStatus.verified,
        locationStatus: VerificationStatus.verified,
        distanceMeters: 4.2,
        status: AttendanceDayStatus.present,
        createdAt: DateTime(now.year, now.month, now.day, 8, 55),
      ),
      AttendanceRecord(
        id: 'ATT-DEMO-002',
        employeeId: 'DOC001',
        employeeName: 'Dr. Rajesh Sharma',
        employeeRole: 'Senior Dental Surgeon',
        date: todayStr,
        checkIn: DateTime(now.year, now.month, now.day, 9, 10),
        verificationMethod: VerificationMethod.faceBiometric,
        faceVerificationStatus: VerificationStatus.verified,
        livenessStatus: VerificationStatus.verified,
        locationStatus: VerificationStatus.verified,
        distanceMeters: 8.5,
        status: AttendanceDayStatus.present,
        createdAt: DateTime(now.year, now.month, now.day, 9, 10),
      ),
    ]);
  }

  /// Finds today's active attendance record for a specific employee
  AttendanceRecord? getTodayRecord(String employeeId) {
    try {
      return _records.firstWhere(
        (r) => r.employeeId == employeeId && r.date == todayDateStr,
      );
    } catch (_) {
      return null;
    }
  }

  /// Records verified biometric check-in for an employee.
  /// Strictly prevents duplicate check-ins on the same day.
  Future<AttendanceActionResult> recordCheckIn({
    required Employee employee,
    required bool isFaceMatched,
    required bool isLivenessPassed,
    required bool isLocationVerified,
    double? distanceMeters,
    String? deviceId,
  }) async {
    // 1. Mandatory Security Gates
    if (!isLocationVerified) {
      return const AttendanceActionResult(
        isSuccess: false,
        message: 'Attendance check-in rejected: Outside clinic geofence.',
        errorCode: 'OUTSIDE_GEOFENCE',
      );
    }

    if (!isLivenessPassed) {
      return const AttendanceActionResult(
        isSuccess: false,
        message: 'Attendance check-in rejected: Liveness / anti-spoofing verification failed.',
        errorCode: 'LIVENESS_FAILED',
      );
    }

    if (!isFaceMatched) {
      return const AttendanceActionResult(
        isSuccess: false,
        message: 'Attendance check-in rejected: Face does not match enrolled biometric template for this employee.',
        errorCode: 'FACE_MISMATCH',
      );
    }

    // 2. Duplicate Check-in Prevention
    final existing = getTodayRecord(employee.id);
    if (existing != null) {
      return AttendanceActionResult(
        isSuccess: false,
        isDuplicate: true,
        record: existing,
        message: 'Already checked in today at ${existing.formattedCheckIn}. Duplicate check-in is not permitted.',
        errorCode: 'ALREADY_CHECKED_IN',
      );
    }

    // 3. Create Valid Record
    final now = DateTime.now();
    final isLate = now.hour > 9 || (now.hour == 9 && now.minute > 30); // 9:30 AM cutoff

    final newRecord = AttendanceRecord(
      id: 'ATT-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: employee.id,
      employeeName: employee.name,
      employeeRole: employee.role,
      date: todayDateStr,
      checkIn: now,
      verificationMethod: VerificationMethod.faceBiometric,
      faceVerificationStatus: VerificationStatus.verified,
      livenessStatus: VerificationStatus.verified,
      locationStatus: VerificationStatus.verified,
      distanceMeters: distanceMeters,
      status: isLate ? AttendanceDayStatus.lateArrival : AttendanceDayStatus.present,
      createdAt: now,
      deviceId: deviceId,
    );

    _records.insert(0, newRecord);
    notifyListeners();

    // 4. Remote Supabase persistence if connected
    _syncToSupabase(newRecord);

    return AttendanceActionResult(
      isSuccess: true,
      record: newRecord,
      message: 'Check-in recorded successfully at ${newRecord.formattedCheckIn}. Status: ${newRecord.status.name}.',
    );
  }

  /// Records verified check-out for an employee.
  Future<AttendanceActionResult> recordCheckOut({
    required Employee employee,
    required bool isFaceMatched,
    required bool isLivenessPassed,
    required bool isLocationVerified,
  }) async {
    if (!isLocationVerified || !isLivenessPassed || !isFaceMatched) {
      return const AttendanceActionResult(
        isSuccess: false,
        message: 'Check-out rejected: Biometric identity or location verification failed.',
        errorCode: 'VERIFICATION_FAILED',
      );
    }

    final existing = getTodayRecord(employee.id);
    if (existing == null) {
      return const AttendanceActionResult(
        isSuccess: false,
        message: 'Cannot check out: No active check-in record found for today.',
        errorCode: 'NO_CHECKIN_FOUND',
      );
    }

    if (existing.isCheckedOut) {
      return AttendanceActionResult(
        isSuccess: false,
        isDuplicate: true,
        record: existing,
        message: 'Already checked out today at ${existing.formattedCheckOut}.',
        errorCode: 'ALREADY_CHECKED_OUT',
      );
    }

    final now = DateTime.now();
    final updated = existing.copyWith(
      checkOut: now,
      status: AttendanceDayStatus.checkedOut,
    );

    // Persist check-out to Supabase if connected
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('attendance').update({
          'check_out': now.toIso8601String(),
          'status': AttendanceDayStatus.checkedOut.name,
        }).eq('id', existing.id);
        debugPrint('[AttendanceService] Check-out synced to Supabase for ${employee.id} (${existing.id})');
      } catch (e) {
        debugPrint('[AttendanceService] Supabase check-out update failed: $e');
        return AttendanceActionResult(
          isSuccess: false,
          record: existing,
          message: 'Failed to record check-out on clinic server: $e',
          errorCode: 'DATABASE_UPDATE_FAILED',
        );
      }
    }

    final idx = _records.indexWhere((r) => r.id == existing.id);
    if (idx != -1) {
      _records[idx] = updated;
      notifyListeners();
    }

    return AttendanceActionResult(
      isSuccess: true,
      record: updated,
      message: 'Check-out recorded successfully at ${updated.formattedCheckOut}.',
    );
  }

  /// Returns total counts for today
  Map<String, int> get todayStats {
    final todayList = _records.where((r) => r.date == todayDateStr).toList();
    final present = todayList.length;
    final checkedOut = todayList.where((r) => r.isCheckedOut).length;
    final lateCount = todayList.where((r) => r.status == AttendanceDayStatus.lateArrival).length;

    return {
      'present': present,
      'checkedOut': checkedOut,
      'late': lateCount,
    };
  }

  Future<void> _syncToSupabase(AttendanceRecord record) async {
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('attendance').insert(record.toMap());
      } catch (e) {
        // Safe offline / local fallback
      }
    }
  }
}
