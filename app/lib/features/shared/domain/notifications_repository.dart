import 'notification_item.dart';

export 'notification_item.dart';

abstract interface class NotificationsRepository {
  Future<List<NotificationItem>> getNotifications({int offset = 0, int limit = 50});
  Future<void> markAsRead(String id);
  Future<bool> hasUnreadNotifications();
}

