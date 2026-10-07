import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/models/notification_item.dart';
import 'package:dental_clinic_app/models/billing.dart';
import 'package:dental_clinic_app/services/notification_service.dart';

void main() {
  group('Task 1: Real Database-Backed Notifications & Realtime Tests', () {
    test('1. NotificationService returns null/false when Supabase is not connected (no fake data)', () async {
      final service = NotificationService();

      final list = await service.fetchNotifications();
      expect(list, isNull, reason: 'Must return null rather than mock notifications when uninitialized');

      final notif = NotificationItem(
        id: 'NOTIF-TEST-1',
        title: 'Test',
        message: 'Test message',
        timestamp: DateTime.now(),
        type: NotificationType.appointment,
      );

      final insertRes = await service.insertNotification(notif);
      expect(insertRes, isFalse, reason: 'Must return false if database insert is not executed');

      final markReadRes = await service.markAsRead('NOTIF-TEST-1');
      expect(markReadRes, isFalse, reason: 'Must return false if database update is not executed');

      final markAllRes = await service.markAllAsRead();
      expect(markAllRes, isFalse, reason: 'Must return false if database bulk update is not executed');
    });

    test('2. ClinicState unreadNotificationCount dynamically counts isRead == false', () {
      final state = ClinicState();
      final initialUnread = state.unreadNotificationCount;
      final calculatedUnread = state.notifications.where((n) => !n.isRead).length;

      expect(initialUnread, equals(calculatedUnread));
    });

    test('3. ClinicState markNotificationAsRead updates notification read status', () async {
      final state = ClinicState();
      if (state.notifications.isNotEmpty) {
        final targetId = state.notifications.first.id;
        await state.markNotificationAsRead(targetId);

        final updated = state.notifications.firstWhere((n) => n.id == targetId);
        expect(updated.isRead, isTrue);
      }
    });

    test('4. ClinicState markAllNotificationsAsRead marks all notifications as read', () async {
      final state = ClinicState();
      await state.markAllNotificationsAsRead();

      expect(state.unreadNotificationCount, equals(0));
      for (final notif in state.notifications) {
        expect(notif.isRead, isTrue);
      }
    });

    test('5. NotificationItem serialization & schema conformity with Postgres check constraints', () {
      for (final type in NotificationType.values) {
        final item = NotificationItem(
          id: 'NOTIF-${type.name}',
          title: 'Title ${type.name}',
          message: 'Message ${type.name}',
          timestamp: DateTime(2026, 10, 4, 12, 0),
          isRead: false,
          type: type,
        );

        final map = item.toMap();
        expect(map['id'], equals('NOTIF-${type.name}'));
        expect(map['type'], equals(type.name));
        expect(
          ['appointment', 'checkIn', 'doctorAvailable', 'paymentPending', 'reminder'],
          contains(map['type']),
          reason: 'Must strictly conform to database check constraint',
        );

        final restored = NotificationItem.fromMap(map);
        expect(restored.id, equals(item.id));
        expect(restored.type, equals(type));
        expect(restored.title, equals(item.title));
      }
    });

    test('6. Production safety: operations fail honestly without fake notifications when DB offline', () async {
      final state = ClinicState();
      final initialNotifCount = state.notifications.length;

      // cancelAppointment fails honestly on uninitialized Supabase
      final cancelRes = await state.cancelAppointment('APT-001');
      expect(cancelRes, isFalse);
      expect(state.notifications.length, equals(initialNotifCount),
          reason: 'Must not add unpersisted notification if DB update fails');

      // addInvoice fails honestly on uninitialized Supabase
      final testInvoice = Invoice(
        id: 'INV-TEST-NOTIF',
        invoiceNumber: 'INV-2026-999',
        patientId: 'PT-01',
        patientName: 'Jane Doe',
        patientPhone: '+919876543210',
        doctorId: 'DOC-01',
        doctorName: 'Dr. Sarah Mitchell',
        date: DateTime.now(),
        items: const [],
        subtotal: 1500.0,
        totalAmount: 1500.0,
        paidAmount: 0.0,
        balanceAmount: 1500.0,
        status: PaymentStatus.pending,
        paymentMethod: 'Pending',
      );
      final invoiceRes = await state.addInvoice(testInvoice);
      expect(invoiceRes, isFalse);
      expect(state.notifications.length, equals(initialNotifCount),
          reason: 'Must not add unpersisted notification if DB invoice fails');

      // recordPayment fails honestly on uninitialized Supabase
      final payRes = await state.recordPayment('INV-001', 500.0, 'Cash');
      expect(payRes, isFalse);
      expect(state.notifications.length, equals(initialNotifCount),
          reason: 'Must not add unpersisted notification if DB payment fails');
    });

    test('7. Realtime channel subscription handles uninitialized environment cleanly', () {
      final service = NotificationService();
      final channel = service.initRealtimeSubscription(
        onInsert: (_) {},
        onUpdate: (_) {},
      );
      expect(channel, isNull, reason: 'Realtime channel gracefully returns null when Supabase is not connected');

      // disposeRealtime completes without throwing
      expect(() => service.disposeRealtime(), returnsNormally);
    });
  });
}
