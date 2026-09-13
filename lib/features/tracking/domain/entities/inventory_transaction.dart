import 'package:equatable/equatable.dart';

class InventoryTransaction extends Equatable {
  final String id;
  final String siteId;
  final String itemId;
  final double delta;
  final String reason;
  final String actorId;
  final DateTime createdAt;
  final String? idempotencyKey;

  const InventoryTransaction({
    required this.id,
    required this.siteId,
    required this.itemId,
    required this.delta,
    required this.reason,
    required this.actorId,
    required this.createdAt,
    this.idempotencyKey,
  });

  @override
  List<Object?> get props => [
    id,
    siteId,
    itemId,
    delta,
    reason,
    actorId,
    createdAt,
    idempotencyKey,
  ];
}
