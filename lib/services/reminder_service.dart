import 'package:flutter/foundation.dart';
import '../models/call_reminder.dart';
import '../models/communication.dart';
import 'supabase_service.dart';

class ReminderService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<CallReminder>?> fetchReminders() async {
    final client = _supabase.client;
    if (client == null) return null;

    try {
      final data = await client
          .from('call_reminders')
          .select()
          .order('appointment_time', ascending: true);

      return (data as List<dynamic>)
          .map((m) => CallReminder.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ReminderService] Error fetching reminders: $e');
      return null;
    }
  }

  Future<bool> updateStatus(
    String reminderId,
    ReminderStatus status, {
    String? lastAttempt,
    String? nextAttempt,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };
      if (lastAttempt != null) updateData['last_attempt'] = lastAttempt;
      if (nextAttempt != null) updateData['next_attempt'] = nextAttempt;

      await client
          .from('call_reminders')
          .update(updateData)
          .eq('id', reminderId);
      return true;
    } catch (e) {
      debugPrint('[ReminderService] Error updating reminder status: $e');
      return false;
    }
  }

  Future<bool> logCall({
    required String id,
    required String patientId,
    required String patientName,
    required String phoneNumber,
    required CallDirection direction,
    required CallStatus status,
    required int durationSeconds,
    String? note,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('call_records').insert({
        'id': id,
        'patient_id': patientId,
        'patient_name': patientName,
        'phone_number': phoneNumber,
        'timestamp': DateTime.now().toIso8601String(),
        'duration_seconds': durationSeconds,
        'direction': direction.name,
        'status': status.name,
        'note': note,
      });
      return true;
    } catch (e) {
      debugPrint('[ReminderService] Error logging call: $e');
      return false;
    }
  }

  Future<bool> logMessage({
    required String id,
    required String patientId,
    required String patientName,
    required String phoneNumber,
    required MessageChannel channel,
    required String message,
    required String templateCategory,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('message_records').insert({
        'id': id,
        'patient_id': patientId,
        'patient_name': patientName,
        'phone_number': phoneNumber,
        'channel': channel.name,
        'message': message,
        'template_category': templateCategory,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sent',
      });
      return true;
    } catch (e) {
      debugPrint('[ReminderService] Error logging message: $e');
      return false;
    }
  }
}
