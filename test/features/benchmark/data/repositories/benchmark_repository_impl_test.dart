/// Unit tests for [BenchmarkRepositoryImpl].
///
/// Tests the offline-first coordination between local datasource and
/// sync queue manager for Benchmark CRUD operations.
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/benchmark/data/datasources/benchmark_local_datasource.dart';
import 'package:mine_flow/features/benchmark/data/datasources/benchmark_remote_datasource.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';
import 'package:mine_flow/features/benchmark/data/repositories/benchmark_repository_impl.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:mocktail/mocktail.dart';

// --- Mock classes ---

class MockBenchmarkLocalDataSource extends Mock
    implements BenchmarkLocalDataSource {}

class MockBenchmarkRemoteDataSource extends Mock
    implements BenchmarkRemoteDataSource {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const BenchmarkModel(
        id: 'fallback',
        bmId: 'FB-000',
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
    registerFallbackValue(SyncAction.update);
  });

  late MockBenchmarkLocalDataSource mockLocal;
  late MockBenchmarkRemoteDataSource mockRemote;
  late MockSyncQueueManager mockSyncQueue;
  late MockNetworkInfo mockNetworkInfo;
  late BenchmarkRepository repository;

  const testId = '00000000-0000-0000-0000-000000000001';
  const testBmId = 'BM-001';
  const testModel = BenchmarkModel(
    id: testId,
    bmId: testBmId,
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

  setUp(() {
    mockLocal = MockBenchmarkLocalDataSource();
    mockRemote = MockBenchmarkRemoteDataSource();
    mockSyncQueue = MockSyncQueueManager();
    mockNetworkInfo = MockNetworkInfo();

    repository = BenchmarkRepositoryImpl(
      localDataSource: mockLocal,
      remoteDataSource: mockRemote,
      syncQueueManager: mockSyncQueue,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getBenchmarks', () {
    test('returns list of benchmarks from local datasource', () async {
      when(() => mockLocal.getBenchmarks()).thenReturn([testModel]);

      final result = await repository.getBenchmarks();

      expect(result.length, 1);
      expect(result.first.bmId, testBmId);
      expect(result.first.status, 'active');
    });

    test('filters by status when provided', () async {
      const inactiveModel = BenchmarkModel(
        id: '00000000-0000-0000-0000-000000000002',
        bmId: 'BM-002',
        northing: 9_100_000.0,
        easting: 690_000.0,
        orthoHeight: 80.0,
        code: 'Pilar',
        orde: '2nd Order',
        geom: null,
        latitude: -7.26,
        longitude: 112.76,
        ellipsHeight: 85.0,
        status: 'inactive',
      );

      when(
        () => mockLocal.getBenchmarks(),
      ).thenReturn([testModel, inactiveModel]);

      final result = await repository.getBenchmarks(status: 'active');

      expect(result.length, 1);
      expect(result.first.bmId, testBmId);
      expect(result.first.status, 'active');
    });

    test('returns empty list when local datasource is empty', () async {
      when(() => mockLocal.getBenchmarks()).thenReturn([]);

      final result = await repository.getBenchmarks();

      expect(result, isEmpty);
    });
  });

  group('getBenchmarkById', () {
    test('returns benchmark when found locally', () async {
      when(() => mockLocal.getBenchmarkById(testId)).thenReturn(testModel);

      final result = await repository.getBenchmarkById(testId);

      expect(result, isNotNull);
      expect(result!.bmId, testBmId);
    });

    test('returns null when not found locally', () async {
      when(() => mockLocal.getBenchmarkById('nonexistent')).thenReturn(null);

      final result = await repository.getBenchmarkById('nonexistent');

      expect(result, isNull);
    });
  });

  group('saveBenchmark', () {
    test('saves locally and enqueues sync mutation', () async {
      when(() => mockLocal.saveBenchmark(any())).thenAnswer((_) async {});
      when(
        () => mockSyncQueue.enqueueMutation(
          entityType: any(named: 'entityType'),
          action: any(named: 'action'),
          payloadJson: any(named: 'payloadJson'),
          timestamp: any(named: 'timestamp'),
        ),
      ).thenAnswer(
        (_) async => SyncQueueItem(
          id: 'test_item',
          entityType: 'benchmarks',
          action: SyncAction.update,
          payloadJson: testModel.toJson(),
          timestamp: DateTime.now(),
          syncStatus: SyncStatus.pending,
        ),
      );
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      await repository.saveBenchmark(testModel.toDomain());

      verify(() => mockLocal.saveBenchmark(any())).called(1);
      verify(
        () => mockSyncQueue.enqueueMutation(
          entityType: 'benchmarks',
          action: SyncAction.update,
          payloadJson: any(named: 'payloadJson'),
          timestamp: any(named: 'timestamp'),
        ),
      ).called(1);
    });

    test('syncs to remote immediately when online', () async {
      when(() => mockLocal.saveBenchmark(any())).thenAnswer((_) async {});
      when(
        () => mockSyncQueue.enqueueMutation(
          entityType: any(named: 'entityType'),
          action: any(named: 'action'),
          payloadJson: any(named: 'payloadJson'),
          timestamp: any(named: 'timestamp'),
        ),
      ).thenAnswer(
        (_) async => SyncQueueItem(
          id: 'test_item',
          entityType: 'benchmarks',
          action: SyncAction.update,
          payloadJson: testModel.toJson(),
          timestamp: DateTime.now(),
          syncStatus: SyncStatus.pending,
        ),
      );
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemote.saveBenchmark(any()),
      ).thenAnswer((_) async => testModel);

      await repository.saveBenchmark(testModel.toDomain());

      verify(() => mockRemote.saveBenchmark(any())).called(1);
    });
  });

  group('deleteBenchmark', () {
    test(
      'soft-deletes by setting status to deleted when found locally',
      () async {
        when(() => mockLocal.getBenchmarkById(testId)).thenReturn(testModel);
        when(() => mockLocal.saveBenchmark(any())).thenAnswer((_) async {});
        when(
          () => mockSyncQueue.enqueueMutation(
            entityType: any(named: 'entityType'),
            action: any(named: 'action'),
            payloadJson: any(named: 'payloadJson'),
            timestamp: any(named: 'timestamp'),
          ),
        ).thenAnswer(
          (_) async => SyncQueueItem(
            id: 'test_del',
            entityType: 'benchmarks',
            action: SyncAction.delete,
            payloadJson: {'id': testId},
            timestamp: DateTime.now(),
            syncStatus: SyncStatus.pending,
          ),
        );

        await repository.deleteBenchmark(testId);

        // Verify the saved model has status "deleted"
        final captured =
            verify(() => mockLocal.saveBenchmark(captureAny())).captured.single
                as BenchmarkModel;
        expect(captured.status, 'deleted');
      },
    );

    test('hard-deletes when not found locally', () async {
      when(() => mockLocal.getBenchmarkById(testId)).thenReturn(null);
      when(() => mockLocal.deleteBenchmark(testId)).thenAnswer((_) async {});
      when(
        () => mockSyncQueue.enqueueMutation(
          entityType: any(named: 'entityType'),
          action: any(named: 'action'),
          payloadJson: any(named: 'payloadJson'),
          timestamp: any(named: 'timestamp'),
        ),
      ).thenAnswer(
        (_) async => SyncQueueItem(
          id: 'test_del',
          entityType: 'benchmarks',
          action: SyncAction.delete,
          payloadJson: {'id': testId},
          timestamp: DateTime.now(),
          syncStatus: SyncStatus.pending,
        ),
      );

      await repository.deleteBenchmark(testId);

      verify(() => mockLocal.deleteBenchmark(testId)).called(1);
    });
  });

  group('syncRemote', () {
    test('processes queue when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockSyncQueue.processQueue()).thenAnswer((_) async {});

      await repository.syncRemote();

      verify(() => mockSyncQueue.processQueue()).called(1);
    });

    test('does nothing when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      await repository.syncRemote();

      verifyNever(() => mockSyncQueue.processQueue());
    });
  });
}
