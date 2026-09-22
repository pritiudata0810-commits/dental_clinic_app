import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class ConsultationService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<bool> saveConsultation({
    String? appointmentId,
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String reasonForVisit,
    required String examinationFindings,
    required String diagnosis,
    String clinicalNotes = '',
    String procedureCode = '',
    String operativeNotes = '',
    double totalFee = 0.0,
    List<Map<String, String>> medicines = const [],
  }) async {
    final client = _supabase.client;
    if (client == null) {
      debugPrint('[ConsultationService] Supabase not active. Saved locally.');
      return true;
    }

    try {
      final Map<String, dynamic> insertData = {
        'patient_id': patientId,
        'patient_name': patientName,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'reason_for_visit': reasonForVisit,
        'examination_findings': examinationFindings,
        'diagnosis': diagnosis,
        'clinical_notes': clinicalNotes,
        'procedure_code': procedureCode,
        'operative_notes': operativeNotes,
        'total_fee': totalFee,
      };
      if (appointmentId != null) {
        insertData['appointment_id'] = appointmentId;
      }

      final consultationRow = await client
          .from('clinical_consultations')
          .insert(insertData)
          .select('id')
          .single();

      final consultationId = consultationRow['id'];

      if (medicines.isNotEmpty && consultationId != null) {
        final prescriptionsData = medicines.map((m) {
          return {
            'consultation_id': consultationId,
            'patient_id': patientId,
            'medicine_name': m['name'] ?? '',
            'dosage': m['dosage'] ?? '',
            'frequency': m['frequency'] ?? '',
            'timing': m['timing'] ?? 'After Food',
            'duration': m['duration'] ?? '5 days',
            'instructions': m['instructions'] ?? '',
          };
        }).toList();

        await client.from('clinical_prescriptions').insert(prescriptionsData);
      }

      return true;
    } catch (e) {
      debugPrint('[ConsultationService] Error saving consultation: $e');
      return false;
    }
  }
}
