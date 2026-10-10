import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_draft_restoration.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';

void main() {
  group('InventoryDraftRestoration', () {
    test('round-trip equality: encode → decode → fields equal', () {
      const item = InventoryItem(
        id: 'inv-1',
        siteId: 'SITE-01',
        zoneId: 'ZONE-51',
        itemName: 'Survey Pole',
        sku: 'SKU-001',
        category: 'Hardware',
        quantityOnHand: 42.0,
        unit: 'pcs',
        minThreshold: 5.0,
        notes: 'Near entrance',
      );
      const formState = InventoryFormState(item: item);

      final encoded = InventoryDraftRestoration.encode(formState);
      final decoded = InventoryDraftRestoration.decode(encoded, 'SITE-01');

      expect(decoded, isNotNull);
      expect(decoded!.itemName, 'Survey Pole');
      expect(decoded.category, 'Hardware');
      expect(decoded.quantityOnHand, 42.0);
      expect(decoded.unit, 'pcs');
      expect(decoded.minThreshold, 5.0);
      expect(decoded.sku, 'SKU-001');
      expect(decoded.notes, 'Near entrance');
      expect(decoded.zoneId, 'ZONE-51');
    });

    test('version-mismatch fallback: old version → null', () {
      const oldSnapshot =
          '{"version":2,"siteId":"SITE-01","zoneId":"ZONE-51","itemName":"x",'
          '"category":"y","quantityOnHand":1,"unit":"pcs","minThreshold":0,'
          '"sku":"s","notes":"n"}';
      final decoded = InventoryDraftRestoration.decode(oldSnapshot, 'SITE-01');
      expect(decoded, isNull);
    });

    test('malformed JSON → null', () {
      final decoded = InventoryDraftRestoration.decode(
        'not valid json',
        'SITE-01',
      );
      expect(decoded, isNull);
    });

    test('null snapshot → null', () {
      final decoded = InventoryDraftRestoration.decode(null, 'SITE-01');
      expect(decoded, isNull);
    });

    test('siteId mismatch → null', () {
      const item = InventoryItem(
        id: 'inv-1',
        siteId: 'SITE-01',
        zoneId: 'ZONE-51',
        itemName: 'Pole',
        quantityOnHand: 1.0,
        unit: 'pcs',
      );
      const formState = InventoryFormState(item: item);
      final encoded = InventoryDraftRestoration.encode(formState);
      final decoded = InventoryDraftRestoration.decode(encoded, 'SITE-99');
      expect(decoded, isNull);
    });

    test('missing required fields → null', () {
      final decoded = InventoryDraftRestoration.decode(
        '{"version":1,"siteId":"SITE-01","quantityOnHand":1,"unit":"pcs"}',
        'SITE-01',
      );
      expect(decoded, isNull);
    });

    test('CONTEXT fields (id, timestamps) never in snapshot', () {
      final item = InventoryItem(
        id: 'inv-secret-id',
        siteId: 'SITE-01',
        itemName: 'Pole',
        quantityOnHand: 1.0,
        unit: 'pcs',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 6, 1),
        deletedAt: DateTime(2024, 9, 1),
      );
      final formState = InventoryFormState(item: item);
      final encoded = InventoryDraftRestoration.encode(formState);

      expect(encoded, isNot(contains('"id"')));
      expect(encoded, isNot(contains('createdAt')));
      expect(encoded, isNot(contains('updatedAt')));
      expect(encoded, isNot(contains('deletedAt')));
    });
  });
}
