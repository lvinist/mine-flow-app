/// Unit tests for [BenchmarkSyncRegistrar].
///
/// Tests that the registrar correctly registers/unregisters entity handlers
/// and processes sync queue items (create, update, delete) by forwarding
/// them to [BenchmarkRepository].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';
import 'package:mine_flow/features/benchmark/data/sync/benchmark_sync_registrar.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockBenchmarkRepository extends Mock implements BenchmarkRepository {}

void main() {
  late MockSyncQueueManager mockSyncQueue;
  late MockBenchmarkRepository mockRepository;

  const testId = '00000000-0000-0000-0000-000000000001';
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
  });

  group('registerSyncHandlers', () {
    test('registers the benchmarks entity handler', () {
      when(
        () => mockSyncQueue.registerEntityHandler(any(), any()),
      ).thenReturn(null);

      BenchmarkSyncRegistrar.registerSyncHandlers(
        mockSyncQueue,
        mockRepository,
      );

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
          () => mockRepository.saveBenchmark(any()),
        ).thenAnswer((_) async {});

        BenchmarkSyncRegistrar.registerSyncHandlers(
          mockSyncQueue,
          mockRepository,
        );

        expect(capturedHandler, isNotNull);

        final item = SyncQueueItem(
          id: 'benchmark_create_1',
          entityType: 'benchmarks',
          action: SyncAction.create,
          payloadJson: testModel.toJson(),
          timestamp: DateTime.now(),
        );

        await capturedHandler!(item);

        verify(() => mockRepository.saveBenchmark(any())).called(1);
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
          () => mockRepository.saveBenchmark(any()),
        ).thenAnswer((_) async {});

        BenchmarkSyncRegistrar.registerSyncHandlers(
          mockSyncQueue,
          mockRepository,
        );

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
            verify(
                  () => mockRepository.saveBenchmark(captureAny()),
                ).captured.single
                as Benchmark;
        expect(captured.id, testId);
        expect(captured.bmId, 'BM-001');
      },
    );

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

        when(
          () => mockRepository.deleteBenchmark(any()),
        ).thenAnswer((_) async {});

        BenchmarkSyncRegistrar.registerSyncHandlers(
          mockSyncQueue,
          mockRepository,
        );

        expect(capturedHandler, isNotNull);

        final item = SyncQueueItem(
          id: 'benchmark_delete_1',
          entityType: 'benchmarks',
          action: SyncAction.delete,
          payloadJson: {'id': testId},
          timestamp: DateTime.now(),
        );

        await capturedHandler!(item);

        verify(() => mockRepository.deleteBenchmark(testId)).called(1);
      },
    );
  });
}
