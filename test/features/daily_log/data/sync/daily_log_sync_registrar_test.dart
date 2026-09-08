/// Unit tests for [DailyLogSyncRegistrar].
///
/// Pins the last-write-wins conflict contract that the offline-sync journey's
/// Part A leg (STEP-45.11, STEP-48.23 re-run R-1) exercises end-to-end: a
/// drained `daily_logs` mutation must be SKIPPED when the remote row's
/// `updated_at` is strictly newer than the queued mutation's timestamp, and
/// pushed when it is not.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/daily_log/data/datasources/daily_log_remote_datasource.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:mine_flow/features/daily_log/data/sync/daily_log_sync_registrar.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockDailyLogRemoteDataSource extends Mock
    implements DailyLogRemoteDataSource {}

void main() {
  late MockSyncQueueManager mockSyncQueue;
  late MockDailyLogRemoteDataSource mockRemoteDataSource;

  const testId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  final queuedAt = DateTime.utc(2026, 9, 4, 12, 0);

  /// A queued offline mutation for [testId], stamped at [queuedAt] — the same
  /// shape `DailyLogRepositoryImpl.autoSaveDraft` enqueues.
  SyncQueueItem buildQueuedItem() {
    final dto = DailyLogDto.fromDomain(
      DailyLog(
        id: testId,
        siteId: testId,
        foremanId: testId,
        logDate: DateTime.utc(2026, 9, 4),
        status: LogStatus.draft,
        summary: 'STALE LOCAL — must NOT overwrite remote',
        updatedAt: queuedAt,
      ),
    );
    return SyncQueueItem(
      id: 'daily_log_update_1',
      entityType: 'daily_logs',
      action: SyncAction.update,
      payloadJson: dto.toJson(),
      timestamp: queuedAt,
    );
  }

  setUpAll(() {
    registerFallbackValue(
      SyncQueueItem(
        id: 'fallback',
        entityType: 'daily_logs',
        action: SyncAction.update,
        payloadJson: const {},
        timestamp: DateTime.now(),
      ),
    );
    registerFallbackValue(
      DailyLogDto(
        id: 'fallback',
        siteId: 'fallback',
        foremanId: 'fallback',
        logDate: DateTime.utc(2026),
        status: 'draft',
      ),
    );
  });

  setUp(() {
    mockSyncQueue = MockSyncQueueManager();
    mockRemoteDataSource = MockDailyLogRemoteDataSource();
  });

  Future<RemoteSyncHandler> captureHandler() async {
    RemoteSyncHandler? capturedHandler;
    when(() => mockSyncQueue.registerEntityHandler(any(), any())).thenAnswer((
      invocation,
    ) {
      capturedHandler = invocation.positionalArguments[1] as RemoteSyncHandler;
    });

    DailyLogSyncRegistrar.registerSyncHandlers(
      mockSyncQueue,
      mockRemoteDataSource,
    );

    expect(capturedHandler, isNotNull);
    return capturedHandler!;
  }

  group('registerSyncHandlers', () {
    test('registers the daily_logs entity handler', () async {
      await captureHandler();

      verify(
        () => mockSyncQueue.registerEntityHandler('daily_logs', any()),
      ).called(1);
    });
  });

  group('unregisterSyncHandlers', () {
    test('unregisters the daily_logs entity handler', () {
      when(() => mockSyncQueue.unregisterEntityHandler(any())).thenReturn(null);

      DailyLogSyncRegistrar.unregisterSyncHandlers(mockSyncQueue);

      verify(
        () => mockSyncQueue.unregisterEntityHandler('daily_logs'),
      ).called(1);
    });
  });

  group('sync processing — LWW conflict contract (STEP-48.23 re-run R-1)', () {
    test('skips the queued mutation when the remote row is strictly newer '
        '(remote wins — silent data loss guard)', () async {
      final handler = await captureHandler();

      // The remote row carries a stamp strictly after the queued
      // mutation's timestamp — a newer direct write must survive.
      when(() => mockRemoteDataSource.fetchDailyLogById(testId)).thenAnswer(
        (_) async => DailyLogDto(
          id: testId,
          siteId: testId,
          foremanId: testId,
          logDate: DateTime.utc(2026, 9, 4),
          status: 'draft',
          summary: 'REMOTE WINS — newer server row',
          updatedAt: queuedAt.add(const Duration(minutes: 5)),
        ),
      );

      await handler(buildQueuedItem());

      verifyNever(() => mockRemoteDataSource.upsertDailyLog(any()));
    });

    test('pushes the queued mutation when the remote row is older '
        '(local wins — the drain must not stall)', () async {
      final handler = await captureHandler();

      when(() => mockRemoteDataSource.fetchDailyLogById(testId)).thenAnswer(
        (_) async => DailyLogDto(
          id: testId,
          siteId: testId,
          foremanId: testId,
          logDate: DateTime.utc(2026, 9, 4),
          status: 'draft',
          updatedAt: queuedAt.subtract(const Duration(minutes: 5)),
        ),
      );
      when(
        () => mockRemoteDataSource.upsertDailyLog(any()),
      ).thenAnswer((_) async {});

      final item = buildQueuedItem();
      await handler(item);

      final pushed =
          verify(
                () => mockRemoteDataSource.upsertDailyLog(captureAny()),
              ).captured.single
              as DailyLogDto;
      expect(pushed.id, testId);
      expect(pushed.summary, 'STALE LOCAL — must NOT overwrite remote');
    });

    test('pushes the queued mutation when the remote row carries no updated_at '
        '(pre-migration rows are never treated as newer)', () async {
      final handler = await captureHandler();

      when(() => mockRemoteDataSource.fetchDailyLogById(testId)).thenAnswer(
        (_) async => DailyLogDto(
          id: testId,
          siteId: testId,
          foremanId: testId,
          logDate: DateTime.utc(2026, 9, 4),
          status: 'draft',
        ),
      );
      when(
        () => mockRemoteDataSource.upsertDailyLog(any()),
      ).thenAnswer((_) async {});

      await handler(buildQueuedItem());

      verify(() => mockRemoteDataSource.upsertDailyLog(any())).called(1);
    });

    test(
      'fetches the remote row before deciding (conflict check is unconditional '
      'for update actions)',
      () async {
        final handler = await captureHandler();

        when(
          () => mockRemoteDataSource.fetchDailyLogById(testId),
        ).thenAnswer((_) async => null);
        when(
          () => mockRemoteDataSource.upsertDailyLog(any()),
        ).thenAnswer((_) async {});

        await handler(buildQueuedItem());

        verify(() => mockRemoteDataSource.fetchDailyLogById(testId)).called(1);
        verify(() => mockRemoteDataSource.upsertDailyLog(any())).called(1);
      },
    );
  });
}
