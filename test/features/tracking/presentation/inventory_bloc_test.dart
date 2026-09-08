import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class FakeInventoryItem extends Fake implements InventoryItem {}

void main() {
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  late MockTrackingRepository mockRepository;
  late InventoryBloc inventoryBloc;

  setUpAll(() {
    registerFallbackValue(FakeInventoryItem());
  });

  setUp(() {
    mockRepository = MockTrackingRepository();
    inventoryBloc = InventoryBloc(repository: mockRepository);
  });

  tearDown(() {
    inventoryBloc.close();
  });

  group('LoadInventoryItemsEvent', () {
    final tItems = [
      const InventoryItem(
        id: 'inv-001',
        siteId: defaultSiteId,
        zoneId: 'warehouse-01',
        itemName: 'Diesel Fuel',
        category: 'Fuel & Lubricants',
        quantityOnHand: 150.0,
        unit: 'Liters',
        minThreshold: 200.0,
      ),
      const InventoryItem(
        id: 'inv-002',
        siteId: defaultSiteId,
        zoneId: 'warehouse-01',
        itemName: 'Safety Helmet',
        category: 'Safety Equipment',
        quantityOnHand: 50.0,
        unit: 'pcs',
        minThreshold: 10.0,
      ),
    ];

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading, InventoryItemsLoaded] with low stock count',
      build: () {
        when(
          () => mockRepository.getInventoryItems(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => tItems);

        return inventoryBloc;
      },
      act: (bloc) => bloc.add(const LoadInventoryItemsEvent()),
      expect: () => [
        const InventoryLoading(),
        isA<InventoryItemsLoaded>()
            .having((s) => s.items.length, 'has 2 items', equals(2))
            .having((s) => s.lowStockCount, 'Diesel is low stock', equals(1)),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading, InventoryError] when repository throws',
      build: () {
        when(
          () => mockRepository.getInventoryItems(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            category: any(named: 'category'),
          ),
        ).thenThrow(Exception('Network error'));

        return inventoryBloc;
      },
      act: (bloc) => bloc.add(const LoadInventoryItemsEvent()),
      expect: () => [
        const InventoryLoading(),
        isA<InventoryError>().having(
          (s) => s.message,
          'contains error',
          contains('Network error'),
        ),
      ],
    );
  });

  group('InitializeInventoryItemFormEvent', () {
    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading, InventoryFormState] with new blank item',
      build: () => inventoryBloc,
      act: (bloc) => bloc.add(
        const InitializeInventoryItemFormEvent(siteId: defaultSiteId),
      ),
      expect: () => [
        const InventoryLoading(),
        isA<InventoryFormState>()
            .having(
              (s) => s.item.siteId,
              'siteId matches',
              equals(defaultSiteId),
            )
            .having((s) => s.item.itemName, 'item name is empty', equals(''))
            .having((s) => s.item.quantityOnHand, 'quantity is 0', equals(0.0)),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading, InventoryFormState] with existing item when editing',
      build: () => inventoryBloc,
      act: (bloc) => bloc.add(
        const InitializeInventoryItemFormEvent(
          siteId: defaultSiteId,
          existingItem: InventoryItem(
            id: 'inv-edit-001',
            siteId: defaultSiteId,
            itemName: 'Diesel Fuel',
            quantityOnHand: 150.0,
          ),
        ),
      ),
      expect: () => [
        const InventoryLoading(),
        isA<InventoryFormState>()
            .having(
              (s) => s.item.id,
              'id matches existing',
              equals('inv-edit-001'),
            )
            .having(
              (s) => s.item.itemName,
              'name matches',
              equals('Diesel Fuel'),
            ),
      ],
    );
  });

  group('Inventory Form Field Changes', () {
    blocTest<InventoryBloc, InventoryState>(
      'updates item name and marks unsaved changes',
      build: () => inventoryBloc,
      seed: () => const InventoryFormState(
        item: InventoryItem(id: 'inv-001', siteId: defaultSiteId, itemName: ''),
      ),
      act: (bloc) => bloc.add(const ItemNameChangedEvent('Diesel Fuel')),
      expect: () => [
        isA<InventoryFormState>()
            .having(
              (s) => s.item.itemName,
              'name updated',
              equals('Diesel Fuel'),
            )
            .having((s) => s.hasUnsavedChanges, 'has unsaved changes', isTrue),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'updates quantity and marks unsaved changes',
      build: () => inventoryBloc,
      seed: () => const InventoryFormState(
        item: InventoryItem(
          id: 'inv-001',
          siteId: defaultSiteId,
          itemName: 'Diesel Fuel',
        ),
      ),
      act: (bloc) => bloc.add(const QuantityOnHandChangedEvent(150.0)),
      expect: () => [
        isA<InventoryFormState>().having(
          (s) => s.item.quantityOnHand,
          'quantity updated',
          equals(150.0),
        ),
      ],
    );
  });

  group('SaveInventoryItemEvent', () {
    blocTest<InventoryBloc, InventoryState>(
      'emits saved state when repository succeeds',
      build: () {
        when(
          () => mockRepository.saveInventoryItem(any()),
        ).thenAnswer((_) async => {});
        return inventoryBloc;
      },
      seed: () => const InventoryFormState(
        item: InventoryItem(
          id: 'inv-001',
          siteId: defaultSiteId,
          itemName: 'Diesel Fuel',
        ),
      ),
      act: (bloc) => bloc.add(const SaveInventoryItemEvent()),
      expect: () => [
        isA<InventoryFormState>().having((s) => s.isSaving, 'isSaving', isTrue),
        isA<InventoryFormState>()
            .having((s) => s.isSaving, 'done saving', isFalse)
            .having((s) => s.isSaved, 'is saved', isTrue)
            .having((s) => s.successMessage, 'has success', isNotNull),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits error state when repository throws',
      build: () {
        when(
          () => mockRepository.saveInventoryItem(any()),
        ).thenThrow(Exception('Save failed'));
        return inventoryBloc;
      },
      seed: () => const InventoryFormState(
        item: InventoryItem(
          id: 'inv-001',
          siteId: defaultSiteId,
          itemName: 'Diesel Fuel',
        ),
      ),
      act: (bloc) => bloc.add(const SaveInventoryItemEvent()),
      expect: () => [
        isA<InventoryFormState>().having((s) => s.isSaving, 'isSaving', isTrue),
        isA<InventoryFormState>()
            .having((s) => s.isSaving, 'done saving', isFalse)
            .having((s) => s.isSaved, 'not saved', isFalse)
            .having(
              (s) => s.errorMessage,
              'has error',
              contains('Save failed'),
            ),
      ],
    );
  });

  group('AdjustStockEvent', () {
    blocTest<InventoryBloc, InventoryState>(
      'adjusts stock and reloads items',
      build: () {
        when(
          () => mockRepository.updateInventoryQuantity(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockRepository.getInventoryItems(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => []);
        return inventoryBloc;
      },
      seed: () => const InventoryItemsLoaded(items: []),
      act: (bloc) => bloc.add(
        const AdjustStockEvent(itemId: 'inv-001', deltaQuantity: -10.0),
      ),
      expect: () => [isA<InventoryLoading>(), isA<InventoryItemsLoaded>()],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits error when adjustment throws',
      build: () {
        when(
          () => mockRepository.updateInventoryQuantity(any(), any()),
        ).thenThrow(Exception('Adjustment failed'));
        return inventoryBloc;
      },
      act: (bloc) => bloc.add(
        const AdjustStockEvent(itemId: 'inv-001', deltaQuantity: -10.0),
      ),
      expect: () => [
        isA<InventoryError>().having(
          (s) => s.message,
          'has error',
          contains('Adjustment failed'),
        ),
      ],
    );
  });

  group('DeleteInventoryItemEvent', () {
    blocTest<InventoryBloc, InventoryState>(
      'deletes item and reloads list when in loaded state',
      build: () {
        when(
          () => mockRepository.deleteInventoryItem(any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockRepository.getInventoryItems(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => []);
        return inventoryBloc;
      },
      seed: () => const InventoryItemsLoaded(items: []),
      act: (bloc) => bloc.add(const DeleteInventoryItemEvent('inv-001')),
      expect: () => [isA<InventoryLoading>(), isA<InventoryItemsLoaded>()],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits error when delete throws',
      build: () {
        when(
          () => mockRepository.deleteInventoryItem(any()),
        ).thenThrow(Exception('Delete failed'));
        return inventoryBloc;
      },
      act: (bloc) => bloc.add(const DeleteInventoryItemEvent('inv-001')),
      expect: () => [
        isA<InventoryError>().having(
          (s) => s.message,
          'has error',
          contains('Delete failed'),
        ),
      ],
    );
  });

  group('LoadItemNameSuggestionsEvent (auto-predict)', () {
    blocTest<InventoryBloc, InventoryState>(
      'clears suggestions when prefix is empty',
      build: () => inventoryBloc,
      seed: () => const InventoryFormState(
        item: InventoryItem(id: 'inv-001', siteId: defaultSiteId, itemName: ''),
        suggestions: ['Diesel Fuel', 'Safety Helmet'],
      ),
      act: (bloc) => bloc.add(const LoadItemNameSuggestionsEvent('')),
      expect: () => [
        isA<InventoryFormState>().having(
          (s) => s.suggestions,
          'suggestions cleared',
          isEmpty,
        ),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'loads suggestions from repository and emits them',
      build: () {
        when(
          () => mockRepository.getDistinctItemNames(any()),
        ).thenAnswer((_) async => ['Diesel Fuel', 'Drill Bit', 'Drain Pump']);
        return inventoryBloc;
      },
      seed: () => const InventoryFormState(
        item: InventoryItem(id: 'inv-001', siteId: defaultSiteId, itemName: ''),
      ),
      act: (bloc) => bloc.add(const LoadItemNameSuggestionsEvent('Dr')),
      expect: () => [
        isA<InventoryFormState>().having(
          (s) => s.suggestions,
          'suggestions from repo',
          equals(['Diesel Fuel', 'Drill Bit', 'Drain Pump']),
        ),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'silently ignores repository errors (no state change)',
      build: () {
        when(
          () => mockRepository.getDistinctItemNames(any()),
        ).thenThrow(Exception('DB error'));
        return inventoryBloc;
      },
      seed: () => const InventoryFormState(
        item: InventoryItem(id: 'inv-001', siteId: defaultSiteId, itemName: ''),
        suggestions: ['Existing'],
      ),
      act: (bloc) => bloc.add(const LoadItemNameSuggestionsEvent('Dr')),
      expect: () => [],
    );

    blocTest<InventoryBloc, InventoryState>(
      'does nothing when not in form state',
      build: () => inventoryBloc,
      seed: () => const InventoryItemsLoaded(items: []),
      act: (bloc) => bloc.add(const LoadItemNameSuggestionsEvent('Dr')),
      expect: () => [],
    );
  });

  group('FilterByCategoryEvent', () {
    blocTest<InventoryBloc, InventoryState>(
      'reloads items with selected category filter',
      build: () {
        when(
          () => mockRepository.getInventoryItems(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => []);
        return inventoryBloc;
      },
      seed: () => const InventoryItemsLoaded(items: []),
      act: (bloc) => bloc.add(const FilterByCategoryEvent('Fuel & Lubricants')),
      expect: () => [isA<InventoryLoading>(), isA<InventoryItemsLoaded>()],
    );
  });
}
