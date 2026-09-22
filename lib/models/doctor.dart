enum DoctorStatus {
  available,
  inConsultation,
  busy,
  onBreak,
  unavailable,
}

extension DoctorStatusExt on DoctorStatus {
  String get label {
    switch (this) {
      case DoctorStatus.available:
        return 'Available';
      case DoctorStatus.inConsultation:
        return 'In Consultation';
      case DoctorStatus.busy:
        return 'Busy';
      case DoctorStatus.onBreak:
        return 'On Break';
      case DoctorStatus.unavailable:
        return 'Unavailable';
    }
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String qualification;
  final DoctorStatus status;
  final String? currentPatientName;
  final String nextAvailableTime;
  final String roomNumber;
  final String phone;
  final String avatarInitials;
  final int todayAppointmentsCount;
  final int completedTodayCount;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.qualification,
    required this.status,
    this.currentPatientName,
    required this.nextAvailableTime,
    required this.roomNumber,
    required this.phone,
    required this.avatarInitials,
    this.todayAppointmentsCount = 0,
    this.completedTodayCount = 0,
  });

  Doctor copyWith({
    String? id,
    String? name,
    String? specialization,
    String? qualification,
    DoctorStatus? status,
    String? currentPatientName,
    String? nextAvailableTime,
    String? roomNumber,
    String? phone,
    String? avatarInitials,
    int? todayAppointmentsCount,
    int? completedTodayCount,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      status: status ?? this.status,
      currentPatientName: currentPatientName ?? this.currentPatientName,
      nextAvailableTime: nextAvailableTime ?? this.nextAvailableTime,
      roomNumber: roomNumber ?? this.roomNumber,
      phone: phone ?? this.phone,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      todayAppointmentsCount: todayAppointmentsCount ?? this.todayAppointmentsCount,
      completedTodayCount: completedTodayCount ?? this.completedTodayCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'qualification': qualification,
      'status': status.name,
      'current_patient_name': currentPatientName,
      'next_available_time': nextAvailableTime,
      'room_number': roomNumber,
      'phone': phone,
      'avatar_initials': avatarInitials,
      'today_appointments_count': todayAppointmentsCount,
      'completed_today_count': completedTodayCount,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    DoctorStatus parseStatus(String? val) {
      if (val == null) return DoctorStatus.available;
      for (final s in DoctorStatus.values) {
        if (s.name.toLowerCase() == val.toLowerCase()) return s;
      }
      return DoctorStatus.available;
    }

    return Doctor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      specialization: map['specialization']?.toString() ?? '',
      qualification: map['qualification']?.toString() ?? '',
      status: parseStatus(map['status']?.toString()),
      currentPatientName: map['current_patient_name']?.toString(),
      nextAvailableTime: map['next_available_time']?.toString() ?? '10:00 AM',
      roomNumber: map['room_number']?.toString() ?? 'Operatory 1',
      phone: map['phone']?.toString() ?? '',
      avatarInitials: map['avatar_initials']?.toString() ?? 'DR',
      todayAppointmentsCount: (map['today_appointments_count'] as num?)?.toInt() ?? 0,
      completedTodayCount: (map['completed_today_count'] as num?)?.toInt() ?? 0,
    );
  }
}
