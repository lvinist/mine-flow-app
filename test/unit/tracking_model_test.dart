import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/tracking/data/models/cut_fill_model.dart';
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
      bcmVolume: 1500.0,
      lcmVolume: 500.0,
      elevationChange: -2.5,
      measurementDate: DateTime(2026, 7, 18),
      measuredBy: 'surveyor-01',
      notes: 'Pit excavation section A',
    );

    test('should calculate netVolume as bank-equivalent', () {
      expect(tRecord.netVolume, equals(1900.0));
    });

    test('should construct CutFillModel from entity and back', () {
      final model = CutFillModel.fromDomain(tRecord);
      expect(model.bcmVolume, equals(1500.0));
      expect(model.lcmVolume, equals(500.0));
      expect(model.netVolume, equals(1900.0));

      final restored = model.toDomain();
      expect(restored.bcmVolume, equals(1500.0));
      expect(restored.lcmVolume, equals(500.0));
      expect(restored.netVolume, equals(1900.0));
    });

    test('should serialize/deserialize JSON correctly', () {
      final model = CutFillModel.fromDomain(tRecord);
      final json = model.toJson();
      expect(json['bcm_volume'], equals(1500.0));
      expect(json['lcm_volume'], equals(500.0));
      expect(json['material_type'], isNull);

      final deserialized = CutFillModel.fromJson(json);
      expect(deserialized.bcmVolume, equals(1500.0));
      expect(deserialized.lcmVolume, equals(500.0));
    });
  });

  group('LandClearingRecord Domain & Model', () {
    final tRecord = LandClearingRecord(
      id: 'lc-001',
      siteId: defaultSiteId,
      zoneId: 'zone-east',
      planArea: 15000.0,
      actualArea: 25000.0,
      method: 'Bulldozer',
      clearingDate: DateTime(2026, 7, 18),
      clearedBy: 'crew-lead-02',
      notes: 'Forestry clearing',
    );

    test('should calculate totalArea as plan-vs-actual variance', () {
      expect(tRecord.totalArea, equals(10000.0));
    });

    test('should construct LandClearingModel from entity and back', () {
      final model = LandClearingModel.fromDomain(tRecord);
      expect(model.planArea, equals(15000.0));
      expect(model.actualArea, equals(25000.0));
      expect(model.method, equals('Bulldozer'));

      final restored = model.toDomain();
      expect(restored.planArea, equals(15000.0));
      expect(restored.actualArea, equals(25000.0));
    });

    test('should serialize/deserialize JSON with plan_area/actual_area', () {
      final model = LandClearingModel.fromDomain(tRecord);
      final json = model.toJson();
      expect(json['plan_area'], equals(15000.0));
      expect(json['actual_area'], equals(25000.0));
      expect(json['method'], equals('Bulldozer'));

      final deserialized = LandClearingModel.fromJson(json);
      expect(deserialized.planArea, equals(15000.0));
      expect(deserialized.actualArea, equals(25000.0));
    });
  });

  group('InventoryItem Domain & Model', () {
    const tItem = InventoryItem(
      id: 'inv-001',
      siteId: defaultSiteId,
      itemName: 'Fuel',
      quantityOnHand: 100.0,
      unit: 'Liters',
      minThreshold: 50.0,
    );

    test('should detect low stock', () {
      expect(tItem.isLowStock, isFalse);
      final low = tItem.copyWith(quantityOnHand: 30.0);
      expect(low.isLowStock, isTrue);
    });
  });
}
