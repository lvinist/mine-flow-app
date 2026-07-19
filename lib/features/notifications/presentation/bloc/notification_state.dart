/// States emitted by [NotificationCubit].
library;

import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';

/// Base state for notification loading.
sealed class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no data has been loaded yet.
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// Notifications are being fetched.
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// Notifications loaded successfully.
class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

/// An error occurred while loading notifications.
class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
