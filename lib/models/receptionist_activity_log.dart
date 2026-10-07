enum ActivityActionType {
  faceLogin,
  passwordLogin,
  faceVerificationSuccess,
  faceVerificationFailure,
  geofenceCheckSuccess,
  geofenceCheckFailure,
  sessionLock,
  sessionUnlock,
  locationRecheckAlert,
  logout,
  patientSearch,
  patientRegistration,
  appointmentCreated,
  appointmentCancelled,
  appointmentRescheduled,
  paymentRecorded,
  reminderSent,
  unrecognizedPersonAlert,
}

class ReceptionistActivityLog {
  final String id;
  final String receptionistName;
  final ActivityActionType actionType;
  final String actionLabel;
  final String authMethod; // "Face", "Password", "System", "GPS"
  final String authMode; // "REAL" or "DEMO"
  final DateTime timestamp;
  final String details;
  final bool isSecurityAlert;
  final double? distanceMeters;
  final String? geofenceStatus;

  const ReceptionistActivityLog({
    required this.id,
    required this.receptionistName,
    required this.actionType,
    required this.actionLabel,
    this.authMethod = 'Face',
    this.authMode = 'DEMO',
    required this.timestamp,
    required this.details,
    this.isSecurityAlert = false,
    this.distanceMeters,
    this.geofenceStatus,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'receptionist_name': receptionistName,
        'action_type': actionType.name,
        'action_label': actionLabel,
        'auth_method': authMethod,
        'auth_mode': authMode,
        'timestamp': timestamp.toIso8601String(),
        'details': details,
        'is_security_alert': isSecurityAlert,
        'distance_meters': distanceMeters,
        'geofence_status': geofenceStatus,
      };

  factory ReceptionistActivityLog.fromMap(Map<String, dynamic> map) {
    final typeName = map['action_type']?.toString() ?? 'faceLogin';
    final actionType = ActivityActionType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => ActivityActionType.faceLogin,
    );

    return ReceptionistActivityLog(
      id: map['id']?.toString() ?? '',
      receptionistName: map['receptionist_name']?.toString() ?? 'Alfiya',
      actionType: actionType,
      actionLabel: map['action_label']?.toString() ?? 'Activity',
      authMethod: map['auth_method']?.toString() ?? 'Face',
      authMode: map['auth_mode']?.toString() ?? 'DEMO',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      details: map['details']?.toString() ?? '',
      isSecurityAlert: map['is_security_alert'] as bool? ?? false,
      distanceMeters: (map['distance_meters'] as num?)?.toDouble(),
      geofenceStatus: map['geofence_status']?.toString(),
    );
  }
}
