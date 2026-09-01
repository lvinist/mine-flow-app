import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';

/// Abstract repository contract for the Data Bucket feature.
///
/// Manages geospatial file metadata — CRUD operations, real-time streaming,
/// and offline sync for the `geospatial_files` Supabase table.
abstract class DataBucketRepository {
  /// Returns a reactive stream of [GeospatialFile] records filtered by optional criteria.
  ///
  /// Local-first, matching [getFiles]: the stream emits the cached record set
  /// whenever the cache changes, which includes the background refresh
  /// [getFiles] kicks off. A presenter that subscribes therefore sees rows that
  /// arrive from the backend *after* it mounted.
  ///
  /// STEP-48.22 (re-run, finding R-4): this previously proxied the Supabase
  /// realtime stream directly, bypassing the cache and the site/zone/type
  /// filters' single source of truth, and no presenter used it — so the file
  /// list rendered its first cache read forever.
  Stream<List<GeospatialFile>> watchFiles({
    String? siteId,
    String? zoneId,
    String? fileType,
  });

  /// Fetches [GeospatialFile] records matching the given filter criteria.
  /// Returns from the local cache first, with a background remote refresh.
  Future<List<GeospatialFile>> getFiles({
    String? siteId,
    String? zoneId,
    String? fileType,
    String? searchQuery,
  });

  /// Retrieves a single [GeospatialFile] by its [id].
  /// Returns `null` if not found.
  Future<GeospatialFile?> getFile(String id);

  /// Saves a [GeospatialFile] record.
  /// Writes to local cache first, then enqueues a remote sync operation.
  /// Returns the saved file (with any server-assigned fields populated).
  Future<GeospatialFile> saveFile(GeospatialFile file);

  /// Soft-deletes a [GeospatialFile] record by its [id].
  /// Marks as deleted locally and enqueues a remote delete operation.
  Future<void> deleteFile(String id);

  /// Processes all pending offline mutations and syncs them to Supabase.
  /// Called by SyncQueueManager when connectivity is restored.
  Future<void> syncPendingUploads();
}
