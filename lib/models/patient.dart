class Patient {
  final String id; // e.g. "P-1001"
  final String name;
  final String phone;
  final String email;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String emergencyContact;
  final String assignedDoctorId;
  final String assignedDoctorName;
  final String lastVisit;
  final String? nextAppointment;
  final int totalVisits;
  final double balanceDue;
  final String bloodGroup;
  final List<String> allergies;
  final String notes;
  final DateTime registrationDate;
  final String crNumber;
  final String age;
  final String fatherOrGuardian;
  final List<String> medicalAlerts;

  const Patient({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.emergencyContact,
    required this.assignedDoctorId,
    required this.assignedDoctorName,
    required this.lastVisit,
    this.nextAppointment,
    this.totalVisits = 1,
    this.balanceDue = 0.0,
    this.bloodGroup = 'O+',
    this.allergies = const [],
    this.notes = '',
    required this.registrationDate,
    this.crNumber = '',
    this.age = '',
    this.fatherOrGuardian = '',
    this.medicalAlerts = const [],
  });

  Patient copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? emergencyContact,
    String? assignedDoctorId,
    String? assignedDoctorName,
    String? lastVisit,
    String? nextAppointment,
    int? totalVisits,
    double? balanceDue,
    String? bloodGroup,
    List<String>? allergies,
    String? notes,
    DateTime? registrationDate,
    String? crNumber,
    String? age,
    String? fatherOrGuardian,
    List<String>? medicalAlerts,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      assignedDoctorName: assignedDoctorName ?? this.assignedDoctorName,
      lastVisit: lastVisit ?? this.lastVisit,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      totalVisits: totalVisits ?? this.totalVisits,
      balanceDue: balanceDue ?? this.balanceDue,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      notes: notes ?? this.notes,
      registrationDate: registrationDate ?? this.registrationDate,
      crNumber: crNumber ?? this.crNumber,
      age: age ?? this.age,
      fatherOrGuardian: fatherOrGuardian ?? this.fatherOrGuardian,
      medicalAlerts: medicalAlerts ?? this.medicalAlerts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'address': address,
      'emergency_contact': emergencyContact,
      'assigned_doctor_id': assignedDoctorId,
      'assigned_doctor_name': assignedDoctorName,
      'last_visit': lastVisit,
      'next_appointment': nextAppointment,
      'total_visits': totalVisits,
      'balance_due': balanceDue,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'notes': notes,
      'registration_date': registrationDate.toIso8601String(),
      'cr_number': crNumber,
      'age': age,
      'father_or_guardian': fatherOrGuardian,
      'medical_alerts': medicalAlerts,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      dateOfBirth: map['date_of_birth']?.toString() ?? '',
      gender: map['gender']?.toString() ?? 'Other',
      address: map['address']?.toString() ?? '',
      emergencyContact: map['emergency_contact']?.toString() ?? '',
      assignedDoctorId: map['assigned_doctor_id']?.toString() ?? '',
      assignedDoctorName: map['assigned_doctor_name']?.toString() ?? '',
      lastVisit: map['last_visit']?.toString() ?? 'First Visit',
      nextAppointment: map['next_appointment']?.toString(),
      totalVisits: (map['total_visits'] as num?)?.toInt() ?? 1,
      balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
      bloodGroup: map['blood_group']?.toString() ?? 'O+',
      allergies: (map['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      notes: map['notes']?.toString() ?? '',
      registrationDate: map['registration_date'] != null
          ? DateTime.tryParse(map['registration_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      crNumber: map['cr_number']?.toString() ?? '',
      age: map['age']?.toString() ?? '',
      fatherOrGuardian: map['father_or_guardian']?.toString() ?? '',
      medicalAlerts: (map['medical_alerts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
