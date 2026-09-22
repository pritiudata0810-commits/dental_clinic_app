import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import 'supabase_service.dart';

class NotificationService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<NotificationItem>?> fetchNotifications() async {
    final client = _supabase.client;
    if (client == null) return null;

    try {
      final data = await client
          .from('notifications')
          .select()
          .order('timestamp', ascending: false);

      return (data as List<dynamic>)
          .map((m) => NotificationItem.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[NotificationService] Error fetching notifications: $e');
      return null;
    }
  }

  Future<bool> insertNotification(NotificationItem item) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('notifications').insert(item.toMap());
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error inserting notification: $e');
      return false;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .neq('is_read', true);
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error marking all notifications as read: $e');
      return false;
    }
  }
}
