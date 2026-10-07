import 'package:flutter/material.dart';

enum CallDirection {
  incoming,
  outgoing,
  missed,
}

extension CallDirectionExtension on CallDirection {
  String get value => name;

  static CallDirection fromString(String? val) {
    if (val == null) return CallDirection.outgoing;
    switch (val.toLowerCase().trim()) {
      case 'incoming':
        return CallDirection.incoming;
      case 'missed':
        return CallDirection.missed;
      default:
        return CallDirection.outgoing;
    }
  }
}

enum CallStatus {
  dialerOpened,
  initiated,
  completed,
  answered,
  missed,
  busy,
  declined,
  failed,
  cancelled,
}

extension CallStatusExtension on CallStatus {
  String get value {
    switch (this) {
      case CallStatus.dialerOpened:
        return 'dialer_opened';
      case CallStatus.initiated:
        return 'initiated';
      case CallStatus.completed:
        return 'completed';
      case CallStatus.answered:
        return 'answered';
      case CallStatus.missed:
        return 'missed';
      case CallStatus.busy:
        return 'busy';
      case CallStatus.declined:
        return 'declined';
      case CallStatus.failed:
        return 'failed';
      case CallStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case CallStatus.dialerOpened:
        return 'Dialer Opened';
      case CallStatus.initiated:
        return 'Initiated';
      case CallStatus.completed:
        return 'Completed';
      case CallStatus.answered:
        return 'Answered';
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.busy:
        return 'Busy';
      case CallStatus.declined:
        return 'Declined';
      case CallStatus.failed:
        return 'Failed';
      case CallStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get badgeColor {
    switch (this) {
      case CallStatus.dialerOpened:
        return const Color(0xFF2563EB); // Blue
      case CallStatus.initiated:
        return const Color(0xFF0284C7); // Sky Blue
      case CallStatus.completed:
      case CallStatus.answered:
        return const Color(0xFF10B981); // Green
      case CallStatus.missed:
      case CallStatus.failed:
        return const Color(0xFFEF4444); // Red
      case CallStatus.busy:
      case CallStatus.declined:
        return const Color(0xFFF59E0B); // Amber
      case CallStatus.cancelled:
        return const Color(0xFF6B7280); // Gray
    }
  }

  static CallStatus fromString(String? val) {
    if (val == null) return CallStatus.dialerOpened;
    switch (val.toLowerCase().trim()) {
      case 'dialer_opened':
        return CallStatus.dialerOpened;
      case 'initiated':
        return CallStatus.initiated;
      case 'completed':
        return CallStatus.completed;
      case 'answered':
        return CallStatus.answered;
      case 'missed':
        return CallStatus.missed;
      case 'busy':
        return CallStatus.busy;
      case 'declined':
        return CallStatus.declined;
      case 'failed':
        return CallStatus.failed;
      case 'cancelled':
        return CallStatus.cancelled;
      default:
        return CallStatus.dialerOpened;
    }
  }
}

class CallRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final DateTime timestamp;
  final int durationSeconds;
  final CallDirection direction;
  final CallStatus status;
  final String? staffUserId;
  final String? staffName;
  final String clinicId;
  final String callType;
  final String? note;
  final String? errorMessage;

  const CallRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    required this.timestamp,
    required this.durationSeconds,
    required this.direction,
    required this.status,
    this.staffUserId,
    this.staffName,
    this.clinicId = 'CLINIC-01',
    this.callType = 'voice',
    this.note,
    this.errorMessage,
  });

  String get durationFormatted {
    if (durationSeconds <= 0) {
      if (status == CallStatus.dialerOpened) return 'Dialer opened';
      if (status == CallStatus.failed) return 'Failed';
      return '0s';
    }
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    if (mins > 0) {
      return '${mins}m ${secs}s';
    }
    return '${secs}s';
  }

  factory CallRecord.fromMap(Map<String, dynamic> map) {
    return CallRecord(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      patientName: map['patient_name']?.toString() ?? '',
      phoneNumber: map['phone_number']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : (map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      direction: CallDirectionExtension.fromString(map['direction']?.toString()),
      status: CallStatusExtension.fromString(map['status']?.toString()),
      staffUserId: map['staff_user_id']?.toString(),
      staffName: map['staff_name']?.toString(),
      clinicId: map['clinic_id']?.toString() ?? 'CLINIC-01',
      callType: map['call_type']?.toString() ?? 'voice',
      note: map['note']?.toString(),
      errorMessage: map['error_message']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'phone_number': phoneNumber,
      'timestamp': timestamp.toIso8601String(),
      'duration_seconds': durationSeconds,
      'direction': direction.value,
      'status': status.value,
      'staff_user_id': staffUserId,
      'staff_name': staffName,
      'clinic_id': clinicId,
      'call_type': callType,
      'note': note,
      'error_message': errorMessage,
    };
  }

  CallRecord copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? phoneNumber,
    DateTime? timestamp,
    int? durationSeconds,
    CallDirection? direction,
    CallStatus? status,
    String? staffUserId,
    String? staffName,
    String? clinicId,
    String? callType,
    String? note,
    String? errorMessage,
  }) {
    return CallRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      timestamp: timestamp ?? this.timestamp,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      staffUserId: staffUserId ?? this.staffUserId,
      staffName: staffName ?? this.staffName,
      clinicId: clinicId ?? this.clinicId,
      callType: callType ?? this.callType,
      note: note ?? this.note,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum MessageChannel {
  sms,
  whatsapp,
}

enum MessageDeliveryStatus {
  sent,
  delivered,
  failed,
  read,
}

class MessageRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final MessageChannel channel;
  final String message;
  final String templateCategory;
  final DateTime timestamp;
  final MessageDeliveryStatus status;

  const MessageRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    required this.channel,
    required this.message,
    required this.templateCategory,
    required this.timestamp,
    required this.status,
  });

  factory MessageRecord.fromMap(Map<String, dynamic> map) {
    return MessageRecord(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      patientName: map['patient_name']?.toString() ?? '',
      phoneNumber: map['phone_number']?.toString() ?? '',
      channel: map['channel'] == 'whatsapp' ? MessageChannel.whatsapp : MessageChannel.sms,
      message: map['message']?.toString() ?? '',
      templateCategory: map['template_category']?.toString() ?? 'General',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: MessageDeliveryStatus.sent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'phone_number': phoneNumber,
      'channel': channel.name,
      'message': message,
      'template_category': templateCategory,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }
}
