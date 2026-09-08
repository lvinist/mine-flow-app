import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';
import 'package:mine_flow/features/benchmark/data/datasources/benchmark_remote_datasource.dart';

/// Registers the Benchmark offline sync handler with the [SyncQueueManager].
///
/// When network connectivity is restored, queued benchmark mutations
/// (save or delete) are replayed against the remote datasource via
/// [BenchmarkRepository].
///
/// Follows the same pattern as [AttendanceSyncRegistrar] and
/// [DailyLogSyncRegistrar].
class BenchmarkSyncRegistrar {
  static final Logger _logger = Logger('BenchmarkSyncRegistrar');

  /// Registers the sync entity handler for `benchmarks`
  /// operations on [syncQueueManager].
  ///
  /// The handler replays pending benchmark mutations through
  /// [benchmarkRepository] when the queue is flushed on connectivity restore.
  static void registerSyncHandlers(
    SyncQueueManager syncQueueManager,
    BenchmarkRemoteDataSource remoteDataSource,
  ) {
    syncQueueManager.registerEntityHandler(
      'benchmarks',
      (item) => _processSyncItem(item, remoteDataSource),
    );
    _logger.info('Registered sync handler for benchmarks');
  }

  /// Unregisters the benchmark sync handler.
  static void unregisterSyncHandlers(SyncQueueManager syncQueueManager) {
    syncQueueManager.unregisterEntityHandler('benchmarks');
    _logger.info('Unregistered benchmarks handler');
  }

  /// Processes a single queued sync item by forwarding it to the repository.
  static Future<void> _processSyncItem(
    SyncQueueItem item,
    BenchmarkRemoteDataSource remoteDataSource,
  ) async {
    _logger.info(
      'Processing benchmark sync item [${item.id}]: ${item.action.name}',
    );

    final payload = item.payloadJson;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        final model = BenchmarkModel.fromJson(payload);
        final remote = await remoteDataSource.fetchBenchmarkById(model.id);
        if (remote?.updatedAt != null &&
            remote!.updatedAt!.isAfter(item.timestamp.toUtc())) {
          _logger.warning(
            'Remote benchmark ${model.id} is newer; remote wins.',
          );
          return;
        }
        await remoteDataSource.saveBenchmark(model);
        break;

      case SyncAction.delete:
        await remoteDataSource.deleteBenchmark(payload['id'] as String);
        break;
    }
  }
}
