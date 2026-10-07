/// Explicit user roles supported by the clinic OS
enum UserRole {
  doctor,
  receptionist,
  admin,
  patient,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.doctor:
        return 'doctor';
      case UserRole.receptionist:
        return 'receptionist';
      case UserRole.admin:
        return 'admin';
      case UserRole.patient:
        return 'patient';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.receptionist:
        return 'Receptionist';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.patient:
        return 'Patient';
    }
  }

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.receptionist;
    switch (role.toLowerCase().trim()) {
      case 'doctor':
        return UserRole.doctor;
      case 'receptionist':
        return UserRole.receptionist;
      case 'admin':
        return UserRole.admin;
      case 'patient':
        return UserRole.patient;
      default:
        return UserRole.receptionist;
    }
  }
}

/// Strongly-typed User Profile tied 1:1 with Supabase auth.users & public.profiles
class UserProfile {
  final String id; // UUID from auth.users
  final String email;
  final String fullName;
  final UserRole role;
  final String clinicId;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.clinicId = 'CLINIC-01',
    this.phone,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDoctor => role == UserRole.doctor;
  bool get isReceptionist => role == UserRole.receptionist;
  bool get isAdmin => role == UserRole.admin;
  bool get isPatient => role == UserRole.patient;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      role: UserRoleExtension.fromString(map['role']?.toString()),
      clinicId: map['clinic_id']?.toString() ?? 'CLINIC-01',
      phone: map['phone']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.value,
      'clinic_id': clinicId,
      'phone': phone,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    UserRole? role,
    String? clinicId,
    String? phone,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      clinicId: clinicId ?? this.clinicId,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'UserProfile(id: $id, email: $email, role: ${role.value}, clinicId: $clinicId)';
}
