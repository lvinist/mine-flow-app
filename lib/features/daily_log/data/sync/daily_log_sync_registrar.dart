import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/daily_log/data/datasources/daily_log_remote_datasource.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';

/// Registers the Daily Log offline sync handler with the [SyncQueueManager].
///
/// When network connectivity is restored, queued daily log mutations (draft
/// auto-save, submit, approve, delete) are replayed against the remote Supabase
/// datasource.
///
/// STEP-48.10: this handler pushes **directly to the remote datasource**, the
/// same way [TrackingSyncRegistrar] does. It previously routed the drained item
/// back through `DailyLogRepository.autoSaveDraft`, whose local-first write path
/// re-enqueues a fresh mutation and never contacts Supabase — so a queued
/// offline daily log never reached staging and the queue never drained (silent
/// data loss of a shift's log). Pushing to the remote datasource here is the
/// only way a drained item leaves the device.
///
/// Conflict resolution mirrors `SyncQueueManager._defaultSupabaseSync`:
/// last-write-wins by `updated_at`. If the remote row is newer than the queued
/// mutation, the remote wins and the local mutation is skipped.
class DailyLogSyncRegistrar {
  static final Logger _logger = Logger('DailyLogSyncRegistrar');

  /// Registers the sync entity handler for `daily_logs`
  /// operations on [syncQueueManager].
  static void registerSyncHandlers(
    SyncQueueManager syncQueueManager,
    DailyLogRemoteDataSource remoteDataSource,
  ) {
    syncQueueManager.registerEntityHandler(
      'daily_logs',
      (item) => _processSyncItem(item, remoteDataSource),
    );
    _logger.info('Registered sync handler for daily_logs');
  }

  /// Unregisters the daily log sync handler.
  static void unregisterSyncHandlers(SyncQueueManager syncQueueManager) {
    syncQueueManager.unregisterEntityHandler('daily_logs');
    _logger.info('Unregistered daily_logs handler');
  }

  /// Processes a single queued sync item by pushing it to the remote datasource.
  static Future<void> _processSyncItem(
    SyncQueueItem item,
    DailyLogRemoteDataSource remoteDataSource,
  ) async {
    _logger.info(
      'Processing daily log sync item [${item.id}]: ${item.action.name}',
    );

    final payload = item.payloadJson;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        final dto = DailyLogDto.fromJson(payload);
        // Last-write-wins: skip when the remote row is newer than this queued
        // mutation (mirrors SyncQueueManager._defaultSupabaseSync).
        final remote = await remoteDataSource.fetchDailyLogById(dto.id);
        if (remote?.updatedAt != null &&
            remote!.updatedAt!.isAfter(item.timestamp)) {
          _logger.warning(
            'Conflict for daily log [${dto.id}]: remote (${remote.updatedAt}) '
            'is newer than queued mutation (${item.timestamp}). Remote wins.',
          );
          return;
        }
        await remoteDataSource.upsertDailyLog(dto);
        break;

      case SyncAction.delete:
        await remoteDataSource.deleteDailyLog(payload['id'] as String);
        break;
    }
  }
}
