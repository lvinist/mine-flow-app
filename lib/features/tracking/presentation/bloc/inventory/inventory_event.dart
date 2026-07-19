import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';

/// Abstract base class for all inventory tracking BLoC events.
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the list of inventory items with optional filters.
class LoadInventoryItemsEvent extends InventoryEvent {
  final String? siteId;
  final String? zoneId;
  final String? category;

  const LoadInventoryItemsEvent({this.siteId, this.zoneId, this.category});

  @override
  List<Object?> get props => [siteId, zoneId, category];
}

/// Event to initialize or load an inventory item form for creating/editing.
class InitializeInventoryItemFormEvent extends InventoryEvent {
  final String siteId;
  final String? zoneId;
  final InventoryItem? existingItem;

  const InitializeInventoryItemFormEvent({
    required this.siteId,
    this.zoneId,
    this.existingItem,
  });

  @override
  List<Object?> get props => [siteId, zoneId, existingItem];
}

/// Event fired when item name changes in the form.
class ItemNameChangedEvent extends InventoryEvent {
  final String itemName;

  const ItemNameChangedEvent(this.itemName);

  @override
  List<Object?> get props => [itemName];
}

/// Event fired when category selection changes.
class InventoryCategoryChangedEvent extends InventoryEvent {
  final String? category;

  const InventoryCategoryChangedEvent(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event fired when unit changes.
class UnitChangedEvent extends InventoryEvent {
  final String unit;

  const UnitChangedEvent(this.unit);

  @override
  List<Object?> get props => [unit];
}

/// Event fired when quantity on hand changes.
class QuantityOnHandChangedEvent extends InventoryEvent {
  final double quantityOnHand;

  const QuantityOnHandChangedEvent(this.quantityOnHand);

  @override
  List<Object?> get props => [quantityOnHand];
}

/// Event fired when minimum threshold value changes.
class MinThresholdChangedEvent extends InventoryEvent {
  final double minThreshold;

  const MinThresholdChangedEvent(this.minThreshold);

  @override
  List<Object?> get props => [minThreshold];
}

/// Event fired when SKU changes in the form.
class SkuChangedEvent extends InventoryEvent {
  final String? sku;

  const SkuChangedEvent(this.sku);

  @override
  List<Object?> get props => [sku];
}

/// Event fired when inventory notes text changes.
class InventoryNotesChangedEvent extends InventoryEvent {
  final String notes;

  const InventoryNotesChangedEvent(this.notes);

  @override
  List<Object?> get props => [notes];
}

/// Event to save an inventory item (create or update).
class SaveInventoryItemEvent extends InventoryEvent {
  const SaveInventoryItemEvent();
}

/// Event to delete an inventory item.
class DeleteInventoryItemEvent extends InventoryEvent {
  final String itemId;

  const DeleteInventoryItemEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

/// Event to adjust stock quantity by a delta (+/-).
class AdjustStockEvent extends InventoryEvent {
  final String itemId;
  final double deltaQuantity;
  final String? reason;

  const AdjustStockEvent({
    required this.itemId,
    required this.deltaQuantity,
    this.reason,
  });

  @override
  List<Object?> get props => [itemId, deltaQuantity, reason];
}

/// Event to filter the inventory list by a specific category.
class FilterByCategoryEvent extends InventoryEvent {
  final String? category;

  const FilterByCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}
