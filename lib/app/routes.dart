import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/doctor/main_shell.dart';
import '../widgets/layout/app_shell.dart';

class AppRoutes {
  static const String login = '/login';
  static const String receptionist = '/receptionist';
  static const String doctor = '/doctor';
  static const String doctorStub = '/doctor-stub';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginScreen(),
      receptionist: (context) => const AppShell(),
      doctor: (context) => const MainShell(),
      doctorStub: (context) => const MainShell(),
    };
  }
}
