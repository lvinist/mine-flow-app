import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/tracking/data/models/cut_fill_model.dart';
import 'package:mine_flow/features/tracking/data/models/inventory_item_model.dart';
import 'package:mine_flow/features/tracking/data/models/land_clearing_model.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';

  group('CutFillRecord Domain & Model', () {
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

    test('should support copyWith and Equatable', () {
      final updated = tRecord.copyWith(cutVolumeM3: 2000.0);
      expect(updated.cutVolumeM3, equals(2000.0));
      expect(updated.netVolumeM3, equals(1500.0));
      expect(updated.id, equals('cf-001'));
    });

    test('should serialize and deserialize JSON with CutFillModel', () {
      final model = CutFillModel.fromDomain(tRecord);
      final json = model.toJson();
      final restoredModel = CutFillModel.fromJson(json);

      expect(restoredModel.id, equals(tRecord.id));
      expect(restoredModel.cutVolumeM3, equals(tRecord.cutVolumeM3));
      expect(restoredModel.fillVolumeM3, equals(tRecord.fillVolumeM3));
      expect(restoredModel.netVolumeM3, equals(1000.0));
    });
  });

  group('LandClearingRecord Domain & Model', () {
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
    });

    test('should serialize and deserialize JSON with LandClearingModel', () {
      final model = LandClearingModel.fromDomain(tRecord);
      final json = model.toJson();
      final restoredModel = LandClearingModel.fromJson(json);

      expect(restoredModel.id, equals(tRecord.id));
      expect(restoredModel.areaClearedM2, equals(25000.0));
      expect(restoredModel.areaClearedHa, equals(2.5));
    });
  });

  group('InventoryItem Domain & Model', () {
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

    test('should evaluate isLowStock correctly', () {
      expect(tItem.isLowStock, isTrue);

      final highStockItem = tItem.copyWith(quantityOnHand: 500.0);
      expect(highStockItem.isLowStock, isFalse);
    });

    test('should serialize and deserialize JSON with InventoryItemModel', () {
      final model = InventoryItemModel.fromDomain(tItem);
      final json = model.toJson();
      final restoredModel = InventoryItemModel.fromJson(json);

      expect(restoredModel.id, equals(tItem.id));
      expect(restoredModel.itemName, equals('Diesel Fuel'));
      expect(restoredModel.quantityOnHand, equals(150.0));
      expect(restoredModel.isLowStock, isTrue);
    });
  });
}
