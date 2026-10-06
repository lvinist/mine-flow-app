import 'package:equatable/equatable.dart';

/// Immutable stock movement with separate event and audit-time provenance.
class InventoryTransaction extends Equatable {
  final String id;
  final String siteId;
  final String itemId;
  final double delta;
  final String reason;
  final String actorId;

  /// Server insert time for new rows; preserved client time for legacy rows.
  final DateTime createdAt;

  /// Client event time, which may predate synchronization by days.
  final DateTime occurredAt;

  /// False for historical timestamps and responses from an unmigrated backend.
  final bool hasServerCreatedAt;
  final String? idempotencyKey;

  const InventoryTransaction({
    required this.id,
    required this.siteId,
    required this.itemId,
    required this.delta,
    required this.reason,
    required this.actorId,
    required this.createdAt,
    DateTime? occurredAt,
    this.hasServerCreatedAt = false,
    this.idempotencyKey,
  }) : occurredAt = occurredAt ?? createdAt;

  @override
  List<Object?> get props => [
    id,
    siteId,
    itemId,
    delta,
    reason,
    actorId,
    createdAt,
    occurredAt,
    hasServerCreatedAt,
    idempotencyKey,
  ];
}
