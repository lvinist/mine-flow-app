import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';

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
    BenchmarkRepository benchmarkRepository,
  ) {
    syncQueueManager.registerEntityHandler(
      'benchmarks',
      (item) => _processSyncItem(item, benchmarkRepository),
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
    BenchmarkRepository benchmarkRepository,
  ) async {
    _logger.info(
      'Processing benchmark sync item [${item.id}]: ${item.action.name}',
    );

    final payload = item.payloadJson;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        // Reconstruct the Model from the payload and save via repository.
        final model = BenchmarkModel.fromJson(payload);
        await benchmarkRepository.saveBenchmark(model.toDomain());
        break;

      case SyncAction.delete:
        await benchmarkRepository.deleteBenchmark(payload['id'] as String);
        break;
    }
  }
}
