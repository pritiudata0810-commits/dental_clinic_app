import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_item.dart';
import 'supabase_service.dart';

class NotificationService {
  final SupabaseService _supabase = SupabaseService.instance;
  RealtimeChannel? _subscription;

  RealtimeChannel? initRealtimeSubscription({
    required void Function(NotificationItem item) onInsert,
    required void Function(NotificationItem item) onUpdate,
  }) {
    final client = _supabase.client;
    if (client == null) return null;

    try {
      _subscription = client
          .channel('public:notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              try {
                final record = payload.newRecord;
                final item = NotificationItem.fromMap(record);
                onInsert(item);
              } catch (e) {
                debugPrint('[NotificationService] Error parsing realtime insert: $e');
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              try {
                final record = payload.newRecord;
                final item = NotificationItem.fromMap(record);
                onUpdate(item);
              } catch (e) {
                debugPrint('[NotificationService] Error parsing realtime update: $e');
              }
            },
          )
          .subscribe();

      return _subscription;
    } catch (e) {
      debugPrint('[NotificationService] Error establishing realtime subscription: $e');
      return null;
    }
  }

  Future<void> disposeRealtime() async {
    final sub = _subscription;
    _subscription = null;
    if (sub != null) {
      try {
        final client = _supabase.client;
        if (client != null) {
          await client.removeChannel(sub);
        }
      } catch (e) {
        debugPrint('[NotificationService] Error disposing realtime channel: $e');
      }
    }
  }

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
