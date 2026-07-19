import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/data_bucket/data/datasources/data_bucket_local_datasource.dart';
import 'package:mine_flow/features/data_bucket/data/datasources/data_bucket_remote_datasource.dart';
import 'package:mine_flow/features/data_bucket/data/models/geospatial_file_model.dart';
import 'package:mine_flow/features/data_bucket/data/repositories/data_bucket_repository_impl.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';

class MockNetworkInfo implements NetworkInfo {
  bool isOnline = false;

  @override
  Future<bool> get isConnected async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

class MockDataBucketRemoteDataSource implements DataBucketRemoteDataSource {
  final List<GeospatialFileModel> db = [];

  @override
  Future<List<GeospatialFileModel>> fetchFiles() async => List.from(db);

  @override
  Future<GeospatialFileModel> saveFile(GeospatialFileModel file) async {
    db.removeWhere((r) => r.id == file.id);
    db.add(file);
    return file;
  }

  @override
  Future<void> deleteFile(String id) async {
    db.removeWhere((r) => r.id == id);
  }

  @override
  Stream<List<GeospatialFileModel>> watchFiles() {
    return Stream.value(List.from(db));
  }
}

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';
  final fixedDate = DateTime(2026, 7, 18, 8, 0, 0);

  late Directory tempDir;
  late Box<Map<String, dynamic>> localBox;
  late Box<SyncQueueItem> queueBox;
  late HiveCacheRepository<SyncQueueItem> queueRepo;
  late MockNetworkInfo mockNetworkInfo;
  late SyncQueueManager syncQueueManager;
  late MockDataBucketRemoteDataSource mockRemoteDataSource;
  late DataBucketLocalDataSource localDataSource;
  late DataBucketRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('data_bucket_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SyncActionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }

    localBox = await Hive.openBox<Map<String, dynamic>>(
      'test_db_${DateTime.now().millisecondsSinceEpoch}',
    );
    queueBox = await Hive.openBox<SyncQueueItem>(
      'test_q_${DateTime.now().millisecondsSinceEpoch}',
    );

    queueRepo = HiveCacheRepository(queueBox);

    mockNetworkInfo = MockNetworkInfo();
    syncQueueManager = SyncQueueManager(
      queueRepository: queueRepo,
      networkInfo: mockNetworkInfo,
    );
    mockRemoteDataSource = MockDataBucketRemoteDataSource();

    localDataSource = DataBucketLocalDataSourceImpl(hiveBox: localBox);

    repository = DataBucketRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: mockRemoteDataSource,
      syncQueueManager: syncQueueManager,
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() async {
    await localBox.clear();
    await localBox.close();
    await queueBox.clear();
    await queueBox.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DataBucket Repository - Save Operations', () {
    final tFile = GeospatialFile(
      id: 'gf-001',
      siteId: defaultSiteId,
      zoneId: 'zone-north',
      fileName: 'survey_area_42.shp',
      fileType: '.shp',
      mimeType: 'application/octet-stream',
      driveFileId: 'drive-file-abc123',
      driveLink: 'https://drive.google.com/file/d/abc123/view',
      fileSizeBytes: 1048576,
      latitude: -7.2504447,
      longitude: 112.768845,
      acquisitionDate: DateTime(2026, 7, 15),
      notes: 'Northern zone boundary survey',
      uploadedBy: 'user-001',
      createdAt: fixedDate,
      updatedAt: fixedDate,
    );

    test(
      'saveFile should write to local cache and enqueue sync mutation when offline',
      () async {
        mockNetworkInfo.isOnline = false;

        await repository.saveFile(tFile);

        // Verify local cache
        final cached = localDataSource.getFile('gf-001');
        expect(cached, isNotNull);
        expect(cached!.fileName, equals('survey_area_42.shp'));
        expect(cached.fileType, equals('.shp'));

        // Verify sync queue
        final pending = queueRepo.getAll();
        expect(pending.length, equals(1));
        expect(pending.first.entityType, equals('data_bucket_metadata_sync'));
        expect(pending.first.action, equals(SyncAction.update));
        expect(pending.first.payloadJson['id'], equals('gf-001'));
      },
    );

    test(
      'saveFile should write to remote and not enqueue sync when online',
      () async {
        mockNetworkInfo.isOnline = true;

        final saved = await repository.saveFile(tFile);

        // Verify local cache
        final cached = localDataSource.getFile('gf-001');
        expect(cached, isNotNull);

        // Verify remote data source received the file
        expect(mockRemoteDataSource.db.length, equals(1));
        expect(mockRemoteDataSource.db.first.id, equals('gf-001'));

        // Verify no pending sync items (remote succeeded)
        final pending = queueRepo.getAll();
        expect(pending.length, equals(0));

        // Verify returned file matches
        expect(saved.id, equals('gf-001'));
        expect(saved.fileName, equals('survey_area_42.shp'));
      },
    );

    test(
      'saveFile should fall back to local cache + enqueue when remote fails while online',
      () async {
        mockNetworkInfo.isOnline = true;
        // Make remote fail by using a mock that throws
        final failingRemote = MockFailingRemoteDataSource();
        repository = DataBucketRepositoryImpl(
          localDataSource: localDataSource,
          remoteDataSource: failingRemote,
          syncQueueManager: syncQueueManager,
          networkInfo: mockNetworkInfo,
        );

        await repository.saveFile(tFile);

        // Verify local cache still updated
        final cached = localDataSource.getFile('gf-001');
        expect(cached, isNotNull);

        // Verify sync queue has the mutation for later retry
        final pending = queueRepo.getAll();
        expect(pending.length, equals(1));
        expect(pending.first.entityType, equals('data_bucket_metadata_sync'));
        expect(pending.first.action, equals(SyncAction.update));
      },
    );

    test('getFile should return file from local cache', () async {
      mockNetworkInfo.isOnline = false;
      await repository.saveFile(tFile);

      final result = await repository.getFile('gf-001');
      expect(result, isNotNull);
      expect(result!.id, equals('gf-001'));
      expect(result.fileName, equals('survey_area_42.shp'));
      expect(result.fileType, equals('.shp'));
    });

    test('getFile should return null for non-existent file', () async {
      final result = await repository.getFile('non-existent');
      expect(result, isNull);
    });
  });

  group('DataBucket Repository - Read Operations', () {
    final tFile1 = GeospatialFile(
      id: 'gf-001',
      siteId: defaultSiteId,
      zoneId: 'zone-north',
      fileName: 'survey_north.shp',
      fileType: '.shp',
      driveFileId: 'drive-001',
      driveLink: 'https://drive.google.com/file/d/001/view',
      createdAt: fixedDate,
      updatedAt: fixedDate,
    );
    final tFile2 = GeospatialFile(
      id: 'gf-002',
      siteId: defaultSiteId,
      zoneId: 'zone-south',
      fileName: 'survey_south.tiff',
      fileType: '.tiff',
      driveFileId: 'drive-002',
      driveLink: 'https://drive.google.com/file/d/002/view',
      createdAt: fixedDate,
      updatedAt: fixedDate,
    );

    setUp(() async {
      mockNetworkInfo.isOnline = false;
      await repository.saveFile(tFile1);
      await repository.saveFile(tFile2);
    });

    test('getFiles should return all files', () async {
      final files = await repository.getFiles();
      expect(files.length, equals(2));
    });

    test('getFiles should filter by zoneId', () async {
      final northFiles = await repository.getFiles(zoneId: 'zone-north');
      expect(northFiles.length, equals(1));
      expect(northFiles.first.id, equals('gf-001'));

      final southFiles = await repository.getFiles(zoneId: 'zone-south');
      expect(southFiles.length, equals(1));
      expect(southFiles.first.id, equals('gf-002'));
    });

    test('getFiles should filter by fileType', () async {
      final shpFiles = await repository.getFiles(fileType: '.shp');
      expect(shpFiles.length, equals(1));
      expect(shpFiles.first.id, equals('gf-001'));

      final tiffFiles = await repository.getFiles(fileType: '.tiff');
      expect(tiffFiles.length, equals(1));
      expect(tiffFiles.first.id, equals('gf-002'));
    });

    test('getFiles should filter by searchQuery', () async {
      final northResults = await repository.getFiles(searchQuery: 'north');
      expect(northResults.length, equals(1));
      expect(northResults.first.id, equals('gf-001'));

      final southResults = await repository.getFiles(searchQuery: 'south');
      expect(southResults.length, equals(1));
      expect(southResults.first.id, equals('gf-002'));
    });

    test('getFiles should filter by multiple criteria', () async {
      final results = await repository.getFiles(
        zoneId: 'zone-north',
        fileType: '.shp',
      );
      expect(results.length, equals(1));
      expect(results.first.id, equals('gf-001'));
    });

    test('getFiles should return empty list when no match', () async {
      final results = await repository.getFiles(fileType: '.dxf');
      expect(results.length, equals(0));
    });
  });

  group('DataBucket Repository - Delete Operations', () {
    final tFile = GeospatialFile(
      id: 'gf-del-001',
      siteId: defaultSiteId,
      zoneId: 'zone-north',
      fileName: 'to_delete.shp',
      fileType: '.shp',
      driveFileId: 'drive-del-001',
      driveLink: 'https://drive.google.com/file/d/del-001/view',
      createdAt: fixedDate,
      updatedAt: fixedDate,
    );

    test(
      'deleteFile should remove from local cache and enqueue delete mutation when offline',
      () async {
        mockNetworkInfo.isOnline = false;
        await repository.saveFile(tFile);

        // Verify it's in cache
        expect(localDataSource.getFile('gf-del-001'), isNotNull);

        // Delete
        await repository.deleteFile('gf-del-001');

        // Should be removed from local cache
        expect(localDataSource.getFile('gf-del-001'), isNull);

        // Should enqueue a delete mutation
        final queueItems = queueRepo.getAll();
        final deleteItems = queueItems
            .where((item) => item.action == SyncAction.delete)
            .toList();
        expect(deleteItems.length, equals(1));
        expect(
          deleteItems.first.entityType,
          equals('data_bucket_metadata_sync'),
        );
      },
    );

    test(
      'deleteFile should remove from local cache and remote when online',
      () async {
        mockNetworkInfo.isOnline = true;
        await repository.saveFile(tFile);

        // Verify remote has it
        expect(mockRemoteDataSource.db.length, equals(1));

        // Delete
        await repository.deleteFile('gf-del-001');

        // Should be removed from local cache
        expect(localDataSource.getFile('gf-del-001'), isNull);

        // Should be removed from remote
        expect(mockRemoteDataSource.db.length, equals(0));
      },
    );

    test('deleteFile on non-existent ID should still enqueue delete', () async {
      mockNetworkInfo.isOnline = false;
      await repository.deleteFile('non-existent-id');

      final queueItems = queueRepo.getAll();
      expect(queueItems.length, equals(1));
      expect(queueItems.first.action, equals(SyncAction.delete));
    });
  });

  group('DataBucket Repository - Sync Operations', () {
    test(
      'syncPendingUploads should fetch from remote and update local cache',
      () async {
        mockNetworkInfo.isOnline = true;

        // Pre-populate remote
        mockRemoteDataSource.db.add(
          GeospatialFileModel(
            id: 'remote-gf-001',
            siteId: defaultSiteId,
            fileName: 'remote_survey.shp',
            fileType: '.shp',
            driveFileId: 'drive-remote',
            driveLink: 'https://drive.google.com/file/d/remote/view',
            createdAt: fixedDate,
            updatedAt: fixedDate,
          ),
        );

        await repository.syncPendingUploads();

        // Should now be in local cache
        final cached = localDataSource.getFile('remote-gf-001');
        expect(cached, isNotNull);
        expect(cached!.fileName, equals('remote_survey.shp'));
      },
    );
  });

  group('DataBucket Repository - Offline Fallback', () {
    test('local cache serves read results when offline', () async {
      mockNetworkInfo.isOnline = false;

      // Save while offline
      await repository.saveFile(
        GeospatialFile(
          id: 'offline-gf-001',
          siteId: defaultSiteId,
          fileName: 'offline_file.shp',
          fileType: '.shp',
          driveFileId: 'drive-offline',
          driveLink: 'https://drive.google.com/file/d/offline/view',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      // Read back while still offline
      final result = await repository.getFile('offline-gf-001');
      expect(result, isNotNull);
      expect(result!.fileName, equals('offline_file.shp'));

      // Verify sync queue has the pending item
      final pending = queueRepo.getAll();
      expect(pending.length, equals(1));
      expect(pending.first.syncStatus, equals(SyncStatus.pending));
    });

    test('multiple offline saves are all enqueued correctly', () async {
      mockNetworkInfo.isOnline = false;

      await repository.saveFile(
        GeospatialFile(
          id: 'offline-1',
          siteId: defaultSiteId,
          fileName: 'file1.shp',
          fileType: '.shp',
          driveFileId: 'drive-1',
          driveLink: 'https://drive.google.com/file/d/1/view',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );
      await repository.saveFile(
        GeospatialFile(
          id: 'offline-2',
          siteId: defaultSiteId,
          fileName: 'file2.tiff',
          fileType: '.tiff',
          driveFileId: 'drive-2',
          driveLink: 'https://drive.google.com/file/d/2/view',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );
      await repository.saveFile(
        GeospatialFile(
          id: 'offline-3',
          siteId: defaultSiteId,
          fileName: 'file3.csv',
          fileType: '.csv',
          driveFileId: 'drive-3',
          driveLink: 'https://drive.google.com/file/d/3/view',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      // All three should be in local cache
      final allFiles = await repository.getFiles();
      expect(allFiles.length, equals(3));

      // All three should be in sync queue
      final pending = queueRepo.getAll();
      expect(pending.length, equals(3));
      expect(pending.every((item) => item.action == SyncAction.update), isTrue);
    });
  });
}

/// A remote data source that always throws, simulating network failure.
class MockFailingRemoteDataSource implements DataBucketRemoteDataSource {
  @override
  Future<List<GeospatialFileModel>> fetchFiles() async {
    throw Exception('Simulated remote failure');
  }

  @override
  Future<GeospatialFileModel> saveFile(GeospatialFileModel file) async {
    throw Exception('Simulated remote failure');
  }

  @override
  Future<void> deleteFile(String id) async {
    throw Exception('Simulated remote failure');
  }

  @override
  Stream<List<GeospatialFileModel>> watchFiles() {
    throw Exception('Simulated remote failure');
  }
}
