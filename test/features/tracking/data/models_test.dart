import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/tracking/data/models/cut_fill_model.dart';
import 'package:mine_flow/features/tracking/data/models/inventory_item_model.dart';
import 'package:mine_flow/features/tracking/data/models/land_clearing_model.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';

  group('CutFillModel Serialization', () {
    final tEntity = CutFillRecord(
      id: 'cf-001',
      siteId: defaultSiteId,
      zoneId: 'zone-north',
      cutVolumeM3: 1500.0,
      fillVolumeM3: 500.0,
      elevationChange: -2.5,
      measurementDate: DateTime(2026, 7, 18),
      measuredBy: 'surveyor-01',
      notes: 'Test excavation',
      createdAt: DateTime(2026, 7, 18, 8, 0, 0),
      updatedAt: DateTime(2026, 7, 18, 8, 30, 0),
    );

    test('fromDomain and toDomain should round-trip correctly', () {
      final model = CutFillModel.fromDomain(tEntity);
      final domain = model.toDomain();

      expect(domain.id, equals(tEntity.id));
      expect(domain.cutVolumeM3, equals(1500.0));
      expect(domain.fillVolumeM3, equals(500.0));
      expect(domain.netVolumeM3, equals(1000.0));
    });

    test('toJson and fromJson should round-trip correctly', () {
      final model = CutFillModel.fromDomain(tEntity);
      final json = model.toJson();
      final restored = CutFillModel.fromJson(json);

      expect(restored.id, equals('cf-001'));
      expect(restored.cutVolumeM3, equals(1500.0));
      expect(restored.fillVolumeM3, equals(500.0));
      expect(restored.netVolumeM3, equals(1000.0));
    });

    test('toCoreModel and fromCoreModel should round-trip correctly', () {
      final model = CutFillModel.fromDomain(tEntity);
      final core = model.toCoreModel();
      final restored = CutFillModel.fromCoreModel(core);

      expect(restored.id, equals('cf-001'));
      expect(restored.cutVolumeM3, equals(1500.0));
      expect(restored.fillVolumeM3, equals(500.0));
      expect(restored.measurementDate, equals(tEntity.measurementDate));
    });

    test('should handle minimal record with only required fields', () {
      final minimal = CutFillModel(
        id: 'cf-minimal',
        siteId: defaultSiteId,
        zoneId: 'zone-test',
        measurementDate: DateTime(2026, 7, 18),
      );

      final json = minimal.toJson();
      expect(json['cut_volume'], equals(0.0));
      expect(json['fill_volume'], equals(0.0));

      final restored = CutFillModel.fromJson(json);
      expect(restored.id, equals('cf-minimal'));
      expect(restored.cutVolumeM3, equals(0.0));
    });

    test('JSON serialization should preserve field name mapping', () {
      final model = CutFillModel.fromDomain(tEntity);
      final json = model.toJson();

      expect(json['id'], equals('cf-001'));
      expect(json['cut_volume'], equals(1500.0));
      expect(json['fill_volume'], equals(500.0));
      expect(json['elevation_change'], equals(-2.5));
      expect(json['measured_at'], isNotNull);
    });
  });

  group('LandClearingModel Serialization', () {
    final tEntity = LandClearingRecord(
      id: 'lc-001',
      siteId: defaultSiteId,
      zoneId: 'zone-east',
      areaClearedM2: 25000.0,
      clearingMethod: 'Bulldozer',
      clearingDate: DateTime(2026, 7, 18),
      clearedBy: 'crew-01',
      notes: 'Complete',
    );

    test('fromDomain and toDomain should round-trip correctly', () {
      final model = LandClearingModel.fromDomain(tEntity);
      final domain = model.toDomain();

      expect(domain.id, equals('lc-001'));
      expect(domain.areaClearedM2, equals(25000.0));
      expect(domain.areaClearedHa, equals(2.5));
    });

    test('toJson and fromJson should round-trip correctly', () {
      final model = LandClearingModel.fromDomain(tEntity);
      final json = model.toJson();
      final restored = LandClearingModel.fromJson(json);

      expect(restored.id, equals('lc-001'));
      expect(restored.areaClearedM2, equals(25000.0));
      expect(restored.areaClearedHa, equals(2.5));
    });

    test('toCoreModel and fromCoreModel should round-trip correctly', () {
      final model = LandClearingModel.fromDomain(tEntity);
      final core = model.toCoreModel();
      final restored = LandClearingModel.fromCoreModel(core);

      expect(restored.id, equals('lc-001'));
      expect(restored.areaClearedM2, equals(25000.0));
      expect(restored.clearingMethod, equals('Bulldozer'));
    });

    test('JSON serialization should preserve area fields', () {
      final model = LandClearingModel.fromDomain(tEntity);
      final json = model.toJson();

      expect(json['area_cleared_m2'], equals(25000.0));
      expect(json['area_cleared_ha'], equals(2.5));
      expect(json['clearing_method'], equals('Bulldozer'));
    });
  });

  group('InventoryItemModel Serialization', () {
    const tEntity = InventoryItem(
      id: 'inv-001',
      siteId: defaultSiteId,
      zoneId: 'warehouse-01',
      itemName: 'Diesel Fuel',
      sku: 'FUEL-DSL-500',
      category: 'Fuel & Lubricants',
      quantityOnHand: 150.0,
      unit: 'Liters',
      minThreshold: 200.0,
    );

    test('fromDomain and toDomain should round-trip correctly', () {
      final model = InventoryItemModel.fromDomain(tEntity);
      final domain = model.toDomain();

      expect(domain.id, equals('inv-001'));
      expect(domain.itemName, equals('Diesel Fuel'));
      expect(domain.quantityOnHand, equals(150.0));
      expect(domain.isLowStock, isTrue);
    });

    test('toJson and fromJson should round-trip correctly', () {
      final model = InventoryItemModel.fromDomain(tEntity);
      final json = model.toJson();
      final restored = InventoryItemModel.fromJson(json);

      expect(restored.id, equals('inv-001'));
      expect(restored.itemName, equals('Diesel Fuel'));
      expect(restored.quantityOnHand, equals(150.0));
      expect(restored.category, equals('Fuel & Lubricants'));
    });

    test('toCoreModel and fromCoreModel should round-trip correctly', () {
      final model = InventoryItemModel.fromDomain(tEntity);
      final core = model.toCoreModel();
      final restored = InventoryItemModel.fromCoreModel(core);

      expect(restored.id, equals('inv-001'));
      expect(restored.itemName, equals('Diesel Fuel'));
      expect(restored.quantityOnHand, equals(150.0));
    });

    test(
      'JSON should include both quantity_on_hand and quantity for compatibility',
      () {
        final model = InventoryItemModel.fromDomain(tEntity);
        final json = model.toJson();

        expect(json['quantity_on_hand'], equals(150.0));
        expect(json['quantity'], equals(150.0));
        expect(json['item_name'], equals('Diesel Fuel'));
        expect(json['name'], equals('Diesel Fuel'));
      },
    );

    test('should handle minimal item with only required fields', () {
      const minimal = InventoryItemModel(
        id: 'inv-min',
        siteId: defaultSiteId,
        itemName: 'Test Item',
      );

      final json = minimal.toJson();
      expect(json['quantity_on_hand'], equals(0.0));
      expect(json['unit'], equals('pcs'));

      final restored = InventoryItemModel.fromJson(json);
      expect(restored.itemName, equals('Test Item'));
      expect(restored.unit, equals('pcs'));
    });
  });
}
