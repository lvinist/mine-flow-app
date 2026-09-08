import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/attendance/data/adapters/attendance_record_dto_adapter.dart';
import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';
import 'package:mine_flow/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/daily_log/data/adapters/daily_log_dto_adapter.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:mine_flow/features/daily_log/data/repositories/daily_log_repository_impl.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Fake implementation of [NetworkInfo] for testing offline/online transitions.
class FakeNetworkInfo implements NetworkInfo {
  bool _isConnected = false;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  void setConnected(bool value) {
    _isConnected = value;
    _controller.add(value);
  }

  @override
  Future<bool> get isConnected async => _isConnected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

void main() {
  late Directory tempDir;
  late FakeNetworkInfo fakeNetworkInfo;
  late Box<AttendanceRecordDto> attendanceBox;
  late Box<DailyLogDto> dailyLogBox;
  late Box<SyncQueueItem> queueBox;
  late HiveCacheRepository<AttendanceRecordDto> attendanceCache;
  late HiveCacheRepository<DailyLogDto> dailyLogCache;
  late HiveCacheRepository<SyncQueueItem> queueRepo;
  late SyncQueueManager syncQueueManager;
  late AttendanceRepositoryImpl attendanceRepository;
  late DailyLogRepositoryImpl dailyLogRepository;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SyncActionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(AttendanceRecordDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(DailyLogDtoAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'attendance_daily_log_sync_test_',
    );
    Hive.init(tempDir.path);

    attendanceBox = await Hive.openBox<AttendanceRecordDto>(
      'test_attendance_box',
    );
    dailyLogBox = await Hive.openBox<DailyLogDto>('test_daily_log_box');
    queueBox = await Hive.openBox<SyncQueueItem>('test_sync_queue_box');

    attendanceCache = HiveCacheRepository(attendanceBox);
    dailyLogCache = HiveCacheRepository(dailyLogBox);
    queueRepo = HiveCacheRepository(queueBox);

    fakeNetworkInfo = FakeNetworkInfo();
  });

  tearDown(() async {
    await syncQueueManager.dispose();
    fakeNetworkInfo.dispose();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Attendance & Daily Log Offline Sync Integration Tests', () {
    test(
      'Attendance offline creation enqueues mutation and flushes when online',
      () async {
        fakeNetworkInfo.setConnected(false);

        final syncedAttendancePayloads = <Map<String, dynamic>>[];

        syncQueueManager = SyncQueueManager(
          queueRepository: queueRepo,
          networkInfo: fakeNetworkInfo,
        );

        // Register entity handler for attendance_records
        syncQueueManager.registerEntityHandler('attendance_records', (
          item,
        ) async {
          syncedAttendancePayloads.add(item.payloadJson);
        });

        attendanceRepository = AttendanceRepositoryImpl(
          localCache: attendanceCache,
          syncQueueManager: syncQueueManager,
          networkInfo: fakeNetworkInfo,
        );

        final record = AttendanceRecord(
          id: 'att-sync-101',
          siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          userId: 'user-miner-01',
          date: DateTime.parse('2026-07-18'),
          status: AttendanceStatus.present,
          remarks: 'On time for morning shift',
          loggedBy: 'foreman-jack',
          createdAt: DateTime.parse('2026-07-18T07:00:00.000Z'),
          updatedAt: DateTime.parse('2026-07-18T07:00:00.000Z'),
        );

        // Save while offline
        await attendanceRepository.saveAttendance(record);

        // 1. Verify cached in local Hive storage
        final localRecord = await attendanceRepository.getAttendanceById(
          'att-sync-101',
        );
        expect(localRecord, isNotNull);
        expect(localRecord!.userId, equals('user-miner-01'));
        expect(localRecord.status, equals(AttendanceStatus.present));

        // 2. Verify enqueued in SyncQueueManager as pending
        final pendingItems = syncQueueManager.getPendingItems();
        expect(pendingItems.length, equals(1));
        expect(pendingItems.first.entityType, equals('attendance_records'));
        expect(syncedAttendancePayloads, isEmpty);

        // 3. Transition network status to online
        fakeNetworkInfo.setConnected(true);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // 4. Verify registered entity handler processed payload
        expect(syncedAttendancePayloads.length, equals(1));
        expect(syncedAttendancePayloads.first['id'], equals('att-sync-101'));
        expect(
          syncedAttendancePayloads.first['user_id'],
          equals('user-miner-01'),
        );

        // 5. Verify queue status marked as completed
        expect(syncQueueManager.getPendingItems(), isEmpty);
        expect(syncQueueManager.getCompletedItems().length, equals(1));
      },
    );

    test(
      'Daily Log draft auto-save and submission offline queueing and sync',
      () async {
        fakeNetworkInfo.setConnected(false);

        final syncedDailyLogActions = <SyncAction>[];

        syncQueueManager = SyncQueueManager(
          queueRepository: queueRepo,
          networkInfo: fakeNetworkInfo,
        );

        // Register entity handler for daily_logs
        syncQueueManager.registerEntityHandler('daily_logs', (item) async {
          syncedDailyLogActions.add(item.action);
        });

        dailyLogRepository = DailyLogRepositoryImpl(
          localCache: dailyLogCache,
          syncQueueManager: syncQueueManager,
          networkInfo: fakeNetworkInfo,
        );

        final draftLog = DailyLog(
          id: 'log-sync-202',
          siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          foremanId: 'foreman-jack',
          logDate: DateTime.parse('2026-07-18'),
          zoneId: 'zone-north-pit',
          status: LogStatus.draft,
          summary: 'Cleared North Pit 200m2',
          weather: 'Sunny',
          createdAt: DateTime.parse('2026-07-18T08:00:00.000Z'),
          updatedAt: DateTime.parse('2026-07-18T08:00:00.000Z'),
        );

        // Auto save draft offline
        await dailyLogRepository.autoSaveDraft(draftLog);

        // Submit daily log offline
        await dailyLogRepository.submitDailyLog('log-sync-202');

        // Verify 2 sync mutations enqueued offline
        expect(syncQueueManager.getPendingItems().length, equals(2));

        // Connect online to trigger replay
        fakeNetworkInfo.setConnected(true);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verify all items synced in sequence
        expect(syncedDailyLogActions.length, equals(2));
        expect(syncQueueManager.getPendingItems(), isEmpty);
        expect(syncQueueManager.getCompletedItems().length, equals(2));

        // Verify updated status in Hive cache is submitted
        final submittedLog = await dailyLogRepository.getDailyLogById(
          'log-sync-202',
        );
        expect(submittedLog, isNotNull);
        expect(submittedLog!.status, equals(LogStatus.submitted));
      },
    );

    test(
      'Timestamp conflict resolution during offline queue sync processing',
      () async {
        fakeNetworkInfo.setConnected(false);

        final processedItems = <SyncQueueItem>[];

        syncQueueManager = SyncQueueManager(
          queueRepository: queueRepo,
          networkInfo: fakeNetworkInfo,
          customSyncHandler: (item) async {
            processedItems.add(item);
          },
        );

        final olderTimestamp = DateTime.parse('2026-07-18T06:00:00.000Z');
        final newerTimestamp = DateTime.parse('2026-07-18T09:00:00.000Z');

        // Enqueue older mutation first
        await syncQueueManager.enqueueMutation(
          id: 'attendance-mut-old',
          entityType: 'attendance_records',
          action: SyncAction.update,
          payloadJson: AttendanceRecordDto(
            id: 'att-conflict-1',
            siteId: 'site-1',
            userId: 'user-1',
            date: DateTime.parse('2026-07-18'),
            status: 'absent',
            updatedAt: olderTimestamp,
          ).toJson(),
          timestamp: olderTimestamp,
        );

        // Enqueue newer mutation second
        await syncQueueManager.enqueueMutation(
          id: 'attendance-mut-new',
          entityType: 'attendance_records',
          action: SyncAction.update,
          payloadJson: AttendanceRecordDto(
            id: 'att-conflict-1',
            siteId: 'site-1',
            userId: 'user-1',
            date: DateTime.parse('2026-07-18'),
            status: 'present',
            updatedAt: newerTimestamp,
          ).toJson(),
          timestamp: newerTimestamp,
        );

        fakeNetworkInfo.setConnected(true);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(processedItems.length, equals(2));
        expect(processedItems[0].timestamp, equals(olderTimestamp));
        expect(processedItems[1].timestamp, equals(newerTimestamp));
        expect(processedItems[1].payloadJson['status'], equals('present'));
      },
    );
  });
}
