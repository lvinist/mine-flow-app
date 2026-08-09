import 'package:mine_flow/core/data/models/inventory_item_model.dart'
    as core_models;
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';

/// Data Model / DTO for [InventoryItem] extending entity and providing JSON serialization.
class InventoryItemModel extends InventoryItem {
  const InventoryItemModel({
    required super.id,
    required super.siteId,
    super.zoneId,
    required super.itemName,
    super.sku,
    super.category,
    super.quantityOnHand = 0.0,
    super.unit = 'pcs',
    super.minThreshold = 0.0,
    super.notes,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB or payload.
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      zoneId: json['zone_id'] as String?,
      itemName: (json['item_name'] ?? json['name']) as String? ?? '',
      sku: json['sku'] as String?,
      category: json['category'] as String?,
      quantityOnHand: (json['quantity_on_hand'] ?? json['quantity']) != null
          ? ((json['quantity_on_hand'] ?? json['quantity']) as num).toDouble()
          : 0.0,
      unit: json['unit'] as String? ?? 'pcs',
      minThreshold: (json['min_threshold'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
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

  /// Serializes model into JSON map suitable for Supabase queries.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      if (zoneId != null) 'zone_id': zoneId,
      'item_name': itemName,
      'name': itemName,
      if (sku != null) 'sku': sku,
      if (category != null) 'category': category,
      'quantity_on_hand': quantityOnHand,
      'quantity': quantityOnHand,
      'unit': unit,
      if (minThreshold != null) 'min_threshold': minThreshold,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  InventoryItem toDomain() {
    return InventoryItem(
      id: id,
      siteId: siteId,
      zoneId: zoneId,
      itemName: itemName,
      sku: sku,
      category: category,
      quantityOnHand: quantityOnHand,
      unit: unit,
      minThreshold: minThreshold,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Factory constructor from domain entity.
  factory InventoryItemModel.fromDomain(InventoryItem entity) {
    return InventoryItemModel(
      id: entity.id,
      siteId: entity.siteId,
      zoneId: entity.zoneId,
      itemName: entity.itemName,
      sku: entity.sku,
      category: entity.category,
      quantityOnHand: entity.quantityOnHand,
      unit: entity.unit,
      minThreshold: entity.minThreshold,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  /// Converts to core model DTO for Hive storage compatibility.
  core_models.InventoryItemModel toCoreModel() {
    return core_models.InventoryItemModel(
      id: id,
      siteId: siteId,
      name: itemName,
      sku: sku,
      category: category,
      quantity: quantityOnHand,
      unit: unit,
      minThreshold: minThreshold,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Creates InventoryItemModel from core InventoryItemModel.
  factory InventoryItemModel.fromCoreModel(
    core_models.InventoryItemModel core,
  ) {
    return InventoryItemModel(
      id: core.id,
      siteId: core.siteId,
      itemName: core.name,
      sku: core.sku,
      category: core.category,
      quantityOnHand: core.quantity,
      unit: core.unit,
      minThreshold: core.minThreshold,
      createdAt: core.createdAt,
      updatedAt: core.updatedAt,
      deletedAt: core.deletedAt,
    );
  }
}
