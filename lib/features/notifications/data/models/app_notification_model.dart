/// Hive-serialisable model for [AppNotification].
library;

import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';

/// Data-layer model mirroring [AppNotification] with JSON serialisation.
///
/// This model is stored in Hive via a manual JSON-based adapter (Type ID 15).
class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // serialised enum name
  final String severity; // serialised enum name
  final bool isRead;
  final bool isDismissed;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.isRead,
    required this.isDismissed,
    required this.createdAt,
    this.expiresAt,
    this.metadata,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      severity: json['severity'] as String,
      isRead: json['isRead'] as bool? ?? false,
      isDismissed: json['isDismissed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'severity': severity,
    'isRead': isRead,
    'isDismissed': isDismissed,
    'createdAt': createdAt.toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (metadata != null) 'metadata': metadata,
  };

  /// Converts the domain entity to this model.
  factory AppNotificationModel.fromEntity(AppNotification entity) {
    return AppNotificationModel(
      id: entity.id,
      title: entity.title,
      message: entity.message,
      type: entity.type.name,
      severity: entity.severity.name,
      isRead: entity.isRead,
      isDismissed: entity.isDismissed,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      metadata: entity.metadata,
    );
  }

  /// Converts back to the domain entity.
  AppNotification toEntity() {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: NotificationType.values.firstWhere((e) => e.name == type),
      severity: NotificationSeverity.values.firstWhere(
        (e) => e.name == severity,
      ),
      isRead: isRead,
      isDismissed: isDismissed,
      createdAt: createdAt,
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }
}
