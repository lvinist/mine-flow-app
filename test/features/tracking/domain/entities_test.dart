import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

void main() {
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

  group('CutFillRecord Domain Entity', () {
    final tRecord = CutFillRecord(
      id: 'cf-001',
      siteId: defaultSiteId,
      zoneId: 'zone-north',
      bcmVolume: 1500.0,
      lcmVolume: 500.0,
      elevationChange: -2.5,
      measurementDate: DateTime(2026, 7, 18),
      measuredBy: 'surveyor-01',
      notes: 'Pit excavation section A',
    );

    test('should calculate netVolume as bank-equivalent (BCM + LCM/1.25)', () {
      expect(tRecord.netVolume, equals(1900.0));
    });

    test('should support copyWith and keep immutability', () {
      final updated = tRecord.copyWith(bcmVolume: 2000.0);
      expect(updated.bcmVolume, equals(2000.0));
      expect(updated.netVolume, equals(2400.0));
      expect(updated.id, equals('cf-001'));
      // Original unchanged
      expect(tRecord.bcmVolume, equals(1500.0));
    });

    test('should support Equatable value equality', () {
      final same = CutFillRecord(
        id: 'cf-001',
        siteId: defaultSiteId,
        zoneId: 'zone-north',
        bcmVolume: 1500.0,
        lcmVolume: 500.0,
        elevationChange: -2.5,
        measurementDate: DateTime(2026, 7, 18),
        measuredBy: 'surveyor-01',
        notes: 'Pit excavation section A',
      );
      expect(tRecord, equals(same));
    });

    test('should handle zero and low volumes (bank-equivalent)', () {
      final zeroRecord = tRecord.copyWith(bcmVolume: 0.0, lcmVolume: 0.0);
      expect(zeroRecord.netVolume, equals(0.0));

      final looseHeavy = tRecord.copyWith(bcmVolume: 100.0, lcmVolume: 500.0);
      // 100 + 500 / 1.25 = 500.0 (bank-equivalent, never negative).
      expect(looseHeavy.netVolume, equals(500.0));
    });

    test(
      'should have null elevationChange when constructing without elevation',
      () {
        final noElevation = CutFillRecord(
          id: 'cf-003',
          siteId: defaultSiteId,
          zoneId: 'zone-test',
          bcmVolume: 100.0,
          lcmVolume: 50.0,
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
      planArea: 15000.0,
      actualArea: 25000.0,
      method: 'Bulldozer & Excavator',
      clearingDate: DateTime(2026, 7, 18),
      clearedBy: 'crew-lead-02',
      notes: 'Forestry clearing complete',
    );

    test('should calculate totalArea as plan-vs-actual variance', () {
      expect(tRecord.totalArea, equals(10000.0));
    });

    test('should calculate totalAreaHa as variance in Hectares', () {
      expect(tRecord.totalAreaHa, equals(1.0));
    });

    test('should support copyWith and Equatable', () {
      final updated = tRecord.copyWith(planArea: 20000.0);
      expect(updated.totalArea, equals(5000.0));
      expect(updated.id, equals('lc-001'));
      expect(updated.method, equals('Bulldozer & Excavator'));
    });

    test('should handle zero area', () {
      final zeroRecord = tRecord.copyWith(planArea: 0.0, actualArea: 0.0);
      expect(zeroRecord.totalArea, equals(0.0));
      expect(zeroRecord.totalAreaHa, equals(0.0));
    });

    test(
      'should have null method when constructing without clearing method',
      () {
        final noMethod = LandClearingRecord(
          id: 'lc-003',
          siteId: defaultSiteId,
          zoneId: 'zone-test',
          planArea: 1000.0,
          actualArea: 500.0,
          clearingDate: DateTime(2026, 7, 18),
        );
        expect(noMethod.method, isNull);
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
