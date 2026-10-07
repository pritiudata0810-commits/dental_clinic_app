/// Unified employee representation for clinic staff (Receptionists, Doctors, Staff).
class Employee {
  final String id; // e.g. "REC001", "DOC001"
  final String name;
  final String role; // "Receptionist", "Doctor", "Clinic Administrator"
  final String email;
  final String phone;
  final String department;
  final DateTime createdAt;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    this.department = 'General Dentistry',
    required this.createdAt,
  });

  Employee copyWith({
    String? id,
    String? name,
    String? role,
    String? email,
    String? phone,
    String? department,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
