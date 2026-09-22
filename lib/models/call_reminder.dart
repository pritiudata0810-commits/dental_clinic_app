enum ReminderStatus {
  pending,
  called,
  answered,
  missed,
  retryRequired,
  confirmed,
  cancelled,
}

extension ReminderStatusExt on ReminderStatus {
  String get label {
    switch (this) {
      case ReminderStatus.pending:
        return 'Pending';
      case ReminderStatus.called:
        return 'Called';
      case ReminderStatus.answered:
        return 'Answered';
      case ReminderStatus.missed:
        return 'Missed';
      case ReminderStatus.retryRequired:
        return 'Retry Required';
      case ReminderStatus.confirmed:
        return 'Confirmed';
      case ReminderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class CallReminder {
  final String id;
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final String appointmentDate; // e.g. "21 Sep 2026"
  final String appointmentTime; // e.g. "10:30 AM"
  final String doctorName;
  final ReminderStatus status;
  final String lastAttempt; // e.g. "Not called" or "Today 09:15 AM - Missed"
  final String nextAttempt; // e.g. "Today before 12:00 PM"
  final String appointmentType;
  final String notes;

  const CallReminder({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.doctorName,
    required this.status,
    required this.lastAttempt,
    required this.nextAttempt,
    this.appointmentType = 'Consultation',
    this.notes = '',
  });

  CallReminder copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? phoneNumber,
    String? appointmentDate,
    String? appointmentTime,
    String? doctorName,
    ReminderStatus? status,
    String? lastAttempt,
    String? nextAttempt,
    String? appointmentType,
    String? notes,
  }) {
    return CallReminder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      doctorName: doctorName ?? this.doctorName,
      status: status ?? this.status,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      nextAttempt: nextAttempt ?? this.nextAttempt,
      appointmentType: appointmentType ?? this.appointmentType,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'phone_number': phoneNumber,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'doctor_name': doctorName,
      'status': status.name,
      'last_attempt': lastAttempt,
      'next_attempt': nextAttempt,
      'appointment_type': appointmentType,
      'notes': notes,
    };
  }

  factory CallReminder.fromMap(Map<String, dynamic> map) {
    ReminderStatus parseStatus(String? val) {
      if (val == null) return ReminderStatus.pending;
      for (final s in ReminderStatus.values) {
        if (s.name.toLowerCase() == val.toLowerCase()) return s;
      }
      return ReminderStatus.pending;
    }

    return CallReminder(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      patientName: map['patient_name']?.toString() ?? '',
      phoneNumber: map['phone_number']?.toString() ?? '',
      appointmentDate: map['appointment_date']?.toString() ?? '',
      appointmentTime: map['appointment_time']?.toString() ?? '',
      doctorName: map['doctor_name']?.toString() ?? '',
      status: parseStatus(map['status']?.toString()),
      lastAttempt: map['last_attempt']?.toString() ?? 'Not called',
      nextAttempt: map['next_attempt']?.toString() ?? 'Today before 12:00 PM',
      appointmentType: map['appointment_type']?.toString() ?? 'Consultation',
      notes: map['notes']?.toString() ?? '',
    );
  }
}
