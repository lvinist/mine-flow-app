import 'package:equatable/equatable.dart';

/// Domain entity representing a site inventory item and its stock level.
class InventoryItem extends Equatable {
  final String id;
  final String siteId;
  final String? zoneId;
  final String itemName;
  final String? sku;
  final String? category;
  final double quantityOnHand;
  final String unit;
  final double? minThreshold;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const InventoryItem({
    required this.id,
    required this.siteId,
    this.zoneId,
    required this.itemName,
    this.sku,
    this.category,
    this.quantityOnHand = 0.0,
    this.unit = 'pcs',
    this.minThreshold = 0.0,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Returns true if stock is at or below the minimum alert threshold.
  bool get isLowStock =>
      minThreshold != null && quantityOnHand <= minThreshold!;

  InventoryItem copyWith({
    String? id,
    String? siteId,
    String? zoneId,
    String? itemName,
    String? sku,
    String? category,
    double? quantityOnHand,
    String? unit,
    double? minThreshold,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      zoneId: zoneId ?? this.zoneId,
      itemName: itemName ?? this.itemName,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      unit: unit ?? this.unit,
      minThreshold: minThreshold ?? this.minThreshold,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    siteId,
    zoneId,
    itemName,
    sku,
    category,
    quantityOnHand,
    unit,
    minThreshold,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
