import 'package:equatable/equatable.dart';

/// Domain entity representing materials, equipment, or consumables on site.
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
class InventoryItemEntity extends Equatable {
  final String id;
  final String siteId;
  final String name;
  final String? sku;
  final String? category;
  final double quantity;
  final String unit;
  final double? minThreshold;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const InventoryItemEntity({
    required this.id,
    required this.siteId,
    required this.name,
    this.sku,
    this.category,
    this.quantity = 0.0,
    this.unit = 'pcs',
    this.minThreshold = 0.0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
    id,
    siteId,
    name,
    sku,
    category,
    quantity,
    unit,
    minThreshold,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
