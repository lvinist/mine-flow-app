/// Unit tests for [BenchmarkSyncRegistrar].
///
/// Tests that the registrar correctly registers/unregisters entity handlers
/// and processes sync queue items (create, update, delete) by forwarding
/// them to [BenchmarkRepository].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/benchmark/data/datasources/benchmark_remote_datasource.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';
import 'package:mine_flow/features/benchmark/data/sync/benchmark_sync_registrar.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockBenchmarkRepository extends Mock implements BenchmarkRepository {}

class MockBenchmarkRemoteDataSource extends Mock
    implements BenchmarkRemoteDataSource {}

void main() {
  late MockSyncQueueManager mockSyncQueue;
  late MockBenchmarkRepository mockRepository;
  late MockBenchmarkRemoteDataSource mockRemote;

  const testId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  const testModel = BenchmarkModel(
    id: testId,
    bmId: 'BM-001',
    northing: 9_200_000.0,
    easting: 700_000.0,
    orthoHeight: 100.5,
    code: 'Pilar',
    orde: '1st Order',
    geom: null,
    latitude: -7.25,
    longitude: 112.75,
    ellipsHeight: 105.2,
    status: 'active',
  );

  setUpAll(() {
    registerFallbackValue(testModel);
    registerFallbackValue(
      SyncQueueItem(
        id: 'fallback',
        entityType: 'benchmarks',
        action: SyncAction.update,
        payloadJson: testModel.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    registerFallbackValue(
      const Benchmark(
        id: 'fallback',
        bmId: 'FB',
        northing: 0,
        easting: 0,
        orthoHeight: 0,
        code: '',
        orde: '',
        geom: null,
        latitude: 0,
        longitude: 0,
        ellipsHeight: 0,
        status: '',
      ),
    );
  });

  setUp(() {
    mockSyncQueue = MockSyncQueueManager();
    mockRepository = MockBenchmarkRepository();
    mockRemote = MockBenchmarkRemoteDataSource();
  });

  group('registerSyncHandlers', () {
    test('registers the benchmarks entity handler', () {
      when(
        () => mockSyncQueue.registerEntityHandler(any(), any()),
      ).thenReturn(null);

      BenchmarkSyncRegistrar.registerSyncHandlers(mockSyncQueue, mockRemote);

      verify(
        () => mockSyncQueue.registerEntityHandler('benchmarks', any()),
      ).called(1);
    });
  });

  group('unregisterSyncHandlers', () {
    test('unregisters the benchmarks entity handler', () {
      when(() => mockSyncQueue.unregisterEntityHandler(any())).thenReturn(null);

      BenchmarkSyncRegistrar.unregisterSyncHandlers(mockSyncQueue);

      verify(
        () => mockSyncQueue.unregisterEntityHandler('benchmarks'),
      ).called(1);
    });
  });

  group('sync processing', () {
    setUp(() {
      reset(mockRepository);
      reset(mockSyncQueue);
    });
    test(
      'processes create action by saving benchmark via repository',
      () async {
        // Capture the handler that the registrar registers
        RemoteSyncHandler? capturedHandler;
        when(
          () => mockSyncQueue.registerEntityHandler(any(), any()),
        ).thenAnswer((invocation) {
          capturedHandler =
              invocation.positionalArguments[1] as RemoteSyncHandler;
        });

        when(
          () => mockRemote.fetchBenchmarkById(testId),
        ).thenAnswer((_) async => null);
        when(
          () => mockRemote.saveBenchmark(any()),
        ).thenAnswer((_) async => testModel);

        BenchmarkSyncRegistrar.registerSyncHandlers(mockSyncQueue, mockRemote);

        expect(capturedHandler, isNotNull);

        final item = SyncQueueItem(
          id: 'benchmark_create_1',
          entityType: 'benchmarks',
          action: SyncAction.create,
          payloadJson: testModel.toJson(),
          timestamp: DateTime.now(),
        );

        await capturedHandler!(item);

        verify(() => mockRemote.saveBenchmark(any())).called(1);
      },
    );

    test(
      'processes update action by saving benchmark via repository',
      () async {
        RemoteSyncHandler? capturedHandler;
        when(
          () => mockSyncQueue.registerEntityHandler(any(), any()),
        ).thenAnswer((invocation) {
          capturedHandler =
              invocation.positionalArguments[1] as RemoteSyncHandler;
        });

        when(
          () => mockRemote.fetchBenchmarkById(testId),
        ).thenAnswer((_) async => null);
        when(
          () => mockRemote.saveBenchmark(any()),
        ).thenAnswer((_) async => testModel);

        BenchmarkSyncRegistrar.registerSyncHandlers(mockSyncQueue, mockRemote);

        expect(capturedHandler, isNotNull);

        final item = SyncQueueItem(
          id: 'benchmark_update_1',
          entityType: 'benchmarks',
          action: SyncAction.update,
          payloadJson: testModel.toJson(),
          timestamp: DateTime.now(),
        );

        await capturedHandler!(item);

        // Verify the correct domain object was passed
        final captured =
            verify(() => mockRemote.saveBenchmark(captureAny())).captured.single
                as BenchmarkModel;
        expect(captured.id, testId);
        expect(captured.bmId, 'BM-001');
      },
    );

    test('skips a queued update when the remote benchmark is newer', () async {
      RemoteSyncHandler? capturedHandler;
      when(() => mockSyncQueue.registerEntityHandler(any(), any())).thenAnswer((
        invocation,
      ) {
        capturedHandler =
            invocation.positionalArguments[1] as RemoteSyncHandler;
      });
      final remoteNewer = BenchmarkModel(
        id: testId,
        bmId: testModel.bmId,
        northing: testModel.northing,
        easting: testModel.easting,
        orthoHeight: testModel.orthoHeight,
        code: testModel.code,
        orde: testModel.orde,
        latitude: testModel.latitude,
        longitude: testModel.longitude,
        ellipsHeight: testModel.ellipsHeight,
        status: testModel.status,
        updatedAt: DateTime.parse('2026-08-31T04:00:00Z'),
      );
      when(
        () => mockRemote.fetchBenchmarkById(testId),
      ).thenAnswer((_) async => remoteNewer);

      BenchmarkSyncRegistrar.registerSyncHandlers(mockSyncQueue, mockRemote);
      await capturedHandler!(
        SyncQueueItem(
          id: 'benchmark_stale_update',
          entityType: 'benchmarks',
          action: SyncAction.update,
          payloadJson: testModel.toJson(),
          timestamp: DateTime.parse('2026-08-31T03:00:00Z'),
        ),
      );

      verifyNever(() => mockRemote.saveBenchmark(any()));
    });

    test(
      'processes delete action by deleting benchmark via repository',
      () async {
        RemoteSyncHandler? capturedHandler;
        when(
          () => mockSyncQueue.registerEntityHandler(any(), any()),
        ).thenAnswer((invocation) {
          capturedHandler =
              invocation.positionalArguments[1] as RemoteSyncHandler;
        });

        when(() => mockRemote.deleteBenchmark(any())).thenAnswer((_) async {});

        BenchmarkSyncRegistrar.registerSyncHandlers(mockSyncQueue, mockRemote);

        expect(capturedHandler, isNotNull);

        final item = SyncQueueItem(
          id: 'benchmark_delete_1',
          entityType: 'benchmarks',
          action: SyncAction.delete,
          payloadJson: {'id': testId},
          timestamp: DateTime.now(),
        );

        await capturedHandler!(item);

        verify(() => mockRemote.deleteBenchmark(testId)).called(1);
      },
    );
  });
}
