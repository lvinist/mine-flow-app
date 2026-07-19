import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';

/// Registers the Equipment Check offline sync handler with the
/// [SyncQueueManager].
///
/// When network connectivity is restored, queued equipment check mutations
/// (upsert, delete) are replayed against the remote datasource via
/// [EquipmentCheckRepository].
///
/// Follows the same pattern as [DailyLogSyncRegistrar] from STEP-11.
class EquipmentCheckSyncRegistrar {
  static final Logger _logger = Logger('EquipmentCheckSyncRegistrar');

  /// Registers the sync entity handler for `equipment_checks`
  /// operations on [syncQueueManager].
  ///
  /// The handler replays pending equipment check mutations through
  /// [equipmentCheckRepository] when the queue is flushed on connectivity
  /// restore.
  static void registerSyncHandlers(
    SyncQueueManager syncQueueManager,
    EquipmentCheckRepository equipmentCheckRepository,
  ) {
    syncQueueManager.registerEntityHandler(
      'equipment_checks',
      (item) => _processSyncItem(item, equipmentCheckRepository),
    );
    _logger.info('Registered sync handler for equipment_checks');
  }

  /// Unregisters the equipment check sync handler.
  static void unregisterSyncHandlers(SyncQueueManager syncQueueManager) {
    syncQueueManager.unregisterEntityHandler('equipment_checks');
    _logger.info('Unregistered equipment_checks handler');
  }

  /// Processes a single queued sync item by forwarding it to the repository.
  static Future<void> _processSyncItem(
    SyncQueueItem item,
    EquipmentCheckRepository equipmentCheckRepository,
  ) async {
    _logger.info(
      'Processing equipment check sync item [${item.id}]: ${item.action.name}',
    );

    final payload = item.payloadJson;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        // Reconstruct the DTO from the payload, convert to domain, and
        // upsert via repository (which saves locally + queues).
        final dto = EquipmentCheckDto.fromJson(payload);
        await equipmentCheckRepository.saveEquipmentCheck(dto.toDomain());
        break;

      case SyncAction.delete:
        await equipmentCheckRepository.deleteEquipmentCheck(
          payload['id'] as String,
        );
        break;
    }
  }
}
