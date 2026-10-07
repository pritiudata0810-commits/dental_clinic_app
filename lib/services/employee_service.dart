import 'package:flutter/foundation.dart';
import '../models/employee.dart';

/// Service managing employee directory for clinic staff.
class EmployeeService extends ChangeNotifier {
  static final EmployeeService instance = EmployeeService._internal();
  factory EmployeeService() => instance;

  EmployeeService._internal() {
    _initDefaultEmployees();
  }

  final Map<String, Employee> _employees = {};

  List<Employee> get allEmployees => _employees.values.toList();
  List<Employee> get employees => allEmployees;

  void _initDefaultEmployees() {
    _employees['REC001'] = Employee(
      id: 'REC001',
      name: 'Alfiya Shaikh',
      role: 'Receptionist',
      email: 'alfiya@smilecare.com',
      phone: '+91 98765 43210',
      department: 'Front Desk & Patient Relations',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );

    _employees['DOC001'] = Employee(
      id: 'DOC001',
      name: 'Dr. Rajesh Sharma',
      role: 'Doctor',
      email: 'rajesh@smilecare.com',
      phone: '+91 98220 11223',
      department: 'Prosthodontics & Surgery',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    );

    _employees['REC002'] = Employee(
      id: 'REC002',
      name: 'Priti Deshmukh',
      role: 'Receptionist',
      email: 'priti@smilecare.com',
      phone: '+91 98223 34455',
      department: 'Front Desk & Billing',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    );

    _employees['DOC002'] = Employee(
      id: 'DOC002',
      name: 'Dr. Priya Patel',
      role: 'Doctor',
      email: 'priya@smilecare.com',
      phone: '+91 98334 55667',
      department: 'Orthodontics',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    );
  }

  Employee? findById(String employeeId) {
    return _employees[employeeId.trim().toUpperCase()];
  }
}
