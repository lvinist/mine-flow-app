import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:mine_flow/features/tracking/data/models/cut_fill_model.dart';
import 'package:mine_flow/features/tracking/data/models/inventory_item_model.dart';
import 'package:mine_flow/features/tracking/data/models/land_clearing_model.dart';

/// Registers sync queue entity handlers for Cut/Fill, Land Clearing, and
/// Inventory tracking entities with the [SyncQueueManager].
///
/// Each handler replays queued offline mutations to the remote Supabase
/// datasource when network connectivity is restored.
class TrackingSyncRegistrar {
  static final Logger _logger = Logger('TrackingSyncRegistrar');

  /// Registers entity handlers for all three tracking entity types.
  static void registerSyncHandlers(
    SyncQueueManager syncQueueManager,
    TrackingRemoteDataSource remoteDataSource,
  ) {
    syncQueueManager.registerEntityHandler(
      'cut_fill_records',
      (item) => _processCutFillSync(item, remoteDataSource),
    );
    _logger.info('Registered sync handler for cut_fill_records');

    syncQueueManager.registerEntityHandler(
      'land_clearing_records',
      (item) => _processLandClearingSync(item, remoteDataSource),
    );
    _logger.info('Registered sync handler for land_clearing_records');

    syncQueueManager.registerEntityHandler(
      'inventory_items',
      (item) => _processInventorySync(item, remoteDataSource),
    );
    _logger.info('Registered sync handler for inventory_items');
  }

  /// Unregisters all tracking entity handlers from [syncQueueManager].
  static void unregisterSyncHandlers(SyncQueueManager syncQueueManager) {
    syncQueueManager.unregisterEntityHandler('cut_fill_records');
    syncQueueManager.unregisterEntityHandler('land_clearing_records');
    syncQueueManager.unregisterEntityHandler('inventory_items');
    _logger.info('Unregistered all tracking sync handlers');
  }

  // --- Cut/Fill Sync Processor ---

  static Future<void> _processCutFillSync(
    dynamic item,
    TrackingRemoteDataSource remoteDataSource,
  ) async {
    final payload = item.payloadJson as Map<String, dynamic>;
    final model = CutFillModel.fromJson(payload);

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        await remoteDataSource.createCutFillRecord(model);
        break;
      case SyncAction.delete:
        await remoteDataSource.deleteCutFillRecord(model.id);
        break;
    }
  }

  // --- Land Clearing Sync Processor ---

  static Future<void> _processLandClearingSync(
    dynamic item,
    TrackingRemoteDataSource remoteDataSource,
  ) async {
    final payload = item.payloadJson as Map<String, dynamic>;
    final model = LandClearingModel.fromJson(payload);

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        await remoteDataSource.createLandClearingRecord(model);
        break;
      case SyncAction.delete:
        await remoteDataSource.deleteLandClearingRecord(model.id);
        break;
    }
  }

  // --- Inventory Sync Processor ---

  static Future<void> _processInventorySync(
    dynamic item,
    TrackingRemoteDataSource remoteDataSource,
  ) async {
    final payload = item.payloadJson as Map<String, dynamic>;
    final model = InventoryItemModel.fromJson(payload);

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        await remoteDataSource.saveInventoryItem(model);
        break;
      case SyncAction.delete:
        await remoteDataSource.deleteInventoryItem(model.id);
        break;
    }
  }
}
