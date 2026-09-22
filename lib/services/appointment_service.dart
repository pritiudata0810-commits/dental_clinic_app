import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import 'supabase_service.dart';

class AppointmentService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<Appointment>?> fetchAppointments() async {
    final client = _supabase.client;
    if (client == null) return null;

    try {
      final data = await client
          .from('appointments')
          .select()
          .order('date_time', ascending: true);

      return (data as List<dynamic>)
          .map((m) => Appointment.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[AppointmentService] Error fetching appointments: $e');
      return null;
    }
  }

  Future<bool> insertAppointment(Appointment appointment) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('appointments').upsert(appointment.toMap());
      return true;
    } catch (e) {
      debugPrint('[AppointmentService] Error inserting appointment: $e');
      return false;
    }
  }

  Future<bool> updateStatus(
    String appointmentId,
    AppointmentStatus status, {
    DateTime? checkInTime,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };
      if (checkInTime != null) {
        updateData['check_in_time'] = checkInTime.toIso8601String();
      }

      await client
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);
      return true;
    } catch (e) {
      debugPrint('[AppointmentService] Error updating appointment status: $e');
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    return updateStatus(appointmentId, AppointmentStatus.cancelled);
  }
}
