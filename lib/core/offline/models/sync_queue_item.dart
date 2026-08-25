import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Actions that can be performed on an offline entity.
enum SyncAction { create, update, delete }

/// Current status of an offline queue item.
enum SyncStatus { pending, syncing, failed, completed }

/// Represents a single pending write transaction recorded while offline.
/// Will be processed by [SyncQueueManager] when network connectivity is restored.
class SyncQueueItem extends Equatable {
  final String id;
  final String entityType;
  final SyncAction action;
  final Map<String, dynamic> payloadJson;
  final DateTime timestamp;
  final SyncStatus syncStatus;
  final int retryCount;
  final String? errorMessage;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.action,
    required this.payloadJson,
    required this.timestamp,
    this.syncStatus = SyncStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
  });

  /// Deserializes a [SyncQueueItem] from a JSON map.
  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      action: SyncAction.values.firstWhere(
        (e) => e.name == (json['action'] as String),
        orElse: () => SyncAction.create,
      ),
      payloadJson: json['payload_json'] is String
          ? jsonDecode(json['payload_json'] as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(json['payload_json'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == (json['sync_status'] as String),
        orElse: () => SyncStatus.pending,
      ),
      retryCount: json['retry_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }

  /// Serializes this item into a JSON map suitable for persistence or logging.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'action': action.name,
      'payload_json': payloadJson,
      'timestamp': timestamp.toIso8601String(),
      'sync_status': syncStatus.name,
      'retry_count': retryCount,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }

  /// Creates a copy of this item with optional updated fields.
  SyncQueueItem copyWith({
    String? id,
    String? entityType,
    SyncAction? action,
    Map<String, dynamic>? payloadJson,
    DateTime? timestamp,
    SyncStatus? syncStatus,
    int? retryCount,
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      action: action ?? this.action,
      payloadJson: payloadJson ?? this.payloadJson,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    entityType,
    action,
    payloadJson,
    timestamp,
    syncStatus,
    retryCount,
    errorMessage,
  ];
}
