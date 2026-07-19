/// Local (Hive-backed) storage for in-app notifications.
library;

import 'package:hive/hive.dart';
import 'package:mine_flow/features/notifications/data/models/app_notification_model.dart';

/// Persistence layer for [AppNotificationModel]s.
///
/// Stores all notifications in a single Hive box (`notifications`). Queries
/// are done in-memory after loading the full list — the dataset is expected
/// to stay small (< 500 items for a single site).
class NotificationLocalDataSource {
  static const _boxName = 'notifications';

  Box<Map<String, dynamic>>? _box;

  /// Ensures the Hive box is open.
  Future<Box<Map<String, dynamic>>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Map<String, dynamic>>(_boxName);
    }
    return _box!;
  }

  /// Returns all stored notifications (newest first).
  Future<List<AppNotificationModel>> getAll() async {
    final box = await _ensureBox();
    final models = <AppNotificationModel>[];
    for (final entry in box.values) {
      models.add(
        AppNotificationModel.fromJson(Map<String, dynamic>.from(entry)),
      );
    }
    models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return models;
  }

  /// Returns all non-dismissed notifications (newest first).
  Future<List<AppNotificationModel>> getActive() async {
    final all = await getAll();
    return all.where((n) => !n.isDismissed).toList();
  }

  /// Saves a single notification to the box.
  Future<void> save(AppNotificationModel model) async {
    final box = await _ensureBox();
    await box.put(model.id, model.toJson());
  }

  /// Saves a list of notifications (batch insert/update).
  Future<void> saveMany(List<AppNotificationModel> models) async {
    final box = await _ensureBox();
    await box.putAll({for (final m in models) m.id: m.toJson()});
  }

  /// Updates the `isRead` flag for a single notification.
  Future<void> markAsRead(String id) async {
    final box = await _ensureBox();
    final raw = box.get(id);
    if (raw != null) {
      final model = AppNotificationModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
      await box.put(
        id,
        AppNotificationModel(
          id: model.id,
          title: model.title,
          message: model.message,
          type: model.type,
          severity: model.severity,
          isRead: true,
          isDismissed: model.isDismissed,
          createdAt: model.createdAt,
          expiresAt: model.expiresAt,
          metadata: model.metadata,
        ).toJson(),
      );
    }
  }

  /// Dismisses a single notification.
  Future<void> dismiss(String id) async {
    final box = await _ensureBox();
    final raw = box.get(id);
    if (raw != null) {
      final model = AppNotificationModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
      await box.put(
        id,
        AppNotificationModel(
          id: model.id,
          title: model.title,
          message: model.message,
          type: model.type,
          severity: model.severity,
          isRead: model.isRead,
          isDismissed: true,
          createdAt: model.createdAt,
          expiresAt: model.expiresAt,
          metadata: model.metadata,
        ).toJson(),
      );
    }
  }

  /// Dismisses all active notifications.
  Future<void> dismissAll() async {
    final active = await getActive();
    for (final n in active) {
      await dismiss(n.id);
    }
  }

  /// Returns the count of unread, non-dismissed notifications.
  Future<int> getUnreadCount() async {
    final all = await getActive();
    return all.where((n) => !n.isRead).length;
  }

  /// Checks whether a notification with the given [type] was already
  /// generated on the same day as [date].
  Future<bool> existsForToday({
    required String type,
    required DateTime date,
  }) async {
    final all = await getAll();
    final dayStart = DateTime(date.year, date.month, date.day);
    return all.any((n) {
      final nDayStart = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      return n.type == type && nDayStart == dayStart;
    });
  }
}
