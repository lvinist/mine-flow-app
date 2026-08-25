import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/attendance/data/adapters/attendance_record_dto_adapter.dart';
import 'package:mine_flow/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';
import 'package:mine_flow/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

class MockNetworkInfo implements NetworkInfo {
  bool isOnline = false;

  @override
  Future<bool> get isConnected async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

class MockAttendanceRemoteDataSource implements AttendanceRemoteDataSource {
  final List<AttendanceRecordDto> mockRemoteData = [];

  @override
  Future<List<AttendanceRecordDto>> fetchAllAttendance() async {
    return mockRemoteData;
  }

  @override
  Future<AttendanceRecordDto?> fetchAttendanceById(String id) async {
    final match = mockRemoteData.where((d) => d.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> upsertAttendance(AttendanceRecordDto dto) async {
    mockRemoteData.removeWhere((d) => d.id == dto.id);
    mockRemoteData.add(dto);
  }

  @override
  Future<void> deleteAttendance(String id) async {
    mockRemoteData.removeWhere((d) => d.id == id);
  }
}

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';
  late Box<AttendanceRecordDto> attendanceBox;
  late Box<SyncQueueItem> queueBox;
  late HiveCacheRepository<AttendanceRecordDto> localCache;
  late HiveCacheRepository<SyncQueueItem> queueRepo;
  late MockNetworkInfo mockNetworkInfo;
  late SyncQueueManager syncQueueManager;
  late MockAttendanceRemoteDataSource mockRemoteDataSource;
  late AttendanceRepositoryImpl repository;

  setUpAll(() async {
    Hive.init('./test_hive_attendance');
    if (!Hive.isAdapterRegistered(10))
      Hive.registerAdapter(SyncQueueItemAdapter());
    if (!Hive.isAdapterRegistered(11))
      Hive.registerAdapter(SyncActionAdapter());
    if (!Hive.isAdapterRegistered(12))
      Hive.registerAdapter(SyncStatusAdapter());
    if (!Hive.isAdapterRegistered(21))
      Hive.registerAdapter(AttendanceRecordDtoAdapter());
  });

  setUp(() async {
    attendanceBox = await Hive.openBox<AttendanceRecordDto>(
      'test_attendance_box_${DateTime.now().millisecondsSinceEpoch}',
    );
    queueBox = await Hive.openBox<SyncQueueItem>(
      'test_queue_box_${DateTime.now().millisecondsSinceEpoch}',
    );

    localCache = HiveCacheRepository(attendanceBox);
    queueRepo = HiveCacheRepository(queueBox);
    mockNetworkInfo = MockNetworkInfo();
    syncQueueManager = SyncQueueManager(
      queueRepository: queueRepo,
      networkInfo: mockNetworkInfo,
    );
    mockRemoteDataSource = MockAttendanceRemoteDataSource();

    repository = AttendanceRepositoryImpl(
      localCache: localCache,
      syncQueueManager: syncQueueManager,
      networkInfo: mockNetworkInfo,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  tearDown(() async {
    await attendanceBox.clear();
    await attendanceBox.close();
    await queueBox.clear();
    await queueBox.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('AttendanceRepositoryImpl - Offline First Operations', () {
    final tRecord1 = AttendanceRecord(
      id: 'att-001',
      siteId: defaultSiteId,
      userId: 'user-001',
      date: DateTime(2026, 7, 18),
      status: AttendanceStatus.present,
      remarks: 'Shift A',
      loggedBy: 'foreman-1',
    );

    final tRecord2 = AttendanceRecord(
      id: 'att-002',
      siteId: defaultSiteId,
      userId: 'user-002',
      date: DateTime(2026, 7, 18),
      status: AttendanceStatus.absent,
      remarks: 'No show',
      loggedBy: 'foreman-1',
    );

    test(
      'saveAttendance should write to local cache and enqueue sync mutation item',
      () async {
        await repository.saveAttendance(tRecord1);

        // Verify cached in Hive
        final cached = localCache.get('att-001');
        expect(cached, isNotNull);
        expect(cached!.userId, equals('user-001'));
        expect(cached.status, equals('present'));

        // Verify enqueued in SyncQueueManager
        final pendingQueue = queueRepo.getAll();
        expect(pendingQueue.length, equals(1));
        expect(pendingQueue.first.entityType, equals('attendance_records'));
        expect(pendingQueue.first.action, equals(SyncAction.update));
        expect(pendingQueue.first.payloadJson['id'], equals('att-001'));
      },
    );

    test(
      'saveAttendanceBatch should save multiple attendance records to local cache',
      () async {
        await repository.saveAttendanceBatch([tRecord1, tRecord2]);

        final allCached = localCache.getAll();
        expect(allCached.length, equals(2));

        final pendingQueue = queueRepo.getAll();
        expect(pendingQueue.length, equals(2));
      },
    );

    test(
      'getAttendanceForDate should filter local cache by date and siteId',
      () async {
        await repository.saveAttendanceBatch([tRecord1, tRecord2]);

        final resultsToday = await repository.getAttendanceForDate(
          DateTime(2026, 7, 18),
          siteId: defaultSiteId,
        );
        expect(resultsToday.length, equals(2));

        final resultsYesterday = await repository.getAttendanceForDate(
          DateTime(2026, 7, 17),
          siteId: defaultSiteId,
        );
        expect(resultsYesterday.isEmpty, isTrue);
      },
    );

    test('getAttendanceForUser should filter records by userId', () async {
      await repository.saveAttendanceBatch([tRecord1, tRecord2]);

      final user1Records = await repository.getAttendanceForUser('user-001');
      expect(user1Records.length, equals(1));
      expect(user1Records.first.id, equals('att-001'));
    });

    test(
      'deleteAttendance should mark soft delete in local cache and enqueue delete mutation',
      () async {
        await repository.saveAttendance(tRecord1);
        await repository.deleteAttendance('att-001');

        final cachedAfterDelete = localCache.get('att-001');
        expect(cachedAfterDelete?.deletedAt, isNotNull);

        final recordsForDate = await repository.getAttendanceForDate(
          DateTime(2026, 7, 18),
        );
        expect(recordsForDate.isEmpty, isTrue);

        final queueItems = queueRepo.getAll();
        final hasDeleteMutation = queueItems.any(
          (item) => item.action == SyncAction.delete,
        );
        expect(hasDeleteMutation, isTrue);
      },
    );

    test(
      'syncRemote should fetch remote records and update local cache when online',
      () async {
        mockNetworkInfo.isOnline = true;
        mockRemoteDataSource.mockRemoteData.add(
          AttendanceRecordDto(
            id: 'remote-att-001',
            siteId: defaultSiteId,
            userId: 'user-009',
            date: DateTime(2026, 7, 18),
            status: 'leave',
          ),
        );

        final syncedRecords = await repository.syncRemote();
        expect(syncedRecords.length, equals(1));
        expect(syncedRecords.first.id, equals('remote-att-001'));
        expect(syncedRecords.first.status, equals(AttendanceStatus.leave));

        final cachedItem = localCache.get('remote-att-001');
        expect(cachedItem, isNotNull);
      },
    );
  });
}
