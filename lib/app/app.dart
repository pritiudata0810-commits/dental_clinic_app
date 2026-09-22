import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/clinic_state.dart';
import '../state/clinic_scope.dart';
import 'routes.dart';

class DentalClinicApp extends StatefulWidget {
  const DentalClinicApp({super.key});

  @override
  State<DentalClinicApp> createState() => _DentalClinicAppState();
}

class _DentalClinicAppState extends State<DentalClinicApp> {
  late final ClinicState _clinicState;

  @override
  void initState() {
    super.initState();
    _clinicState = ClinicState();
  }

  @override
  void dispose() {
    _clinicState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClinicScope(
      state: _clinicState,
      child: MaterialApp(
        title: 'SmileCare Dental Clinic OS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
      ),
    );
  }
}
