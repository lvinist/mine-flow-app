import 'package:mine_flow/features/tracking/domain/entities/inventory_transaction.dart';

/// Ledger DTO preserving both timestamp values and their explicit provenance.
class InventoryTransactionModel {
  final String id;
  final String siteId;
  final String itemId;
  final double delta;
  final String reason;
  final String actorId;
  final DateTime createdAt;
  final DateTime occurredAt;
  final bool hasServerCreatedAt;
  final String? idempotencyKey;

  const InventoryTransactionModel({
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

  /// Reads old and migrated schemas without calling legacy time server-authored.
  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    final source = json['created_at_source'];
    if (source != null && source != 'legacy_client' && source != 'server') {
      throw const FormatException('Unknown inventory timestamp provenance');
    }
    if (source == 'server' && json['occurred_at'] == null) {
      throw const FormatException(
        'Server ledger row is missing client event time',
      );
    }
    return InventoryTransactionModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      itemId: json['item_id'] as String,
      delta: (json['delta'] as num).toDouble(),
      reason: json['reason'] as String,
      actorId: json['actor_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      occurredAt: DateTime.parse(
        (json['occurred_at'] ?? json['created_at']) as String,
      ),
      hasServerCreatedAt: json['created_at_source'] == 'server',
      idempotencyKey: json['idempotency_key'] as String?,
    );
  }

  /// Serializes the read model without losing timestamp provenance.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'item_id': itemId,
      'delta': delta,
      'reason': reason,
      'actor_id': actorId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'created_at_source': hasServerCreatedAt ? 'server' : 'legacy_client',
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    };
  }

  /// Preserves timestamp semantics at the repository boundary.
  InventoryTransaction toDomain() {
    return InventoryTransaction(
      id: id,
      siteId: siteId,
      itemId: itemId,
      delta: delta,
      reason: reason,
      actorId: actorId,
      createdAt: createdAt,
      occurredAt: occurredAt,
      hasServerCreatedAt: hasServerCreatedAt,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Restores the DTO without re-authoring event or audit time.
  factory InventoryTransactionModel.fromDomain(InventoryTransaction domain) {
    return InventoryTransactionModel(
      id: domain.id,
      siteId: domain.siteId,
      itemId: domain.itemId,
      delta: domain.delta,
      reason: domain.reason,
      actorId: domain.actorId,
      createdAt: domain.createdAt,
      occurredAt: domain.occurredAt,
      hasServerCreatedAt: domain.hasServerCreatedAt,
      idempotencyKey: domain.idempotencyKey,
    );
  }
}
