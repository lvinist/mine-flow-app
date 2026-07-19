/// Cubit managing in-app notification state.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_state.dart';

/// Drives the notification list and banner state.
///
/// Lifecycle:
/// 1. Call [loadNotifications] on app start to hydrate from Hive.
/// 2. Call [checkAndGenerate] periodically (e.g. on app resume or timer)
///    to evaluate rules and produce new notifications.
/// 3. Use [markAsRead], [dismiss], [dismissAll] for user interactions.
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  final String siteId;

  NotificationCubit({
    required this._repository,
    required this.siteId,
  }) : super(const NotificationInitial());

  /// Loads persisted notifications from local storage.
  Future<void> loadNotifications() async {
    emit(const NotificationLoading());
    try {
      final results = await Future.wait([
        _repository.getActiveNotifications(),
        _repository.getUnreadCount(),
      ]);
      emit(
        NotificationLoaded(
          notifications: results[0] as List<AppNotification>,
          unreadCount: results[1] as int,
        ),
      );
    } catch (e) {
      emit(NotificationError('Gagal memuat notifikasi: $e'));
    }
  }

  /// Evaluates notification rules and persists new ones.
  Future<void> checkAndGenerate() async {
    try {
      await _repository.checkAndGenerateNotifications(siteId: siteId);
      // Reload to reflect any new notifications
      await loadNotifications();
    } catch (e) {
      emit(NotificationError('Gagal memeriksa notifikasi: $e'));
    }
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await loadNotifications();
  }

  /// Dismisses a single notification.
  Future<void> dismiss(String id) async {
    await _repository.dismiss(id);
    await loadNotifications();
  }

  /// Dismisses all active notifications.
  Future<void> dismissAll() async {
    await _repository.dismissAll();
    await loadNotifications();
  }
}
