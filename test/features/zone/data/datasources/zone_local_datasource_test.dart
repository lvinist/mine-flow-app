import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/core/data/models/zone_model.dart';
import 'package:mine_flow/core/offline/adapters/model_adapters.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/features/zone/data/datasources/zone_local_datasource.dart';

void main() {
  late Directory tempDir;
  late Box<ZoneModel> zoneBox;
  late HiveCacheRepository<ZoneModel> zoneCache;
  late ZoneLocalDataSource localDataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zone_local_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ZoneModelAdapter());
    }

    zoneBox = await Hive.openBox<ZoneModel>(
      'test_zone_${DateTime.now().millisecondsSinceEpoch}',
    );

    zoneCache = HiveCacheRepository(zoneBox);
    localDataSource = ZoneLocalDataSourceImpl(zoneCache);
  });

  tearDown(() async {
    await zoneBox.clear();
    await zoneBox.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ZoneLocalDataSource', () {
    final testZone = ZoneModel(
      id: 'test-id-1',
      siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      name: 'Pit A - Utama (North Cut)',
      category: 'Pit',
      description: 'Primary excavation zone',
      createdAt: DateTime(2026, 7, 23),
      updatedAt: DateTime(2026, 7, 23),
    );

    final testZone2 = ZoneModel(
      id: 'test-id-2',
      siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      name: 'Stockpile 1 (ROM)',
      category: 'Stockpile',
      createdAt: DateTime(2026, 7, 23),
    );

    test('should store and retrieve a single zone', () async {
      await localDataSource.saveZone(testZone);

      final retrieved = localDataSource.getZoneById('test-id-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-id-1'));
      expect(retrieved.name, equals('Pit A - Utama (North Cut)'));
      expect(retrieved.category, equals('Pit'));
    });

    test('should return null for non-existent zone', () {
      final retrieved = localDataSource.getZoneById('non-existent');
      expect(retrieved, isNull);
    });

    test('should retrieve all zones', () async {
      await localDataSource.saveZone(testZone);
      await localDataSource.saveZone(testZone2);

      final allZones = localDataSource.getZones();
      expect(allZones.length, equals(2));
      expect(
        allZones.map((z) => z.id),
        containsAll(['test-id-1', 'test-id-2']),
      );
    });

    test('should update an existing zone', () async {
      await localDataSource.saveZone(testZone);

      final updatedZone = ZoneModel(
        id: 'test-id-1',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        name: 'Pit A - Utama (North Cut) - Updated',
        category: 'Pit',
        description: 'Updated description',
        createdAt: testZone.createdAt,
        updatedAt: DateTime(2026, 7, 24),
      );
      await localDataSource.saveZone(updatedZone);

      final retrieved = localDataSource.getZoneById('test-id-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, contains('Updated'));
      expect(retrieved.updatedAt, equals(DateTime(2026, 7, 24)));
    });

    test('should delete a zone', () async {
      await localDataSource.saveZone(testZone);
      expect(localDataSource.getZones().length, equals(1));

      await localDataSource.deleteZone('test-id-1');
      expect(localDataSource.getZones().length, equals(0));
      expect(localDataSource.getZoneById('test-id-1'), isNull);
    });

    test('should save and retrieve a batch of zones', () async {
      await localDataSource.saveZoneBatch([testZone, testZone2]);

      final allZones = localDataSource.getZones();
      expect(allZones.length, equals(2));
    });

    test('should return empty list when no zones stored', () {
      final allZones = localDataSource.getZones();
      expect(allZones, isEmpty);
    });
  });
}
