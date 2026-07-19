import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';

/// Abstract base class for all inventory BLoC states.
abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

/// Loading state while fetching or saving inventory data.
class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

/// State representing loaded list of inventory items with category filter and low-stock info.
class InventoryItemsLoaded extends InventoryState {
  final List<InventoryItem> items;
  final String? siteId;
  final String? zoneId;
  final String? selectedCategory;

  /// Total number of items that are low stock (quantity_on_hand <= min_threshold).
  final int lowStockCount;

  const InventoryItemsLoaded({
    required this.items,
    this.siteId,
    this.zoneId,
    this.selectedCategory,
    this.lowStockCount = 0,
  });

  /// The currently displayed items (already filtered by category if selected).
  List<InventoryItem> get displayedItems => items;

  InventoryItemsLoaded copyWith({
    List<InventoryItem>? items,
    String? siteId,
    String? zoneId,
    String? selectedCategory,
    int? lowStockCount,
  }) {
    return InventoryItemsLoaded(
      items: items ?? this.items,
      siteId: siteId ?? this.siteId,
      zoneId: zoneId ?? this.zoneId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      lowStockCount: lowStockCount ?? this.lowStockCount,
    );
  }

  @override
  List<Object?> get props => [
    items,
    siteId,
    zoneId,
    selectedCategory,
    lowStockCount,
  ];
}

/// Form state managing editing of an inventory item.
class InventoryFormState extends InventoryState {
  final InventoryItem item;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;
  final String? successMessage;
  final bool hasUnsavedChanges;

  const InventoryFormState({
    required this.item,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
    this.successMessage,
    this.hasUnsavedChanges = false,
  });

  InventoryFormState copyWith({
    InventoryItem? item,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
    String? successMessage,
    bool? hasUnsavedChanges,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return InventoryFormState(
      item: item ?? this.item,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }

  @override
  List<Object?> get props => [
    item,
    isSaving,
    isSaved,
    errorMessage,
    successMessage,
    hasUnsavedChanges,
  ];
}

/// Error state for failures.
class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}
