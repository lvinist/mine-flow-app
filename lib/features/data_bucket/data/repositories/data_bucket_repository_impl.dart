import 'dart:async';

import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/data_bucket/data/datasources/data_bucket_local_datasource.dart';
import 'package:mine_flow/features/data_bucket/data/datasources/data_bucket_remote_datasource.dart';
import 'package:mine_flow/features/data_bucket/data/models/geospatial_file_model.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';

/// Implementation of [DataBucketRepository] coordinating local Hive cache,
/// Supabase REST operations, and SyncQueueManager for offline mutations.
///
/// Read pattern: local-first with background remote refresh.
/// Write pattern: local cache immediately, enqueue remote sync.
class DataBucketRepositoryImpl implements DataBucketRepository {
  final DataBucketLocalDataSource localDataSource;
  final DataBucketRemoteDataSource remoteDataSource;
  final SyncQueueManager syncQueueManager;
  final NetworkInfo networkInfo;

  DataBucketRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncQueueManager,
    required this.networkInfo,
  });

  @override
  Stream<List<GeospatialFile>> watchFiles({
    String? siteId,
    String? zoneId,
    String? fileType,
  }) {
    return remoteDataSource.watchFiles().map(
      (models) => models
          .where((model) => _matchesFilter(model, siteId, zoneId, fileType))
          .map((model) => model.toDomain())
          .toList(),
    );
  }

  @override
  Future<List<GeospatialFile>> getFiles({
    String? siteId,
    String? zoneId,
    String? fileType,
    String? searchQuery,
  }) async {
    final localModels = localDataSource.getFiles();

    final filtered = localModels
        .where((model) {
          if (!_matchesFilter(model, siteId, zoneId, fileType)) return false;
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            final matchesFileName = model.fileName.toLowerCase().contains(
              query,
            );
            final matchesNotes =
                model.notes?.toLowerCase().contains(query) ?? false;
            if (!matchesFileName && !matchesNotes) return false;
          }
          return true;
        })
        .map((model) => model.toDomain())
        .toList();

    unawaited(_refreshIfOnline());

    return filtered;
  }

  @override
  Future<GeospatialFile?> getFile(String id) async {
    final model = localDataSource.getFile(id);
    return model?.toDomain();
  }

  @override
  Future<GeospatialFile> saveFile(GeospatialFile file) async {
    final updatedAt = DateTime.now();
    final updatedFile = file.copyWith(updatedAt: updatedAt);
    final model = GeospatialFileModel.fromDomain(updatedFile);

    // Write to local cache immediately
    await localDataSource.saveFile(model);

    final isOnline = await networkInfo.isConnected;
    if (isOnline) {
      try {
        final remoteModel = await remoteDataSource.saveFile(model);
        return remoteModel.toDomain();
      } catch (_) {
        // Remote save failed; enqueue for sync
        await syncQueueManager.enqueueMutation(
          entityType: 'data_bucket_metadata_sync',
          action: SyncAction.update,
          payloadJson: model.toJson(),
          timestamp: updatedAt,
        );
      }
    } else {
      // Offline; enqueue for later sync
      await syncQueueManager.enqueueMutation(
        entityType: 'data_bucket_metadata_sync',
        action: SyncAction.update,
        payloadJson: model.toJson(),
        timestamp: updatedAt,
      );
    }

    return updatedFile;
  }

  @override
  Future<void> deleteFile(String id) async {
    final existing = localDataSource.getFile(id);

    if (existing != null) {
      // Keep a tombstone marker for sync purposes
      final model = GeospatialFileModel(
        id: existing.id,
        siteId: existing.siteId,
        zoneId: existing.zoneId,
        fileName: existing.fileName,
        fileType: existing.fileType,
        mimeType: existing.mimeType,
        driveFileId: existing.driveFileId,
        driveLink: existing.driveLink,
        fileSizeBytes: existing.fileSizeBytes,
        latitude: existing.latitude,
        longitude: existing.longitude,
        acquisitionDate: existing.acquisitionDate,
        notes: existing.notes,
        uploadedBy: existing.uploadedBy,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      // Remove from local cache
      await localDataSource.deleteFile(id);

      final isOnline = await networkInfo.isConnected;
      if (isOnline) {
        try {
          await remoteDataSource.deleteFile(id);
        } catch (_) {
          await syncQueueManager.enqueueMutation(
            entityType: 'data_bucket_metadata_sync',
            action: SyncAction.delete,
            payloadJson: {'id': id},
            timestamp: DateTime.now(),
          );
        }
      } else {
        await syncQueueManager.enqueueMutation(
          entityType: 'data_bucket_metadata_sync',
          action: SyncAction.delete,
          payloadJson: model.toJson(),
          timestamp: DateTime.now(),
        );
      }
    } else {
      // Not in cache; just enqueue delete for remote
      await localDataSource.deleteFile(id);
      await syncQueueManager.enqueueMutation(
        entityType: 'data_bucket_metadata_sync',
        action: SyncAction.delete,
        payloadJson: {'id': id},
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<void> syncPendingUploads() async {
    final isOnline = await networkInfo.isConnected;
    if (!isOnline) return;

    try {
      final remoteFiles = await remoteDataSource.fetchFiles();
      await localDataSource.saveFileBatch(remoteFiles);
    } catch (_) {
      // Silent fail; retry on next sync trigger
    }
  }

  /// Refreshes the local cache from remote in the background.
  Future<void> _refreshIfOnline() async {
    final isOnline = await networkInfo.isConnected;
    if (!isOnline) return;

    try {
      await syncPendingUploads();
    } catch (_) {}
  }

  /// Checks whether a [GeospatialFileModel] matches the given filter criteria.
  bool _matchesFilter(
    GeospatialFileModel model,
    String? siteId,
    String? zoneId,
    String? fileType,
  ) {
    if (siteId != null && model.siteId != siteId) return false;
    if (zoneId != null && model.zoneId != zoneId) return false;
    if (fileType != null && model.fileType != fileType) return false;
    return true;
  }
}
