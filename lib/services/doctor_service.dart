import 'package:flutter/foundation.dart';
import '../models/doctor.dart';
import 'supabase_service.dart';

class DoctorService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<Doctor>?> fetchDoctors() async {
    final client = _supabase.client;
    if (client == null) return null;

    try {
      final data = await client
          .from('doctors')
          .select()
          .order('name', ascending: true);

      return (data as List<dynamic>)
          .map((m) => Doctor.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[DoctorService] Error fetching doctors: $e');
      return null;
    }
  }

  Future<bool> updateStatus(
    String doctorId,
    DoctorStatus status, {
    String? currentPatientName,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('doctors').update({
        'status': status.name,
        'current_patient_name': currentPatientName,
      }).eq('id', doctorId);
      return true;
    } catch (e) {
      debugPrint('[DoctorService] Error updating doctor status: $e');
      return false;
    }
  }
}
