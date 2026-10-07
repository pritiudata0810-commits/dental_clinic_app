import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/doctor/main_shell.dart';
import '../widgets/layout/app_shell.dart';
import '../widgets/auth/auth_gate.dart';
import '../models/user_profile.dart';

class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String receptionist = '/receptionist';
  static const String doctor = '/doctor';
  static const String doctorStub = '/doctor-stub';

  static Map<String, WidgetBuilder> get routes {
    return {
      root: (context) => const AuthGate(),
      login: (context) => const LoginScreen(),
      receptionist: (context) => const RoleGuardedRoute(
            allowedRoles: [UserRole.receptionist, UserRole.admin],
            child: AppShell(),
          ),
      doctor: (context) => const RoleGuardedRoute(
            allowedRoles: [UserRole.doctor, UserRole.admin],
            child: MainShell(),
          ),
      doctorStub: (context) => const RoleGuardedRoute(
            allowedRoles: [UserRole.doctor, UserRole.admin],
            child: MainShell(),
          ),
    };
  }
}
