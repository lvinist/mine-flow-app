import 'package:mine_flow/core/domain/entities/inventory_item_entity.dart';

/// Data Transfer Object (DTO) for [InventoryItemEntity] handling JSON serialization
/// to and from Supabase `public.inventory_items` table.
class InventoryItemModel extends InventoryItemEntity {
  const InventoryItemModel({
    required super.id,
    required super.siteId,
    required super.name,
    super.sku,
    super.category,
    super.quantity = 0.0,
    super.unit = 'pcs',
    super.minThreshold = 0.0,
    super.notes,
    super.zoneId,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB.
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      name: json['name'] as String,
      sku: json['sku'] as String?,
      category: json['category'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'pcs',
      minThreshold: (json['min_threshold'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      zoneId: json['zone_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Converts model into JSON map suitable for Supabase queries.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'name': name,
      if (sku != null) 'sku': sku,
      if (category != null) 'category': category,
      'quantity': quantity,
      'unit': unit,
      if (minThreshold != null) 'min_threshold': minThreshold,
      if (notes != null) 'notes': notes,
      if (zoneId != null) 'zone_id': zoneId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  InventoryItemEntity toDomain() {
    return InventoryItemEntity(
      id: id,
      siteId: siteId,
      name: name,
      sku: sku,
      category: category,
      quantity: quantity,
      unit: unit,
      minThreshold: minThreshold,
      notes: notes,
      zoneId: zoneId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  InventoryItemEntity toEntity() => toDomain();

  /// Factory constructor from a domain entity.
  factory InventoryItemModel.fromDomain(InventoryItemEntity entity) {
    return InventoryItemModel(
      id: entity.id,
      siteId: entity.siteId,
      name: entity.name,
      sku: entity.sku,
      category: entity.category,
      quantity: entity.quantity,
      unit: entity.unit,
      minThreshold: entity.minThreshold,
      notes: entity.notes,
      zoneId: entity.zoneId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory InventoryItemModel.fromEntity(InventoryItemEntity entity) =>
      InventoryItemModel.fromDomain(entity);
}
