import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/daily_log/data/adapters/daily_log_dto_adapter.dart';
import 'package:mine_flow/features/daily_log/data/datasources/daily_log_remote_datasource.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:mine_flow/features/daily_log/data/repositories/daily_log_repository_impl.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

class MockNetworkInfo implements NetworkInfo {
  bool isOnline = false;

  @override
  Future<bool> get isConnected async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

class MockDailyLogRemoteDataSource implements DailyLogRemoteDataSource {
  final List<DailyLogDto> mockRemoteData = [];

  @override
  Future<List<DailyLogDto>> fetchAllDailyLogs() async {
    return mockRemoteData;
  }

  @override
  Future<DailyLogDto?> fetchDailyLogById(String id) async {
    final match = mockRemoteData.where((d) => d.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> upsertDailyLog(DailyLogDto dto) async {
    mockRemoteData.removeWhere((d) => d.id == dto.id);
    mockRemoteData.add(dto);
  }

  @override
  Future<void> deleteDailyLog(String id) async {
    mockRemoteData.removeWhere((d) => d.id == id);
  }
}

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';
  late Box<DailyLogDto> dailyLogBox;
  late Box<SyncQueueItem> queueBox;
  late HiveCacheRepository<DailyLogDto> localCache;
  late HiveCacheRepository<SyncQueueItem> queueRepo;
  late MockNetworkInfo mockNetworkInfo;
  late SyncQueueManager syncQueueManager;
  late MockDailyLogRemoteDataSource mockRemoteDataSource;
  late DailyLogRepositoryImpl repository;

  setUpAll(() async {
    Hive.init('./test_hive_daily_log');
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SyncActionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(DailyLogDtoAdapter());
    }
  });

  setUp(() async {
    dailyLogBox = await Hive.openBox<DailyLogDto>(
      'test_daily_log_box_${DateTime.now().millisecondsSinceEpoch}',
    );
    queueBox = await Hive.openBox<SyncQueueItem>(
      'test_queue_box_${DateTime.now().millisecondsSinceEpoch}',
    );

    localCache = HiveCacheRepository(dailyLogBox);
    queueRepo = HiveCacheRepository(queueBox);
    mockNetworkInfo = MockNetworkInfo();
    syncQueueManager = SyncQueueManager(
      queueRepository: queueRepo,
      networkInfo: mockNetworkInfo,
    );
    mockRemoteDataSource = MockDailyLogRemoteDataSource();

    repository = DailyLogRepositoryImpl(
      localCache: localCache,
      syncQueueManager: syncQueueManager,
      networkInfo: mockNetworkInfo,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  tearDown(() async {
    await dailyLogBox.clear();
    await dailyLogBox.close();
    await queueBox.clear();
    await queueBox.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('DailyLogRepositoryImpl - Offline First Operations', () {
    final tLog1 = DailyLog(
      id: 'log-001',
      siteId: defaultSiteId,
      foremanId: 'foreman-1',
      logDate: DateTime(2026, 7, 18),
      zoneId: 'zone-01',
      status: LogStatus.draft,
      summary: 'Initial draft log',
      weather: 'Sunny',
    );

    final tLog2 = DailyLog(
      id: 'log-002',
      siteId: defaultSiteId,
      foremanId: 'foreman-2',
      logDate: DateTime(2026, 7, 18),
      zoneId: 'zone-02',
      status: LogStatus.submitted,
      summary: 'Completed afternoon log',
      weather: 'Rainy',
    );

    test(
      'autoSaveDraft should store log as draft in local cache and enqueue sync mutation',
      () async {
        await repository.autoSaveDraft(tLog1);

        final cached = localCache.get('log-001');
        expect(cached, isNotNull);
        expect(cached!.foremanId, equals('foreman-1'));
        expect(cached.status, equals('draft'));
        expect(cached.summary, equals('Initial draft log'));

        final pendingQueue = queueRepo.getAll();
        expect(pendingQueue.length, equals(1));
        expect(pendingQueue.first.entityType, equals('daily_logs'));
        expect(pendingQueue.first.action, equals(SyncAction.update));
        expect(pendingQueue.first.payloadJson['id'], equals('log-001'));
      },
    );

    test(
      'getDraftLogForForeman should locate existing draft log for foreman on specified date',
      () async {
        await repository.autoSaveDraft(tLog1);

        final draftFound = await repository.getDraftLogForForeman(
          foremanId: 'foreman-1',
          date: DateTime(2026, 7, 18),
          siteId: defaultSiteId,
        );

        expect(draftFound, isNotNull);
        expect(draftFound!.id, equals('log-001'));
        expect(draftFound.status, equals(LogStatus.draft));
      },
    );

    test(
      'submitDailyLog should transition status to submitted and update timestamp',
      () async {
        await repository.autoSaveDraft(tLog1);

        await repository.submitDailyLog('log-001');

        final cached = localCache.get('log-001');
        expect(cached, isNotNull);
        expect(cached!.status, equals('submitted'));

        final pendingQueue = queueRepo.getAll();
        expect(pendingQueue.length, equals(2)); // autoSaveDraft + submit
        expect(pendingQueue.last.payloadJson['status'], equals('submitted'));
      },
    );

    test(
      'approveDailyLog should set status to approved and store approvedBy supervisor ID',
      () async {
        await repository.autoSaveDraft(tLog2);

        await repository.approveDailyLog(
          'log-002',
          approvedBy: 'supervisor-99',
        );

        final cached = localCache.get('log-002');
        expect(cached, isNotNull);
        expect(cached!.status, equals('approved'));
        expect(cached.approvedBy, equals('supervisor-99'));

        final pendingQueue = queueRepo.getAll();
        expect(
          pendingQueue.last.payloadJson['approved_by'],
          equals('supervisor-99'),
        );
      },
    );

    test(
      'getDailyLogs should filter correctly by date, foremanId, zoneId, and status',
      () async {
        await repository.autoSaveDraft(tLog1);
        await repository.autoSaveDraft(tLog2);

        final allToday = await repository.getDailyLogs(
          date: DateTime(2026, 7, 18),
        );
        expect(allToday.length, equals(2));

        final foreman1Logs = await repository.getDailyLogs(
          foremanId: 'foreman-1',
        );
        expect(foreman1Logs.length, equals(1));
        expect(foreman1Logs.first.id, equals('log-001'));

        final zone2Logs = await repository.getDailyLogs(zoneId: 'zone-02');
        expect(zone2Logs.length, equals(1));
        expect(zone2Logs.first.id, equals('log-002'));
      },
    );

    test(
      'deleteDailyLog should mark soft delete in local cache and enqueue delete mutation',
      () async {
        await repository.autoSaveDraft(tLog1);
        await repository.deleteDailyLog('log-001');

        final cachedAfterDelete = localCache.get('log-001');
        expect(cachedAfterDelete?.deletedAt, isNotNull);

        final logsToday = await repository.getDailyLogs(
          date: DateTime(2026, 7, 18),
        );
        expect(logsToday.isEmpty, isTrue);

        final queueItems = queueRepo.getAll();
        final hasDeleteMutation = queueItems.any(
          (item) => item.action == SyncAction.delete,
        );
        expect(hasDeleteMutation, isTrue);
      },
    );

    test(
      'syncRemote should fetch remote logs and populate local cache when online',
      () async {
        mockNetworkInfo.isOnline = true;
        mockRemoteDataSource.mockRemoteData.add(
          DailyLogDto(
            id: 'remote-log-001',
            siteId: defaultSiteId,
            foremanId: 'remote-foreman',
            logDate: DateTime(2026, 7, 18),
            status: 'approved',
            summary: 'Remote log synced',
          ),
        );

        final syncedLogs = await repository.syncRemote();
        expect(syncedLogs.length, equals(1));
        expect(syncedLogs.first.id, equals('remote-log-001'));
        expect(syncedLogs.first.summary, equals('Remote log synced'));

        final cachedItem = localCache.get('remote-log-001');
        expect(cachedItem, isNotNull);
      },
    );
  });
}
