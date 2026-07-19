/// Implementation of [NotificationRepository].
library;

import 'package:mine_flow/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:mine_flow/features/notifications/data/models/app_notification_model.dart';
import 'package:mine_flow/features/notifications/data/services/notification_rule_engine.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/notifications/domain/repositories/notification_repository.dart';

/// Concrete repository that delegates rule generation to
/// [NotificationRuleEngine] and persistence to [NotificationLocalDataSource].
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRuleEngine _ruleEngine;
  final NotificationLocalDataSource _localDataSource;

  NotificationRepositoryImpl({
    required this._ruleEngine,
    required this._localDataSource,
  });

  @override
  Future<List<AppNotification>> getActiveNotifications() async {
    final models = await _localDataSource.getActive();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    await _localDataSource.markAsRead(id);
  }

  @override
  Future<void> dismiss(String id) async {
    await _localDataSource.dismiss(id);
  }

  @override
  Future<void> dismissAll() async {
    await _localDataSource.dismissAll();
  }

  @override
  Future<int> getUnreadCount() async {
    return await _localDataSource.getUnreadCount();
  }

  @override
  Future<List<AppNotification>> checkAndGenerateNotifications({
    required String siteId,
  }) async {
    // 1. Evaluate rules
    final newNotifications = await _ruleEngine.evaluateRules(siteId: siteId);

    if (newNotifications.isEmpty) return [];

    // 2. Deduplicate: skip if a notification of the same type was already
    //    generated today
    final toPersist = <AppNotification>[];
    for (final notification in newNotifications) {
      final exists = await _localDataSource.existsForToday(
        type: notification.type.name,
        date: notification.createdAt,
      );
      if (!exists) {
        toPersist.add(notification);
      }
    }

    if (toPersist.isEmpty) return [];

    // 3. Persist new notifications
    final models = toPersist
        .map((n) => AppNotificationModel.fromEntity(n))
        .toList();
    await _localDataSource.saveMany(models);

    return toPersist;
  }
}
