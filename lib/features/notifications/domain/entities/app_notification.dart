/// Entity representing an in-app notification.
library;

import 'package:equatable/equatable.dart';

/// Category of notification — which domain it originates from.
enum NotificationType {
  equipmentCheckReminder,
  lowInventory,
  missingAttendance,
  overdueMilestone,
}

/// Urgency level for the notification.
enum NotificationSeverity { info, warning, critical }

/// A single in-app notification.
///
/// Notifications are rule-generated, stored locally in Hive, and can be
/// marked as read or dismissed by the user. Critical notifications display
/// as a persistent banner until acknowledged.
class AppNotification extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationSeverity severity;
  final bool isRead;
  final bool isDismissed;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    this.isRead = false,
    this.isDismissed = false,
    required this.createdAt,
    this.expiresAt,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationSeverity? severity,
    bool? isRead,
    bool? isDismissed,
    DateTime? createdAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    type,
    severity,
    isRead,
    isDismissed,
    createdAt,
    expiresAt,
    metadata,
  ];
}
