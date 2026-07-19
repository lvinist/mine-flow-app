import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';

/// Registers the Daily Log offline sync handler with the [SyncQueueManager].
///
/// When network connectivity is restored, queued daily log mutations (draft
/// auto-save, submit, approve, delete) are replayed against the remote
/// datasource via [DailyLogRepository].
///
/// Follows the same pattern as [AttendanceSyncRegistrar] from STEP-11.
class DailyLogSyncRegistrar {
  static final Logger _logger = Logger('DailyLogSyncRegistrar');

  /// Registers the sync entity handler for `daily_logs`
  /// operations on [syncQueueManager].
  ///
  /// The handler replays pending daily log mutations through
  /// [dailyLogRepository] when the queue is flushed on connectivity restore.
  static void registerSyncHandlers(
    SyncQueueManager syncQueueManager,
    DailyLogRepository dailyLogRepository,
  ) {
    syncQueueManager.registerEntityHandler(
      'daily_logs',
      (item) => _processSyncItem(item, dailyLogRepository),
    );
    _logger.info('Registered sync handler for daily_logs');
  }

  /// Unregisters the daily log sync handler.
  static void unregisterSyncHandlers(SyncQueueManager syncQueueManager) {
    syncQueueManager.unregisterEntityHandler('daily_logs');
    _logger.info('Unregistered daily_logs handler');
  }

  /// Processes a single queued sync item by forwarding it to the repository.
  static Future<void> _processSyncItem(
    SyncQueueItem item,
    DailyLogRepository dailyLogRepository,
  ) async {
    _logger.info(
      'Processing daily log sync item [${item.id}]: ${item.action.name}',
    );

    final payload = item.payloadJson;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        // Reconstruct the DTO from the payload, convert to domain, and
        // auto-save via repository (which upserts locally + queues).
        final dto = DailyLogDto.fromJson(payload);
        await dailyLogRepository.autoSaveDraft(dto.toDomain());
        break;

      case SyncAction.delete:
        await dailyLogRepository.deleteDailyLog(payload['id'] as String);
        break;
    }
  }
}
