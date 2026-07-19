import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/data_bucket/data/models/geospatial_file_model.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';

/// Registers the Data Bucket's offline metadata sync handler with the
/// [SyncQueueManager].
///
/// When network connectivity is restored, queued metadata mutations (save or
/// delete) are replayed against Supabase via [DataBucketRepository.syncPendingUploads].
///
/// Follows the same pattern as [TrackingSyncRegistrar] from STEP-7.5.
class DataBucketSyncRegistrar {
  static final Logger _logger = Logger('DataBucketSyncRegistrar');

  /// Registers the sync entity handler for `data_bucket_metadata_sync`
  /// operations on [syncQueueManager].
  ///
  /// The handler replays pending metadata mutations through
  /// [dataBucketRepository] when the queue is flushed on connectivity restore.
  static void registerSyncHandlers(
    SyncQueueManager syncQueueManager,
    DataBucketRepository dataBucketRepository,
  ) {
    syncQueueManager.registerEntityHandler(
      'data_bucket_metadata_sync',
      (item) => _processSyncItem(item, dataBucketRepository),
    );
    _logger.info('Registered sync handler for data_bucket_metadata_sync');
  }

  /// Unregisters the data bucket sync handler.
  static void unregisterSyncHandlers(SyncQueueManager syncQueueManager) {
    syncQueueManager.unregisterEntityHandler('data_bucket_metadata_sync');
    _logger.info('Unregistered data_bucket_metadata_sync handler');
  }

  /// Processes a single queued sync item by forwarding it to the repository.
  static Future<void> _processSyncItem(
    SyncQueueItem item,
    DataBucketRepository dataBucketRepository,
  ) async {
    _logger.info(
      'Processing data_bucket sync item [${item.id}]: ${item.action.name}',
    );

    final payload = item.payloadJson;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        // Reconstruct the model from the payload and sync via repository.
        // The repository's syncPendingUploads handles bulk fetch-and-merge,
        // but for individual enqueued mutations we upsert through the
        // repository's live save path.
        final model = GeospatialFileModel.fromJson(payload);
        await dataBucketRepository.saveFile(model.toDomain());
        break;

      case SyncAction.delete:
        await dataBucketRepository.deleteFile(payload['id'] as String);
        break;
    }
  }
}
