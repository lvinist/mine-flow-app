/// Repository abstraction for in-app notifications.
library;

import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';

/// Contract for the notification data layer.
///
/// Notifications are rule-generated and stored locally in Hive, so the
/// repository only exposes read/mutate operations plus a check-and-generate
/// method that produces new notifications from rule evaluation.
abstract class NotificationRepository {
  /// Returns all active (non-dismissed) notifications, newest first.
  Future<List<AppNotification>> getActiveNotifications();

  /// Marks a single notification as read.
  Future<void> markAsRead(String id);

  /// Dismisses a notification (hides it permanently).
  Future<void> dismiss(String id);

  /// Dismisses all active notifications.
  Future<void> dismissAll();

  /// Returns the count of unread, non-dismissed notifications.
  Future<int> getUnreadCount();

  /// Evaluates rule engine and persists any new notifications.
  ///
  /// Deduplicates based on [NotificationType] per day — so a single rule
  /// won't generate dozens of identical warnings in one session.
  Future<List<AppNotification>> checkAndGenerateNotifications({
    required String siteId,
  });
}
