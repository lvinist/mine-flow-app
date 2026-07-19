import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';

  group('CutFillRecord Domain Entity', () {
    final tRecord = CutFillRecord(
      id: 'cf-001',
      siteId: defaultSiteId,
      zoneId: 'zone-north',
      cutVolumeM3: 1500.0,
      fillVolumeM3: 500.0,
      elevationChange: -2.5,
      measurementDate: DateTime(2026, 7, 18),
      measuredBy: 'surveyor-01',
      notes: 'Pit excavation section A',
    );

    test('should calculate netVolumeM3 correctly (Cut - Fill)', () {
      expect(tRecord.netVolumeM3, equals(1000.0));
    });

    test('should support copyWith and keep immutability', () {
      final updated = tRecord.copyWith(cutVolumeM3: 2000.0);
      expect(updated.cutVolumeM3, equals(2000.0));
      expect(updated.netVolumeM3, equals(1500.0));
      expect(updated.id, equals('cf-001'));
      // Original unchanged
      expect(tRecord.cutVolumeM3, equals(1500.0));
    });

    test('should support Equatable value equality', () {
      final same = CutFillRecord(
        id: 'cf-001',
        siteId: defaultSiteId,
        zoneId: 'zone-north',
        cutVolumeM3: 1500.0,
        fillVolumeM3: 500.0,
        elevationChange: -2.5,
        measurementDate: DateTime(2026, 7, 18),
        measuredBy: 'surveyor-01',
        notes: 'Pit excavation section A',
      );
      expect(tRecord, equals(same));
    });

    test('should handle zero and negative volumes', () {
      final zeroRecord = tRecord.copyWith(cutVolumeM3: 0.0, fillVolumeM3: 0.0);
      expect(zeroRecord.netVolumeM3, equals(0.0));

      final negativeNet = tRecord.copyWith(
        cutVolumeM3: 100.0,
        fillVolumeM3: 500.0,
      );
      expect(negativeNet.netVolumeM3, equals(-400.0));
    });

    test(
      'should have null elevationChange when constructing without elevation',
      () {
        final noElevation = CutFillRecord(
          id: 'cf-003',
          siteId: defaultSiteId,
          zoneId: 'zone-test',
          cutVolumeM3: 100.0,
          fillVolumeM3: 50.0,
          measurementDate: DateTime(2026, 7, 18),
        );
        expect(noElevation.elevationChange, isNull);
      },
    );
  });

  group('LandClearingRecord Domain Entity', () {
    final tRecord = LandClearingRecord(
      id: 'lc-001',
      siteId: defaultSiteId,
      zoneId: 'zone-east',
      areaClearedM2: 25000.0,
      clearingMethod: 'Bulldozer & Excavator',
      clearingDate: DateTime(2026, 7, 18),
      clearedBy: 'crew-lead-02',
      notes: 'Forestry clearing complete',
    );

    test('should calculate areaClearedHa correctly (m2 to Ha)', () {
      expect(tRecord.areaClearedHa, equals(2.5));
    });

    test('should support copyWith and Equatable', () {
      final updated = tRecord.copyWith(areaClearedM2: 50000.0);
      expect(updated.areaClearedHa, equals(5.0));
      expect(updated.id, equals('lc-001'));
      expect(updated.clearingMethod, equals('Bulldozer & Excavator'));
    });

    test('should handle zero area', () {
      final zeroRecord = tRecord.copyWith(areaClearedM2: 0.0);
      expect(zeroRecord.areaClearedHa, equals(0.0));
      expect(zeroRecord.areaClearedM2, equals(0.0));
    });

    test(
      'should have null clearingMethod when constructing without clearing method',
      () {
        final noMethod = LandClearingRecord(
          id: 'lc-003',
          siteId: defaultSiteId,
          zoneId: 'zone-test',
          areaClearedM2: 1000.0,
          clearingDate: DateTime(2026, 7, 18),
        );
        expect(noMethod.clearingMethod, isNull);
      },
    );
  });

  group('InventoryItem Domain Entity', () {
    const tItem = InventoryItem(
      id: 'inv-001',
      siteId: defaultSiteId,
      zoneId: 'warehouse-01',
      itemName: 'Diesel Fuel',
      sku: 'FUEL-DSL-500',
      category: 'Fuel & Lubricants',
      quantityOnHand: 150.0,
      unit: 'Liters',
      minThreshold: 200.0,
      notes: 'Low stock alert active',
    );

    test('should evaluate isLowStock when quantity <= threshold', () {
      expect(tItem.isLowStock, isTrue);

      final highStockItem = tItem.copyWith(quantityOnHand: 500.0);
      expect(highStockItem.isLowStock, isFalse);
    });

    test('should evaluate isLowStock as false when threshold is zero', () {
      final noThreshold = tItem.copyWith(minThreshold: 0.0);
      expect(noThreshold.isLowStock, isFalse);
    });

    test('should evaluate isLowStock as false when no threshold is set', () {
      const noThreshold = InventoryItem(
        id: 'inv-003',
        siteId: defaultSiteId,
        itemName: 'Test Item',
        quantityOnHand: 150.0,
      );
      expect(noThreshold.isLowStock, isFalse);
    });

    test('should handle edge case where quantity equals threshold exactly', () {
      final exactMatch = tItem.copyWith(
        quantityOnHand: 200.0,
        minThreshold: 200.0,
      );
      expect(exactMatch.isLowStock, isTrue);
    });

    test('should support copyWith and Equatable', () {
      final updated = tItem.copyWith(itemName: 'Bio Diesel');
      expect(updated.itemName, equals('Bio Diesel'));
      expect(updated.id, equals('inv-001'));
      expect(tItem.itemName, equals('Diesel Fuel'));
    });
  });
}
