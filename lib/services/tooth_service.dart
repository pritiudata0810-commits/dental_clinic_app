import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tooth_record.dart';
import 'supabase_service.dart';

class ToothService {
  final SupabaseService _supabase = SupabaseService.instance;

  /// Fetch tooth records from Supabase, optionally filtered by patient ID
  Future<List<ToothRecord>?> fetchToothRecords({String? patientId}) async {
    final client = _supabase.client;
    if (client == null) {
      debugPrint('[ToothService] Supabase not connected. Using local data.');
      return null;
    }

    try {
      var query = client.from('patient_tooth_records').select();
      if (patientId != null && patientId.isNotEmpty) {
        query = query.eq('patient_id', patientId);
      }

      final response = await query.order('treatment_date', ascending: false);
      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) => ToothRecord.fromJson(json as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      debugPrint('[ToothService] PostgrestException fetching tooth records: '
          'code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}');
      return null;
    } catch (e) {
      debugPrint('[ToothService] Error fetching tooth records: $e');
      return null;
    }
  }

  /// Insert or update a tooth record in Supabase
  Future<ToothRecord?> saveToothRecord(ToothRecord record) async {
    final client = _supabase.client;
    if (client == null) {
      debugPrint('[ToothService] Supabase not connected. Cannot persist tooth record.');
      return null;
    }

    try {
      final payload = record.toJson();
      final res = await client
          .from('patient_tooth_records')
          .upsert(payload)
          .select()
          .single();

      return ToothRecord.fromJson(Map<String, dynamic>.from(res));
    } on PostgrestException catch (e) {
      debugPrint('[ToothService] PostgrestException saving tooth record: '
          'code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}');
      return null;
    } catch (e) {
      debugPrint('[ToothService] Error saving tooth record: $e');
      return null;
    }
  }

  /// Delete a tooth record
  Future<bool> deleteToothRecord(String id) async {
    final client = _supabase.client;
    if (client == null) {
      debugPrint('[ToothService] Supabase not connected. Cannot delete tooth record.');
      return false;
    }

    try {
      await client.from('patient_tooth_records').delete().eq('id', id);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('[ToothService] PostgrestException deleting tooth record: '
          'code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}');
      return false;
    } catch (e) {
      debugPrint('[ToothService] Error deleting tooth record: $e');
      return false;
    }
  }
}
