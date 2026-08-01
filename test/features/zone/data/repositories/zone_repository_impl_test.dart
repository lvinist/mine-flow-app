import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mine_flow/core/data/models/zone_model.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/model_adapters.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/zone/data/datasources/zone_local_datasource.dart';
import 'package:mine_flow/features/zone/data/repositories/zone_repository_impl.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';

class MockNetworkInfo implements NetworkInfo {
  bool isOnline = false;

  @override
  Future<bool> get isConnected async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';
  late Directory tempDir;
  late Box<ZoneModel> zoneBox;
  late Box<SyncQueueItem> queueBox;
  late HiveCacheRepository<ZoneModel> zoneCache;
  late HiveCacheRepository<SyncQueueItem> queueRepo;
  late MockNetworkInfo mockNetworkInfo;
  late SyncQueueManager syncQueueManager;
  late ZoneLocalDataSource localDataSource;
  late ZoneRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zone_repo_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ZoneModelAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SyncActionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }

    zoneBox = await Hive.openBox<ZoneModel>(
      'test_zone_${DateTime.now().millisecondsSinceEpoch}',
    );
    queueBox = await Hive.openBox<SyncQueueItem>(
      'test_q_${DateTime.now().millisecondsSinceEpoch}',
    );

    zoneCache = HiveCacheRepository(zoneBox);
    queueRepo = HiveCacheRepository(queueBox);

    mockNetworkInfo = MockNetworkInfo();
    syncQueueManager = SyncQueueManager(
      queueRepository: queueRepo,
      networkInfo: mockNetworkInfo,
    );

    localDataSource = ZoneLocalDataSourceImpl(zoneCache);

    repository = ZoneRepositoryImpl(
      localDataSource: localDataSource,
      syncQueueManager: syncQueueManager,
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() async {
    await zoneBox.clear();
    await zoneBox.close();
    await queueBox.clear();
    await queueBox.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ZoneRepository', () {
    final testZone = ZoneEntity(
      id: 'test-id-1',
      siteId: defaultSiteId,
      name: 'Pit A - Utama (North Cut)',
      category: 'Pit',
      description: 'Primary excavation zone',
      createdAt: DateTime(2026, 7, 23),
      updatedAt: DateTime(2026, 7, 23),
    );

    final testZone2 = ZoneEntity(
      id: 'test-id-2',
      siteId: defaultSiteId,
      name: 'Stockpile 1 (ROM)',
      category: 'Stockpile',
      createdAt: DateTime(2026, 7, 23),
    );

    test('should store and retrieve a zone', () async {
      await repository.saveZone(testZone);

      final result = repository.getZoneById('test-id-1');
      expect(result, isNotNull);
      expect(result!.id, equals('test-id-1'));
      expect(result.name, equals('Pit A - Utama (North Cut)'));
    });

    test('should return null for non-existent zone', () {
      final result = repository.getZoneById('non-existent');
      expect(result, isNull);
    });

    test('should retrieve all stored zones', () async {
      await repository.saveZone(testZone);
      await repository.saveZone(testZone2);

      final allZones = repository.getZones();
      expect(allZones.length, equals(2));
      expect(
        allZones.map((z) => z.id),
        containsAll(['test-id-1', 'test-id-2']),
      );
    });

    test('should soft-delete a zone and exclude from getZones', () async {
      await repository.saveZone(testZone);
      expect(repository.getZones().length, equals(1));

      await repository.deleteZone('test-id-1');
      expect(repository.getZones().length, equals(0));
      expect(repository.getZoneById('test-id-1'), isNull);
    });

    test('should preserve soft-deleted zone in local box', () async {
      await repository.saveZone(testZone);
      await repository.deleteZone('test-id-1');

      // The original model is still in the box with deletedAt set
      final rawModel = zoneCache.get('test-id-1');
      expect(rawModel, isNotNull);
      expect(rawModel!.deletedAt, isNotNull);
    });

    test('should enqueue sync mutation on save', () async {
      await repository.saveZone(testZone);

      final queueItems = queueRepo.getAll();
      expect(queueItems.length, equals(1));
      expect(queueItems.first.action, equals(SyncAction.update));
      expect(queueItems.first.entityType, equals('zones'));
    });

    test('should enqueue sync mutation on delete', () async {
      await repository.saveZone(testZone);
      // Clear the save queue item
      await queueRepo.clear();

      await repository.deleteZone('test-id-1');

      final queueItems = queueRepo.getAll();
      expect(queueItems.length, equals(1));
      expect(queueItems.first.action, equals(SyncAction.delete));
      expect(queueItems.first.entityType, equals('zones'));
    });

    test('should filter out soft-deleted zones from getZones', () async {
      await repository.saveZone(testZone);
      await repository.saveZone(testZone2);

      // Manually soft-delete testZone2 in the box
      final updated = ZoneModel(
        id: testZone2.id,
        siteId: testZone2.siteId,
        name: testZone2.name,
        category: testZone2.category,
        createdAt: testZone2.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
      await zoneCache.put(testZone2.id, updated);

      final allZones = repository.getZones();
      expect(allZones.length, equals(1));
      expect(allZones.first.id, equals('test-id-1'));
    });

    test('should assign updatedAt on save when null', () async {
      final newZone = ZoneEntity(
        id: 'new-zone',
        siteId: defaultSiteId,
        name: 'New Zone',
        createdAt: DateTime(2026, 7, 23),
      );

      await repository.saveZone(newZone);

      final retrieved = repository.getZoneById('new-zone');
      expect(retrieved, isNotNull);
      expect(retrieved!.updatedAt, isNotNull);
    });

    test('should handle delete on non-existent zone without error', () async {
      // Should not throw when deleting a zone that was never saved
      await expectLater(repository.deleteZone('non-existent'), completes);
    });
  });
}
