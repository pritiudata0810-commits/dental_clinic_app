import 'package:flutter/material.dart';
import 'app/app.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseConfig.logStatus();
  await SupabaseService.initialize();
  runApp(const DentalClinicApp());
}
