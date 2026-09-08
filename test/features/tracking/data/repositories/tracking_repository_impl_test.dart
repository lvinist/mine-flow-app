import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
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
import 'package:mine_flow/features/tracking/data/sync/tracking_sync_registrar.dart';
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
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
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
      bcmVolume: 1500.0,
      lcmVolume: 500.0,
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
        expect(cached!.bcmVolume, equals(1500.0));

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
        bcmVolume: 2000.0,
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
      expect(result!.bcmVolume, equals(1500.0));
      expect(result.lcmVolume, equals(500.0));
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
      planArea: 15000.0,
      actualArea: 25000.0,
      method: 'Bulldozer',
      clearingDate: DateTime(2026, 7, 18),
      clearedBy: 'crew-01',
    );

    test(
      'saveLandClearingRecord should write to local cache and enqueue sync mutation',
      () async {
        await repository.saveLandClearingRecord(tRecord);

        final cached = localDataSource.getLandClearingRecordById('lc-001');
        expect(cached, isNotNull);
        expect(cached!.actualArea, equals(25000.0));

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
        planArea: 5000.0,
        actualArea: 10000.0,
      );
      await repository.saveLandClearingRecord(otherRecord);

      final eastRecords = await repository.getLandClearingRecords(
        zoneId: 'zone-east',
      );
      expect(eastRecords.length, equals(1));
      expect(eastRecords.first.actualArea, equals(25000.0));

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

    test(
      'getCutFillRecords orders newest-first so a just-saved record is not below the fold (STEP-48.21 R-1)',
      () async {
        // CI failure mechanism: Hive values are insertion-ordered; when the
        // background staging backfill lands BEFORE the save (fast CI
        // network), the just-saved row is appended LAST. The list screen
        // renders through a lazy SliverList.builder, so a last-position row
        // is below the fold and its widget is never built — find.text
        // containing sees nothing. The read contract must surface the
        // newest row first.
        const zoneId = 'zone-order-test';
        final backfill = CutFillRecord(
          id: 'cf-backfill-old',
          siteId: defaultSiteId,
          zoneId: zoneId,
          measurementDate: DateTime(2026, 7, 17),
        );
        final justSaved = CutFillRecord(
          id: 'cf-just-saved',
          siteId: defaultSiteId,
          zoneId: zoneId,
          measurementDate: DateTime(2026, 7, 18, 16, 45),
        );
        // Insertion order deliberately: old row first, new row last.
        await repository.saveCutFillRecord(backfill);
        await repository.saveCutFillRecord(justSaved);

        final records = await repository.getCutFillRecords(zoneId: zoneId);
        expect(records.length, equals(2));
        expect(records.first.id, equals('cf-just-saved'));
        expect(records.last.id, equals('cf-backfill-old'));
      },
    );

    test(
      'syncRemote does not clobber a newer local inventory quantity with a stale remote snapshot (STEP-48.21 R-4 Android leg)',
      () async {
        // 48.26 gate CI mechanism (inventory_journey_test.dart:193,
        // Expected <120.0> / Actual <150.0>): getInventoryItems fires an
        // unawaited background refresh. A fetch snapshot that STARTED before
        // the stock adjustment's upsert completed carries the pre-adjustment
        // quantity (150); when its putAll lands AFTER the local 120-write,
        // an unconditional putAll clobbers the fresher local row. The refresh
        // merge must be last-write-wins on updatedAt (the same class
        // AttendanceRepositoryImpl / DailyLogRepositoryImpl already merge).
        mockNetworkInfo.isOnline = true;
        final justSaved = InventoryItem(
          id: 'inv-r4-clobber',
          siteId: defaultSiteId,
          itemName: 'Solar Industri B30',
          quantityOnHand: 150.0,
          updatedAt: DateTime(2026, 9, 3, 9, 0, 0),
        );
        await repository.saveInventoryItem(justSaved);

        // The stale snapshot: fetched before the adjustment, lands after it.
        // (DB trigger overwrote updated_at with server NOW() pre-20260901000001,
        // so remote updated_at can genuinely predate the local write.)
        mockRemoteDataSource.inventoryDb.add(
          InventoryItemModel(
            id: 'inv-r4-clobber',
            siteId: defaultSiteId,
            itemName: 'Solar Industri B30',
            quantityOnHand: 150.0,
            updatedAt: DateTime(2026, 9, 3, 8, 59, 0),
          ),
        );

        await repository.updateInventoryQuantity('inv-r4-clobber', -30.0);
        await repository.syncRemote();

        final after = await repository.getInventoryItemById('inv-r4-clobber');
        expect(after!.quantityOnHand, equals(120.0));
      },
    );

    test(
      'syncRemote still applies a genuinely newer remote inventory row (STEP-48.21 R-4 merge sanity)',
      () async {
        // Guard against overcorrecting: a server-side correction that is
        // equal-or-newer must still converge into the cache (mirrors the
        // daily-log merge semantics).
        mockNetworkInfo.isOnline = true;
        await repository.saveInventoryItem(
          InventoryItem(
            id: 'inv-r4-newer',
            siteId: defaultSiteId,
            itemName: 'Remote Correction',
            quantityOnHand: 100.0,
            updatedAt: DateTime(2026, 9, 3, 9, 0, 0),
          ),
        );
        mockRemoteDataSource.inventoryDb.add(
          InventoryItemModel(
            id: 'inv-r4-newer',
            siteId: defaultSiteId,
            itemName: 'Remote Correction',
            quantityOnHand: 80.0,
            updatedAt: DateTime(2026, 9, 3, 9, 5, 0),
          ),
        );

        await repository.syncRemote();

        final after = await repository.getInventoryItemById('inv-r4-newer');
        expect(after!.quantityOnHand, equals(80.0));
      },
    );

    test(
      'tracking registrar UTC re-anchors updated_at so the drain does not stamp a phantom-future row (STEP-48.21 R-4 / 48.20 class sweep)',
      () async {
        // 48.26 R-4 Android leg co-defect: TrackingSyncRegistrar drained
        // model.toJson(), whose updated_at is an offset-less LOCAL-time ISO
        // string. A timestamptz column reads that as UTC — +7h on a +07
        // device — so the drained row beat every later write in every
        // last-write-wins comparison for 7 hours. The core
        // _defaultSupabaseSync was UTC re-anchored in the 48.20 re-run; the
        // feature registrars were the unswept sibling sites.
        mockNetworkInfo.isOnline = true;
        TrackingSyncRegistrar.registerSyncHandlers(
          syncQueueManager,
          mockRemoteDataSource,
        );
        addTearDown(
          () => TrackingSyncRegistrar.unregisterSyncHandlers(syncQueueManager),
        );

        final localWallTime = DateTime(2026, 9, 3, 16, 0, 0); // +07 wall time
        await repository.saveInventoryItem(
          InventoryItem(
            id: 'inv-r4-utc',
            siteId: defaultSiteId,
            itemName: 'UTC Anchor Probe',
            quantityOnHand: 42.0,
            updatedAt: localWallTime,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final drained = mockRemoteDataSource.inventoryDb.single;
        final stamped = DateTime.parse(
          drained.toJson()['updated_at'] as String,
        );
        expect(
          stamped.isUtc,
          isTrue,
          reason:
              'drained updated_at must carry a UTC designator, not an offset-less local string',
        );
        expect(stamped, equals(localWallTime.toUtc()));
      },
    );
  });
}
