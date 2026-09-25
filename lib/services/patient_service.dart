import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import 'supabase_service.dart';

class PatientService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<Patient>?> fetchPatients() async {
    final client = _supabase.client;
    if (client == null) return null;

    try {
      final data = await client
          .from('patients')
          .select()
          .order('name', ascending: true);

      return (data as List<dynamic>)
          .map((m) => Patient.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[PatientService] Error fetching patients: $e');
      return null;
    }
  }

  Future<bool> insertPatient(Patient patient) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('patients').upsert(patient.toMap(includeExtendedFields: true));
      return true;
    } catch (e) {
      try {
        await client.from('patients').upsert(patient.toMap(includeExtendedFields: false));
        return true;
      } catch (inner) {
        debugPrint('[PatientService] Error inserting patient: $inner');
        return false;
      }
    }
  }

  Future<bool> updatePatient(Patient patient) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client
          .from('patients')
          .update(patient.toMap(includeExtendedFields: true))
          .eq('id', patient.id);
      return true;
    } catch (e) {
      try {
        await client
            .from('patients')
            .update(patient.toMap(includeExtendedFields: false))
            .eq('id', patient.id);
        return true;
      } catch (inner) {
        debugPrint('[PatientService] Error updating patient: $inner');
        return false;
      }
    }
  }
}
