enum AppointmentStatus {
  scheduled,
  confirmed,
  arrived,
  checkedIn,
  waiting,
  inProgress, // With Doctor
  completed,
  cancelled,
  noShow,
}

extension AppointmentStatusExt on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.arrived:
        return 'Arrived';
      case AppointmentStatus.checkedIn:
        return 'Checked In';
      case AppointmentStatus.waiting:
        return 'Waiting';
      case AppointmentStatus.inProgress:
        return 'With Doctor';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  bool get isWaitingRoomActive {
    return this == AppointmentStatus.arrived ||
        this == AppointmentStatus.checkedIn ||
        this == AppointmentStatus.waiting ||
        this == AppointmentStatus.inProgress;
  }
}

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String doctorId;
  final String doctorName;
  final DateTime dateTime;
  final String timeString; // e.g. "09:30 AM"
  final String appointmentType; // Consultation, Routine Checkup, Cleaning, Root Canal, Dental Filling, etc.
  final int durationMinutes;
  final AppointmentStatus status;
  final String tokenNumber; // e.g. "TK-04"
  final String? roomNumber;
  final String notes;
  final DateTime? checkInTime;
  final int waitMinutes;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    required this.dateTime,
    required this.timeString,
    required this.appointmentType,
    this.durationMinutes = 30,
    required this.status,
    required this.tokenNumber,
    this.roomNumber,
    this.notes = '',
    this.checkInTime,
    this.waitMinutes = 0,
  });

  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? doctorId,
    String? doctorName,
    DateTime? dateTime,
    String? timeString,
    String? appointmentType,
    int? durationMinutes,
    AppointmentStatus? status,
    String? tokenNumber,
    String? roomNumber,
    String? notes,
    DateTime? checkInTime,
    int? waitMinutes,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      dateTime: dateTime ?? this.dateTime,
      timeString: timeString ?? this.timeString,
      appointmentType: appointmentType ?? this.appointmentType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      roomNumber: roomNumber ?? this.roomNumber,
      notes: notes ?? this.notes,
      checkInTime: checkInTime ?? this.checkInTime,
      waitMinutes: waitMinutes ?? this.waitMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'date_time': dateTime.toIso8601String(),
      'time_string': timeString,
      'appointment_type': appointmentType,
      'duration_minutes': durationMinutes,
      'status': status.name,
      'token_number': tokenNumber,
      'room_number': roomNumber,
      'notes': notes,
      'check_in_time': checkInTime?.toIso8601String(),
      'wait_minutes': waitMinutes,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    AppointmentStatus parseStatus(String? val) {
      if (val == null) return AppointmentStatus.scheduled;
      for (final s in AppointmentStatus.values) {
        if (s.name.toLowerCase() == val.toLowerCase()) return s;
      }
      return AppointmentStatus.scheduled;
    }

    return Appointment(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      patientName: map['patient_name']?.toString() ?? '',
      patientPhone: map['patient_phone']?.toString() ?? '',
      doctorId: map['doctor_id']?.toString() ?? '',
      doctorName: map['doctor_name']?.toString() ?? '',
      dateTime: map['date_time'] != null
          ? DateTime.tryParse(map['date_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeString: map['time_string']?.toString() ?? '',
      appointmentType: map['appointment_type']?.toString() ?? 'General Consultation',
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 30,
      status: parseStatus(map['status']?.toString()),
      tokenNumber: map['token_number']?.toString() ?? '',
      roomNumber: map['room_number']?.toString(),
      notes: map['notes']?.toString() ?? '',
      checkInTime: map['check_in_time'] != null
          ? DateTime.tryParse(map['check_in_time'].toString())
          : null,
      waitMinutes: (map['wait_minutes'] as num?)?.toInt() ?? 0,
    );
  }
}
