enum CallDirection {
  incoming,
  outgoing,
  missed,
}

enum CallStatus {
  answered,
  missed,
  busy,
  declined,
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
  final String? note;

  const CallRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    required this.timestamp,
    required this.durationSeconds,
    required this.direction,
    required this.status,
    this.note,
  });

  String get durationFormatted {
    if (durationSeconds <= 0) return '0s';
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    if (mins > 0) {
      return '${mins}m ${secs}s';
    }
    return '${secs}s';
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
  final String templateCategory; // "Appointment Reminder", "Follow-up", "Payment Reminder", "Custom"
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
}
