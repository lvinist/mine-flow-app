import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';

/// BLoC handling state management for Inventory item tracking:
/// - List/dashboard view with category filter tabs and low-stock warnings
/// - Form creation and editing of inventory items
/// - Stock adjustment (+/-) with reason tracking
/// - Save and delete operations via repository
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final TrackingRepository _repository;
  final Uuid _uuid;

  InventoryBloc({required this._repository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const InventoryInitial()) {
    on<LoadInventoryItemsEvent>(_onLoadItems);
    on<InitializeInventoryItemFormEvent>(_onInitializeForm);
    on<ItemNameChangedEvent>(_onItemNameChanged);
    on<InventoryCategoryChangedEvent>(_onCategoryChanged);
    on<UnitChangedEvent>(_onUnitChanged);
    on<QuantityOnHandChangedEvent>(_onQuantityChanged);
    on<MinThresholdChangedEvent>(_onMinThresholdChanged);
    on<SkuChangedEvent>(_onSkuChanged);
    on<InventoryNotesChangedEvent>(_onNotesChanged);
    on<SaveInventoryItemEvent>(_onSaveItem);
    on<DeleteInventoryItemEvent>(_onDeleteItem);
    on<AdjustStockEvent>(_onAdjustStock);
    on<FilterByCategoryEvent>(_onFilterByCategory);
    on<LoadItemNameSuggestionsEvent>(_onLoadSuggestions);
  }

  /// Predefined inventory categories used for filter tabs and dropdown.
  static const List<String> categories = [
    'Fuel / Lubricants',
    'Explosives / Blasting',
    'Spare Parts',
    'Consumables',
    'Safety Equipment',
    'Tools',
    'Lainnya',
  ];

  Future<void> _onLoadItems(
    LoadInventoryItemsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final items = await _repository.getInventoryItems(
        siteId: event.siteId,
        zoneId: event.zoneId,
        category: event.category,
      );

      _updateLoadedState(
        emit,
        items,
        siteId: event.siteId,
        zoneId: event.zoneId,
        selectedCategory: event.category,
      );
    } catch (e) {
      emit(InventoryError('Gagal memuat data inventori: ${e.toString()}'));
    }
  }

  Future<void> _onInitializeForm(
    InitializeInventoryItemFormEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final item =
          event.existingItem ??
          InventoryItem(
            id: _uuid.v4(),
            siteId: event.siteId,
            zoneId: event.zoneId,
            itemName: '',
            quantityOnHand: 0.0,
            unit: 'pcs',
            minThreshold: 0.0,
            createdAt: DateTime.now(),
          );

      emit(InventoryFormState(item: item));
    } catch (e) {
      emit(
        InventoryError('Gagal inisialisasi form inventori: ${e.toString()}'),
      );
    }
  }

  void _onItemNameChanged(
    ItemNameChangedEvent event,
    Emitter<InventoryState> emit,
  ) {
    _updateFormField(
      emit,
      (item) =>
          item.copyWith(itemName: event.itemName, updatedAt: DateTime.now()),
    );
  }

  void _onCategoryChanged(
    InventoryCategoryChangedEvent event,
    Emitter<InventoryState> emit,
  ) {
    _updateFormField(
      emit,
      (item) =>
          item.copyWith(category: event.category, updatedAt: DateTime.now()),
    );
  }

  void _onUnitChanged(UnitChangedEvent event, Emitter<InventoryState> emit) {
    _updateFormField(
      emit,
      (item) => item.copyWith(unit: event.unit, updatedAt: DateTime.now()),
    );
  }

  void _onQuantityChanged(
    QuantityOnHandChangedEvent event,
    Emitter<InventoryState> emit,
  ) {
    _updateFormField(
      emit,
      (item) => item.copyWith(
        quantityOnHand: event.quantityOnHand,
        clearQuantityOnHand: event.quantityOnHand == null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _onMinThresholdChanged(
    MinThresholdChangedEvent event,
    Emitter<InventoryState> emit,
  ) {
    _updateFormField(
      emit,
      (item) => item.copyWith(
        minThreshold: event.minThreshold,
        clearMinThreshold: event.minThreshold == null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _onSkuChanged(SkuChangedEvent event, Emitter<InventoryState> emit) {
    _updateFormField(
      emit,
      (item) => item.copyWith(sku: event.sku, updatedAt: DateTime.now()),
    );
  }

  void _onNotesChanged(
    InventoryNotesChangedEvent event,
    Emitter<InventoryState> emit,
  ) {
    _updateFormField(
      emit,
      (item) => item.copyWith(
        notes: event.notes.isNotEmpty ? event.notes : null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _updateFormField(
    Emitter<InventoryState> emit,
    InventoryItem Function(InventoryItem) transform,
  ) {
    final currentState = state;
    if (currentState is InventoryFormState) {
      final updatedItem = transform(currentState.item);
      emit(currentState.copyWith(item: updatedItem, hasUnsavedChanges: true));
    }
  }

  Future<void> _onSaveItem(
    SaveInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! InventoryFormState) return;

    emit(currentState.copyWith(isSaving: true, clearError: true));

    try {
      await _repository.saveInventoryItem(currentState.item);
      emit(
        currentState.copyWith(
          isSaving: false,
          isSaved: true,
          hasUnsavedChanges: false,
          successMessage: 'Item inventori berhasil disimpan!',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          errorMessage: 'Gagal menyimpan item inventori: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteItem(
    DeleteInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.deleteInventoryItem(event.itemId);

      final currentState = state;
      if (currentState is InventoryItemsLoaded) {
        // Reload with same filters
        add(
          LoadInventoryItemsEvent(
            siteId: currentState.siteId,
            zoneId: currentState.zoneId,
            category: currentState.selectedCategory,
          ),
        );
      } else {
        add(const LoadInventoryItemsEvent());
      }
    } catch (e) {
      emit(InventoryError('Gagal menghapus item inventori: ${e.toString()}'));
    }
  }

  Future<void> _onAdjustStock(
    AdjustStockEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.updateInventoryQuantity(
        event.itemId,
        event.deltaQuantity,
      );

      // Reload current list
      final currentState = state;
      if (currentState is InventoryItemsLoaded) {
        add(
          LoadInventoryItemsEvent(
            siteId: currentState.siteId,
            zoneId: currentState.zoneId,
            category: currentState.selectedCategory,
          ),
        );
      } else {
        add(const LoadInventoryItemsEvent());
      }
    } catch (e) {
      emit(
        InventoryError('Gagal menyesuaikan stok inventori: ${e.toString()}'),
      );
    }
  }

  void _onFilterByCategory(
    FilterByCategoryEvent event,
    Emitter<InventoryState> emit,
  ) {
    final currentState = state;
    if (currentState is InventoryItemsLoaded) {
      // Re-load with category filter
      add(
        LoadInventoryItemsEvent(
          siteId: currentState.siteId,
          zoneId: currentState.zoneId,
          category: event.category,
        ),
      );
    } else {
      add(LoadInventoryItemsEvent(category: event.category));
    }
  }

  Future<void> _onLoadSuggestions(
    LoadItemNameSuggestionsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! InventoryFormState) return;
    if (event.prefix.trim().isEmpty) {
      emit(currentState.copyWith(clearSuggestions: true));
      return;
    }
    try {
      final names = await _repository.getDistinctItemNames(event.prefix);
      if (state is InventoryFormState) {
        emit((state as InventoryFormState).copyWith(suggestions: names));
      }
    } catch (_) {
      // Silently ignore suggestion fetch failures; they're non-critical.
    }
  }

  /// Helper to emit an [InventoryItemsLoaded] state with computed low-stock count.
  void _updateLoadedState(
    Emitter<InventoryState> emit,
    List<InventoryItem> items, {
    String? siteId,
    String? zoneId,
    String? selectedCategory,
  }) {
    final lowStockCount = items.where((item) => item.isLowStock).length;

    emit(
      InventoryItemsLoaded(
        items: items,
        siteId: siteId,
        zoneId: zoneId,
        selectedCategory: selectedCategory,
        lowStockCount: lowStockCount,
      ),
    );
  }
}
