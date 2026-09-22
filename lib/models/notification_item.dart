import 'package:flutter/material.dart';

enum NotificationType {
  appointment,
  checkIn,
  doctorAvailable,
  paymentPending,
  reminder,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.appointment:
        return Icons.calendar_month_outlined;
      case NotificationType.checkIn:
        return Icons.how_to_reg_outlined;
      case NotificationType.doctorAvailable:
        return Icons.person_pin_circle_outlined;
      case NotificationType.paymentPending:
        return Icons.payments_outlined;
      case NotificationType.reminder:
        return Icons.alarm_outlined;
    }
  }

  Color get accentColor {
    switch (type) {
      case NotificationType.appointment:
        return const Color(0xFF0284C7);
      case NotificationType.checkIn:
        return const Color(0xFF10B981);
      case NotificationType.doctorAvailable:
        return const Color(0xFF8B5CF6);
      case NotificationType.paymentPending:
        return const Color(0xFFF59E0B);
      case NotificationType.reminder:
        return const Color(0xFF0EA5E9);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'type': type.name,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    NotificationType parseType(String? val) {
      if (val == null) return NotificationType.appointment;
      for (final t in NotificationType.values) {
        if (t.name.toLowerCase() == val.toLowerCase()) return t;
      }
      return NotificationType.appointment;
    }

    return NotificationItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['is_read'] == true,
      type: parseType(map['type']?.toString()),
    );
  }
}
