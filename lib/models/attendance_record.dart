import 'package:intl/intl.dart';

/// Status of daily employee attendance
enum AttendanceDayStatus {
  present,
  lateArrival,
  halfDay,
  checkedOut,
}

/// Verification status for attendance audit
enum VerificationStatus {
  verified,
  failed,
  bypassed,
  pending,
}

/// Verification method used
enum VerificationMethod {
  faceBiometric,
  manualAdmin,
  passwordFallback,
}

/// Immutable record of an employee's daily attendance.
class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeRole;
  final String date; // YYYY-MM-DD
  final DateTime checkIn;
  final DateTime? checkOut;
  final VerificationMethod verificationMethod;
  final VerificationStatus faceVerificationStatus;
  final VerificationStatus livenessStatus;
  final VerificationStatus locationStatus;
  final double? distanceMeters;
  final AttendanceDayStatus status;
  final DateTime createdAt;
  final String? deviceId;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeRole,
    required this.date,
    required this.checkIn,
    this.checkOut,
    this.verificationMethod = VerificationMethod.faceBiometric,
    required this.faceVerificationStatus,
    required this.livenessStatus,
    required this.locationStatus,
    this.distanceMeters,
    this.status = AttendanceDayStatus.present,
    required this.createdAt,
    this.deviceId,
  });

  bool get isCheckedOut => checkOut != null;

  bool get isFaceMatched => faceVerificationStatus == VerificationStatus.verified;
  bool get isLivenessPassed => livenessStatus == VerificationStatus.verified;
  bool get isLocationVerified => locationStatus == VerificationStatus.verified;

  String get formattedCheckIn => DateFormat('hh:mm a').format(checkIn);
  String get formattedCheckOut => checkOut != null ? DateFormat('hh:mm a').format(checkOut!) : '--:--';

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeRole,
    String? date,
    DateTime? checkIn,
    DateTime? checkOut,
    VerificationMethod? verificationMethod,
    VerificationStatus? faceVerificationStatus,
    VerificationStatus? livenessStatus,
    VerificationStatus? locationStatus,
    double? distanceMeters,
    AttendanceDayStatus? status,
    DateTime? createdAt,
    String? deviceId,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeRole: employeeRole ?? this.employeeRole,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      faceVerificationStatus: faceVerificationStatus ?? this.faceVerificationStatus,
      livenessStatus: livenessStatus ?? this.livenessStatus,
      locationStatus: locationStatus ?? this.locationStatus,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'employee_name': employeeName,
    'employee_role': employeeRole,
    'date': date,
    'check_in': checkIn.toIso8601String(),
    'check_out': checkOut?.toIso8601String(),
    'verification_method': verificationMethod.name,
    'face_verification_status': faceVerificationStatus.name,
    'liveness_status': livenessStatus.name,
    'location_status': locationStatus.name,
    'distance_meters': distanceMeters,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'device_id': deviceId,
  };

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      employeeName: map['employee_name'] as String? ?? 'Employee',
      employeeRole: map['employee_role'] as String? ?? 'Staff',
      date: map['date'] as String,
      checkIn: DateTime.parse(map['check_in'] as String),
      checkOut: map['check_out'] != null ? DateTime.parse(map['check_out'] as String) : null,
      verificationMethod: VerificationMethod.values.firstWhere(
        (v) => v.name == map['verification_method'],
        orElse: () => VerificationMethod.faceBiometric,
      ),
      faceVerificationStatus: VerificationStatus.values.firstWhere(
        (v) => v.name == map['face_verification_status'],
        orElse: () => VerificationStatus.verified,
      ),
      livenessStatus: VerificationStatus.values.firstWhere(
        (v) => v.name == map['liveness_status'],
        orElse: () => VerificationStatus.verified,
      ),
      locationStatus: VerificationStatus.values.firstWhere(
        (v) => v.name == map['location_status'],
        orElse: () => VerificationStatus.verified,
      ),
      distanceMeters: (map['distance_meters'] as num?)?.toDouble(),
      status: AttendanceDayStatus.values.firstWhere(
        (v) => v.name == map['status'],
        orElse: () => AttendanceDayStatus.present,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      deviceId: map['device_id'] as String?,
    );
  }
}
