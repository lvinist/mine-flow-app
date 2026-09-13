import 'package:mine_flow/features/tracking/domain/entities/inventory_transaction.dart';

class InventoryTransactionModel {
  final String id;
  final String siteId;
  final String itemId;
  final double delta;
  final String reason;
  final String actorId;
  final DateTime createdAt;
  final String? idempotencyKey;

  const InventoryTransactionModel({
    required this.id,
    required this.siteId,
    required this.itemId,
    required this.delta,
    required this.reason,
    required this.actorId,
    required this.createdAt,
    this.idempotencyKey,
  });

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      itemId: json['item_id'] as String,
      delta: (json['delta'] as num).toDouble(),
      reason: json['reason'] as String,
      actorId: json['actor_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      idempotencyKey: json['idempotency_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'item_id': itemId,
      'delta': delta,
      'reason': reason,
      'actor_id': actorId,
      'created_at': createdAt.toIso8601String(),
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    };
  }

  InventoryTransaction toDomain() {
    return InventoryTransaction(
      id: id,
      siteId: siteId,
      itemId: itemId,
      delta: delta,
      reason: reason,
      actorId: actorId,
      createdAt: createdAt,
      idempotencyKey: idempotencyKey,
    );
  }

  factory InventoryTransactionModel.fromDomain(InventoryTransaction domain) {
    return InventoryTransactionModel(
      id: domain.id,
      siteId: domain.siteId,
      itemId: domain.itemId,
      delta: domain.delta,
      reason: domain.reason,
      actorId: domain.actorId,
      createdAt: domain.createdAt,
      idempotencyKey: domain.idempotencyKey,
    );
  }
}
