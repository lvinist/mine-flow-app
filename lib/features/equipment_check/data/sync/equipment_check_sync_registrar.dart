import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/equipment_check/data/datasources/equipment_check_remote_datasource.dart';
import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';

/// Registers the Equipment Check offline sync handler with the
/// [SyncQueueManager].
///
/// When network connectivity is restored, queued equipment check mutations
/// (upsert, delete) are replayed against the remote Supabase datasource.
///
/// STEP-48.10: this handler pushes **directly to the remote datasource**, the
/// same way [TrackingSyncRegistrar] does. It previously routed the drained item
/// back through `EquipmentCheckRepository.saveEquipmentCheck`, whose local-first
/// write path re-enqueues a fresh mutation and never contacts Supabase — so a
/// queued offline equipment check never reached staging and the queue never
/// drained. Pushing to the remote datasource here is the only way a drained item
/// leaves the device. (Fixed alongside attendance and daily_log, which shared
/// the same sibling defect.)
///
/// Conflict resolution mirrors `SyncQueueManager._defaultSupabaseSync`:
/// last-write-wins by `updated_at`.
class EquipmentCheckSyncRegistrar {
  static final Logger _logger = Logger('EquipmentCheckSyncRegistrar');

  /// Registers the sync entity handler for `equipment_checks`
  /// operations on [syncQueueManager].
  static void registerSyncHandlers(
    SyncQueueManager syncQueueManager,
    EquipmentCheckRemoteDataSource remoteDataSource,
  ) {
    syncQueueManager.registerEntityHandler(
      'equipment_checks',
      (item) => _processSyncItem(item, remoteDataSource),
    );
    _logger.info('Registered sync handler for equipment_checks');
  }

  /// Unregisters the equipment check sync handler.
  static void unregisterSyncHandlers(SyncQueueManager syncQueueManager) {
    syncQueueManager.unregisterEntityHandler('equipment_checks');
    _logger.info('Unregistered equipment_checks handler');
  }

  /// Processes a single queued sync item by pushing it to the remote datasource.
  static Future<void> _processSyncItem(
    SyncQueueItem item,
    EquipmentCheckRemoteDataSource remoteDataSource,
  ) async {
    _logger.info(
      'Processing equipment check sync item [${item.id}]: ${item.action.name}',
    );

    final payload = item.payloadJson;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        final dto = EquipmentCheckDto.fromJson(payload);
        // Last-write-wins: skip when the remote row is newer than this queued
        // mutation (mirrors SyncQueueManager._defaultSupabaseSync).
        final remote = await remoteDataSource.fetchEquipmentCheckById(dto.id);
        if (remote?.updatedAt != null &&
            remote!.updatedAt!.isAfter(item.timestamp)) {
          _logger.warning(
            'Conflict for equipment check [${dto.id}]: remote '
            '(${remote.updatedAt}) is newer than queued mutation '
            '(${item.timestamp}). Remote wins.',
          );
          return;
        }
        await remoteDataSource.upsertEquipmentCheck(dto);
        break;

      case SyncAction.delete:
        await remoteDataSource.deleteEquipmentCheck(payload['id'] as String);
        break;
    }
  }
}
