import 'package:flutter/material.dart';

enum ToothStatus {
  healthy,
  caries,
  filling,
  crown,
  rootCanal,
  extraction,
  missing,
  implant,
  bridge,
  denture,
  fracture,
  underTreatment,
  requiresFollowUp;

  String get label {
    switch (this) {
      case ToothStatus.healthy:
        return 'Healthy';
      case ToothStatus.caries:
        return 'Caries / Cavity';
      case ToothStatus.filling:
        return 'Filling / Restored';
      case ToothStatus.crown:
        return 'Crown';
      case ToothStatus.rootCanal:
        return 'Root Canal (RCT)';
      case ToothStatus.extraction:
        return 'Extracted';
      case ToothStatus.missing:
        return 'Missing';
      case ToothStatus.implant:
        return 'Implant';
      case ToothStatus.bridge:
        return 'Bridge';
      case ToothStatus.denture:
        return 'Denture';
      case ToothStatus.fracture:
        return 'Fractured';
      case ToothStatus.underTreatment:
        return 'Under Treatment';
      case ToothStatus.requiresFollowUp:
        return 'Requires Follow-up';
    }
  }

  Color get color {
    switch (this) {
      case ToothStatus.healthy:
        return const Color(0xFF16A34A); // Green
      case ToothStatus.caries:
        return const Color(0xFFDC2626); // Red
      case ToothStatus.filling:
        return const Color(0xFF2563EB); // Blue
      case ToothStatus.crown:
        return const Color(0xFFD97706); // Amber / Gold
      case ToothStatus.rootCanal:
        return const Color(0xFF7C3AED); // Purple
      case ToothStatus.extraction:
      case ToothStatus.missing:
        return const Color(0xFF64748B); // Slate Gray
      case ToothStatus.implant:
        return const Color(0xFF0D9488); // Teal
      case ToothStatus.bridge:
      case ToothStatus.denture:
        return const Color(0xFF4F46E5); // Indigo
      case ToothStatus.fracture:
        return const Color(0xFFEA580C); // Dark Orange
      case ToothStatus.underTreatment:
        return const Color(0xFFF59E0B); // Amber
      case ToothStatus.requiresFollowUp:
        return const Color(0xFFE11D48); // Rose
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ToothStatus.healthy:
        return const Color(0xFFDCFCE7);
      case ToothStatus.caries:
        return const Color(0xFFFEE2E2);
      case ToothStatus.filling:
        return const Color(0xFFDBEAFE);
      case ToothStatus.crown:
        return const Color(0xFFFEF3C7);
      case ToothStatus.rootCanal:
        return const Color(0xFFF3E8FF);
      case ToothStatus.extraction:
      case ToothStatus.missing:
        return const Color(0xFFF1F5F9);
      case ToothStatus.implant:
        return const Color(0xFFCCFBF1);
      case ToothStatus.bridge:
      case ToothStatus.denture:
        return const Color(0xFFEEF2FF);
      case ToothStatus.fracture:
        return const Color(0xFFFFEDD5);
      case ToothStatus.underTreatment:
        return const Color(0xFFFEF9C3);
      case ToothStatus.requiresFollowUp:
        return const Color(0xFFFFE4E6);
    }
  }

  static ToothStatus fromString(String val) {
    for (final s in ToothStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase()) {
        return s;
      }
    }
    return ToothStatus.healthy;
  }
}

enum ToothTreatmentCompletionStatus {
  planned,
  inProgress,
  completed,
  requiresFollowUp;

  String get label {
    switch (this) {
      case ToothTreatmentCompletionStatus.planned:
        return 'Planned';
      case ToothTreatmentCompletionStatus.inProgress:
        return 'In Progress';
      case ToothTreatmentCompletionStatus.completed:
        return 'Completed';
      case ToothTreatmentCompletionStatus.requiresFollowUp:
        return 'Follow-Up Needed';
    }
  }

  Color get color {
    switch (this) {
      case ToothTreatmentCompletionStatus.planned:
        return const Color(0xFF64748B);
      case ToothTreatmentCompletionStatus.inProgress:
        return const Color(0xFFD97706);
      case ToothTreatmentCompletionStatus.completed:
        return const Color(0xFF16A34A);
      case ToothTreatmentCompletionStatus.requiresFollowUp:
        return const Color(0xFFE11D48);
    }
  }

  static ToothTreatmentCompletionStatus fromString(String val) {
    for (final s in ToothTreatmentCompletionStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase()) {
        return s;
      }
    }
    return ToothTreatmentCompletionStatus.completed;
  }
}

class ToothRecord {
  final String id;
  final String patientId;
  final int toothNumber; // 11-18, 21-28, 31-38, 41-48
  final ToothStatus status;
  final String procedure;
  final String clinicalFinding;
  final String notes;
  final String? dentistId;
  final String dentistName;
  final DateTime treatmentDate;
  final DateTime? followUpDate;
  final ToothTreatmentCompletionStatus completionStatus;
  final String? prescriptionId;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ToothRecord({
    required this.id,
    required this.patientId,
    required this.toothNumber,
    required this.status,
    this.procedure = '',
    this.clinicalFinding = '',
    this.notes = '',
    this.dentistId,
    this.dentistName = '',
    required this.treatmentDate,
    this.followUpDate,
    this.completionStatus = ToothTreatmentCompletionStatus.completed,
    this.prescriptionId,
    this.attachmentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if FDI tooth number is valid (11-18, 21-28, 31-38, 41-48)
  static bool isValidFdi(int num) {
    return (num >= 11 && num <= 18) ||
        (num >= 21 && num <= 28) ||
        (num >= 31 && num <= 38) ||
        (num >= 41 && num <= 48);
  }

  /// Quadrant identifier: 1, 2, 3, or 4
  int get quadrant => toothNumber ~/ 10;

  /// Tooth position within quadrant: 1 to 8
  int get position => toothNumber % 10;

  /// Dental anatomy label for tooth
  String get toothName {
    final type = _getToothType(position);
    final quad = _getQuadrantShort(quadrant);
    return '$quad $type (#$toothNumber)';
  }

  /// Full clinical description
  String get fullToothLabel {
    final type = _getToothType(position);
    final quad = _getQuadrantFull(quadrant);
    return '$quad $type (FDI #$toothNumber)';
  }

  static String _getToothType(int pos) {
    switch (pos) {
      case 1:
        return 'Central Incisor';
      case 2:
        return 'Lateral Incisor';
      case 3:
        return 'Canine (Cuspid)';
      case 4:
        return 'First Premolar (Bicuspid)';
      case 5:
        return 'Second Premolar (Bicuspid)';
      case 6:
        return 'First Molar (6-yr)';
      case 7:
        return 'Second Molar (12-yr)';
      case 8:
        return 'Third Molar (Wisdom)';
      default:
        return 'Tooth';
    }
  }

  static String _getQuadrantShort(int quad) {
    switch (quad) {
      case 1:
        return 'Upper Right';
      case 2:
        return 'Upper Left';
      case 3:
        return 'Lower Left';
      case 4:
        return 'Lower Right';
      default:
        return '';
    }
  }

  static String _getQuadrantFull(int quad) {
    switch (quad) {
      case 1:
        return 'Maxillary Right Quadrant 1';
      case 2:
        return 'Maxillary Left Quadrant 2';
      case 3:
        return 'Mandibular Left Quadrant 3';
      case 4:
        return 'Mandibular Right Quadrant 4';
      default:
        return '';
    }
  }

  ToothRecord copyWith({
    String? id,
    String? patientId,
    int? toothNumber,
    ToothStatus? status,
    String? procedure,
    String? clinicalFinding,
    String? notes,
    String? dentistId,
    String? dentistName,
    DateTime? treatmentDate,
    DateTime? followUpDate,
    ToothTreatmentCompletionStatus? completionStatus,
    String? prescriptionId,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ToothRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      toothNumber: toothNumber ?? this.toothNumber,
      status: status ?? this.status,
      procedure: procedure ?? this.procedure,
      clinicalFinding: clinicalFinding ?? this.clinicalFinding,
      notes: notes ?? this.notes,
      dentistId: dentistId ?? this.dentistId,
      dentistName: dentistName ?? this.dentistName,
      treatmentDate: treatmentDate ?? this.treatmentDate,
      followUpDate: followUpDate ?? this.followUpDate,
      completionStatus: completionStatus ?? this.completionStatus,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'tooth_number': toothNumber,
      'status': status.name,
      'procedure': procedure,
      'clinical_finding': clinicalFinding,
      'notes': notes,
      if (dentistId != null) 'dentist_id': dentistId,
      'dentist_name': dentistName,
      'treatment_date': treatmentDate.toIso8601String(),
      if (followUpDate != null) 'follow_up_date': followUpDate!.toIso8601String(),
      'completion_status': completionStatus.name,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      'attachment_urls': attachmentUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ToothRecord.fromJson(Map<String, dynamic> json) {
    return ToothRecord(
      id: json['id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      toothNumber: (json['tooth_number'] as num?)?.toInt() ?? 11,
      status: ToothStatus.fromString(json['status'] as String? ?? 'healthy'),
      procedure: json['procedure'] as String? ?? '',
      clinicalFinding: json['clinical_finding'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      dentistId: json['dentist_id'] as String?,
      dentistName: json['dentist_name'] as String? ?? '',
      treatmentDate: json['treatment_date'] != null
          ? DateTime.tryParse(json['treatment_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      followUpDate: json['follow_up_date'] != null
          ? DateTime.tryParse(json['follow_up_date'].toString())
          : null,
      completionStatus: ToothTreatmentCompletionStatus.fromString(
          json['completion_status'] as String? ?? 'completed'),
      prescriptionId: json['prescription_id'] as String?,
      attachmentUrls: json['attachment_urls'] != null
          ? List<String>.from(json['attachment_urls'] as List)
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
