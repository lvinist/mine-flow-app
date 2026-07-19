import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mine_flow/core/data/models/cut_fill_record_model.dart';
import 'package:mine_flow/core/data/models/inventory_item_model.dart'
    as core_models;
import 'package:mine_flow/core/data/models/land_clearing_record_model.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/model_adapters.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/tracking/data/datasources/tracking_local_datasource.dart';
import 'package:mine_flow/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:mine_flow/features/tracking/data/models/cut_fill_model.dart';
import 'package:mine_flow/features/tracking/data/models/land_clearing_model.dart';
import 'package:mine_flow/features/tracking/data/models/inventory_item_model.dart';
import 'package:mine_flow/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

class MockNetworkInfo implements NetworkInfo {
  bool isOnline = false;

  @override
  Future<bool> get isConnected async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

class MockTrackingRemoteDataSource implements TrackingRemoteDataSource {
  final List<CutFillModel> cutFillDb = [];
  final List<LandClearingModel> landClearingDb = [];
  final List<InventoryItemModel> inventoryDb = [];

  @override
  Future<List<CutFillModel>> fetchCutFillRecords() async =>
      List.from(cutFillDb);

  @override
  Future<CutFillModel> createCutFillRecord(CutFillModel record) async {
    cutFillDb.removeWhere((r) => r.id == record.id);
    cutFillDb.add(record);
    return record;
  }

  @override
  Future<void> deleteCutFillRecord(String id) async {
    cutFillDb.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<LandClearingModel>> fetchLandClearingRecords() async =>
      List.from(landClearingDb);

  @override
  Future<LandClearingModel> createLandClearingRecord(
    LandClearingModel record,
  ) async {
    landClearingDb.removeWhere((r) => r.id == record.id);
    landClearingDb.add(record);
    return record;
  }

  @override
  Future<void> deleteLandClearingRecord(String id) async {
    landClearingDb.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<InventoryItemModel>> fetchInventoryItems() async =>
      List.from(inventoryDb);

  @override
  Future<InventoryItemModel> saveInventoryItem(InventoryItemModel item) async {
    inventoryDb.removeWhere((i) => i.id == item.id);
    inventoryDb.add(item);
    return item;
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    inventoryDb.removeWhere((i) => i.id == id);
  }
}

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';
  late Directory tempDir;
  late Box<CutFillRecordModel> cutFillBox;
  late Box<LandClearingRecordModel> landClearingBox;
  late Box<core_models.InventoryItemModel> inventoryBox;
  late Box<SyncQueueItem> queueBox;
  late HiveCacheRepository<CutFillRecordModel> cutFillCache;
  late HiveCacheRepository<LandClearingRecordModel> landClearingCache;
  late HiveCacheRepository<core_models.InventoryItemModel> inventoryCache;
  late HiveCacheRepository<SyncQueueItem> queueRepo;
  late MockNetworkInfo mockNetworkInfo;
  late SyncQueueManager syncQueueManager;
  late MockTrackingRemoteDataSource mockRemoteDataSource;
  late TrackingLocalDataSource localDataSource;
  late TrackingRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tracking_repo_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(CutFillRecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(LandClearingRecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(InventoryItemModelAdapter());
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

    cutFillBox = await Hive.openBox<CutFillRecordModel>(
      'test_cf_${DateTime.now().millisecondsSinceEpoch}',
    );
    landClearingBox = await Hive.openBox<LandClearingRecordModel>(
      'test_lc_${DateTime.now().millisecondsSinceEpoch}',
    );
    inventoryBox = await Hive.openBox<core_models.InventoryItemModel>(
      'test_inv_${DateTime.now().millisecondsSinceEpoch}',
    );
    queueBox = await Hive.openBox<SyncQueueItem>(
      'test_q_${DateTime.now().millisecondsSinceEpoch}',
    );

    cutFillCache = HiveCacheRepository(cutFillBox);
    landClearingCache = HiveCacheRepository(landClearingBox);
    inventoryCache = HiveCacheRepository(inventoryBox);
    queueRepo = HiveCacheRepository(queueBox);

    mockNetworkInfo = MockNetworkInfo();
    syncQueueManager = SyncQueueManager(
      queueRepository: queueRepo,
      networkInfo: mockNetworkInfo,
    );
    mockRemoteDataSource = MockTrackingRemoteDataSource();

    localDataSource = TrackingLocalDataSourceImpl(
      cutFillCache: cutFillCache,
      landClearingCache: landClearingCache,
      inventoryCache: inventoryCache,
    );

    repository = TrackingRepositoryImpl(
      localDataSource: localDataSource,
      syncQueueManager: syncQueueManager,
      networkInfo: mockNetworkInfo,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  tearDown(() async {
    await cutFillBox.clear();
    await cutFillBox.close();
    await landClearingBox.clear();
    await landClearingBox.close();
    await inventoryBox.clear();
    await inventoryBox.close();
    await queueBox.clear();
    await queueBox.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Cut/Fill Repository Operations', () {
    final tRecord = CutFillRecord(
      id: 'cf-001',
      siteId: defaultSiteId,
      zoneId: 'zone-north',
      cutVolumeM3: 1500.0,
      fillVolumeM3: 500.0,
      measurementDate: DateTime(2026, 7, 18),
      measuredBy: 'surveyor-01',
      createdAt: DateTime(2026, 7, 18, 8, 0, 0),
    );

    test(
      'saveCutFillRecord should write to local cache and enqueue sync mutation',
      () async {
        await repository.saveCutFillRecord(tRecord);

        final cached = localDataSource.getCutFillRecordById('cf-001');
        expect(cached, isNotNull);
        expect(cached!.cutVolumeM3, equals(1500.0));

        final pending = queueRepo.getAll();
        expect(pending.length, equals(1));
        expect(pending.first.entityType, equals('cut_fill_records'));
        expect(pending.first.action, equals(SyncAction.update));
        expect(pending.first.payloadJson['id'], equals('cf-001'));
      },
    );

    test('getCutFillRecords should filter by zoneId', () async {
      await repository.saveCutFillRecord(tRecord);
      final otherRecord = tRecord.copyWith(
        id: 'cf-002',
        zoneId: 'zone-south',
        cutVolumeM3: 2000.0,
      );
      await repository.saveCutFillRecord(otherRecord);

      final northRecords = await repository.getCutFillRecords(
        zoneId: 'zone-north',
      );
      expect(northRecords.length, equals(1));
      expect(northRecords.first.id, equals('cf-001'));

      final southRecords = await repository.getCutFillRecords(
        zoneId: 'zone-south',
      );
      expect(southRecords.length, equals(1));
      expect(southRecords.first.id, equals('cf-002'));
    });

    test('getCutFillRecordById should return specific record', () async {
      await repository.saveCutFillRecord(tRecord);

      final result = await repository.getCutFillRecordById('cf-001');
      expect(result, isNotNull);
      expect(result!.cutVolumeM3, equals(1500.0));
      expect(result.fillVolumeM3, equals(500.0));
    });

    test(
      'getCutFillRecordById should return null for non-existent record',
      () async {
        final result = await repository.getCutFillRecordById('non-existent');
        expect(result, isNull);
      },
    );

    test(
      'deleteCutFillRecord should soft delete and enqueue delete mutation',
      () async {
        await repository.saveCutFillRecord(tRecord);
        await repository.deleteCutFillRecord('cf-001');

        // Should be soft-deleted (deletedAt not null)
        final cached = localDataSource.getCutFillRecordById('cf-001');
        expect(cached?.deletedAt, isNotNull);

        // Should not appear in active records
        final activeRecords = await repository.getCutFillRecords();
        expect(activeRecords.isEmpty, isTrue);

        // Should have both save and delete mutations enqueued
        final queueItems = queueRepo.getAll();
        final hasDelete = queueItems.any(
          (item) => item.action == SyncAction.delete,
        );
        expect(hasDelete, isTrue);
      },
    );

    test(
      'deleteCutFillRecord on non-existent should still enqueue delete',
      () async {
        await repository.deleteCutFillRecord('non-existent-cf');

        final queueItems = queueRepo.getAll();
        expect(queueItems.length, equals(1));
        expect(queueItems.first.action, equals(SyncAction.delete));
      },
    );

    test(
      'syncRemote should fetch remote data and update local cache',
      () async {
        mockNetworkInfo.isOnline = true;
        mockRemoteDataSource.cutFillDb.add(
          CutFillModel(
            id: 'remote-cf-001',
            siteId: defaultSiteId,
            zoneId: 'remote-zone',
            measurementDate: DateTime(2026, 7, 18),
          ),
        );

        await repository.syncRemote();

        final cached = localDataSource.getCutFillRecordById('remote-cf-001');
        expect(cached, isNotNull);
        expect(cached!.siteId, equals(defaultSiteId));
      },
    );
  });

  group('Land Clearing Repository Operations', () {
    final tRecord = LandClearingRecord(
      id: 'lc-001',
      siteId: defaultSiteId,
      zoneId: 'zone-east',
      areaClearedM2: 25000.0,
      clearingMethod: 'Bulldozer',
      clearingDate: DateTime(2026, 7, 18),
      clearedBy: 'crew-01',
    );

    test(
      'saveLandClearingRecord should write to local cache and enqueue sync mutation',
      () async {
        await repository.saveLandClearingRecord(tRecord);

        final cached = localDataSource.getLandClearingRecordById('lc-001');
        expect(cached, isNotNull);
        expect(cached!.areaClearedM2, equals(25000.0));

        final pending = queueRepo.getAll();
        expect(pending.length, equals(1));
        expect(pending.first.entityType, equals('land_clearing_records'));
        expect(pending.first.action, equals(SyncAction.update));
      },
    );

    test('getLandClearingRecords should filter by zoneId', () async {
      await repository.saveLandClearingRecord(tRecord);
      final otherRecord = tRecord.copyWith(
        id: 'lc-002',
        zoneId: 'zone-west',
        areaClearedM2: 10000.0,
      );
      await repository.saveLandClearingRecord(otherRecord);

      final eastRecords = await repository.getLandClearingRecords(
        zoneId: 'zone-east',
      );
      expect(eastRecords.length, equals(1));
      expect(eastRecords.first.areaClearedM2, equals(25000.0));

      final allRecords = await repository.getLandClearingRecords();
      expect(allRecords.length, equals(2));
    });

    test(
      'deleteLandClearingRecord should soft delete and enqueue delete mutation',
      () async {
        await repository.saveLandClearingRecord(tRecord);
        await repository.deleteLandClearingRecord('lc-001');

        final cached = localDataSource.getLandClearingRecordById('lc-001');
        expect(cached?.deletedAt, isNotNull);

        final active = await repository.getLandClearingRecords();
        expect(active.isEmpty, isTrue);
      },
    );
  });

  group('Inventory Repository Operations', () {
    const tItem = InventoryItem(
      id: 'inv-001',
      siteId: defaultSiteId,
      zoneId: 'warehouse-01',
      itemName: 'Diesel Fuel',
      category: 'Fuel & Lubricants',
      quantityOnHand: 150.0,
      unit: 'Liters',
      minThreshold: 200.0,
    );

    test(
      'saveInventoryItem should write to local cache and enqueue sync mutation',
      () async {
        await repository.saveInventoryItem(tItem);

        final cached = localDataSource.getInventoryItemById('inv-001');
        expect(cached, isNotNull);
        expect(cached!.itemName, equals('Diesel Fuel'));
        expect(cached.quantityOnHand, equals(150.0));

        final pending = queueRepo.getAll();
        expect(pending.length, equals(1));
        expect(pending.first.entityType, equals('inventory_items'));
      },
    );

    test('getInventoryItems should filter by category', () async {
      await repository.saveInventoryItem(tItem);
      final otherItem = tItem.copyWith(
        id: 'inv-002',
        itemName: 'Safety Helmet',
        category: 'Safety Equipment',
      );
      await repository.saveInventoryItem(otherItem);

      final fuelItems = await repository.getInventoryItems(
        category: 'Fuel & Lubricants',
      );
      expect(fuelItems.length, equals(1));
      expect(fuelItems.first.itemName, equals('Diesel Fuel'));

      final allItems = await repository.getInventoryItems();
      expect(allItems.length, equals(2));
    });

    test('updateInventoryQuantity should adjust stock correctly', () async {
      await repository.saveInventoryItem(tItem);

      await repository.updateInventoryQuantity('inv-001', 50.0);
      final updated = await repository.getInventoryItemById('inv-001');
      expect(updated!.quantityOnHand, equals(200.0));

      await repository.updateInventoryQuantity('inv-001', -30.0);
      final decreased = await repository.getInventoryItemById('inv-001');
      expect(decreased!.quantityOnHand, equals(170.0));
    });

    test('updateInventoryQuantity should not go below zero', () async {
      await repository.saveInventoryItem(tItem);

      await repository.updateInventoryQuantity('inv-001', -200.0);
      final updated = await repository.getInventoryItemById('inv-001');
      expect(updated!.quantityOnHand, equals(0.0));
    });

    test(
      'deleteInventoryItem should soft delete and enqueue delete mutation',
      () async {
        await repository.saveInventoryItem(tItem);
        await repository.deleteInventoryItem('inv-001');

        final cached = localDataSource.getInventoryItemById('inv-001');
        expect(cached?.deletedAt, isNotNull);

        final active = await repository.getInventoryItems();
        expect(active.isEmpty, isTrue);
      },
    );
  });

  group('Sync Queue Integration', () {
    test(
      'mutations are enqueued in correct order for CRUD operations',
      () async {
        mockNetworkInfo.isOnline = false;

        // Create
        await repository.saveCutFillRecord(
          CutFillRecord(
            id: 'cf-sync-1',
            siteId: defaultSiteId,
            zoneId: 'zone-test',
            measurementDate: DateTime(2026, 7, 18),
          ),
        );

        final record2 = CutFillRecord(
          id: 'cf-sync-2',
          siteId: defaultSiteId,
          zoneId: 'zone-test',
          measurementDate: DateTime(2026, 7, 18),
        );
        await repository.saveCutFillRecord(record2);
        await repository.deleteCutFillRecord('cf-sync-2');

        final queueItems = queueRepo.getAll();
        expect(queueItems.length, equals(3));

        // Delete mutation exists
        final deleteItem = queueItems.firstWhere(
          (item) => item.action == SyncAction.delete,
        );
        expect(deleteItem.payloadJson['id'], equals('cf-sync-2'));
      },
    );

    test(
      'SyncQueueManager processes tracking mutations via entity handlers',
      () async {
        mockNetworkInfo.isOnline = true;

        // Register the sync handlers for tracking
        syncQueueManager.registerEntityHandler('cut_fill_records', (
          item,
        ) async {
          final payload = item.payloadJson;
          await mockRemoteDataSource.createCutFillRecord(
            CutFillModel.fromJson(payload),
          );
        });

        await repository.saveCutFillRecord(
          CutFillRecord(
            id: 'cf-process-1',
            siteId: defaultSiteId,
            zoneId: 'zone-test',
            measurementDate: DateTime(2026, 7, 18),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verify the remote data source received the item
        expect(mockRemoteDataSource.cutFillDb.length, equals(1));
        expect(mockRemoteDataSource.cutFillDb.first.id, equals('cf-process-1'));

        // Verify queue item completed
        final completed = syncQueueManager.getCompletedItems();
        expect(completed.length, equals(1));
      },
    );
  });
}
