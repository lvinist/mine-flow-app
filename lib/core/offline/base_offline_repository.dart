import 'dart:async';

import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';

/// Base abstract offline-first repository pattern implementation.
///
/// Ensures write-through local caching in Hive immediately on write/delete,
/// enqueues offline mutation events to [SyncQueueManager], and background-refreshes
/// local cache from remote when network connectivity is available.
abstract class BaseOfflineRepository<T> {
  final HiveCacheRepository<T> localCache;
  final SyncQueueManager syncQueueManager;
  final NetworkInfo networkInfo;

  BaseOfflineRepository({
    required this.localCache,
    required this.syncQueueManager,
    required this.networkInfo,
  });

  /// The table / entity type name (e.g. 'attendance_records').
  String get entityType;

  /// Extracts unique key ID from entity/model instance.
  String getId(T item);

  /// Serializes entity/model instance to JSON map.
  Map<String, dynamic> toJson(T item);

  /// Deserializes entity/model instance from JSON map.
  T fromJson(Map<String, dynamic> json);

  /// Extracts update timestamp from entity/model instance.
  DateTime getUpdatedAt(T item);

  /// Abstract hook for fetching remote records from remote API / Supabase.
  Future<List<T>> fetchRemote();

  /// Retrieves cached items from Hive immediately.
  /// Triggers background remote refresh if [fetchRemoteIfOnline] is true and device is online.
  Future<List<T>> getAll({bool fetchRemoteIfOnline = true}) async {
    final cached = localCache.getAll();
    if (fetchRemoteIfOnline) {
      unawaited(networkInfo.isConnected.then((isOnline) {
        if (isOnline) {
          unawaited(refreshRemote());
        }
      }));
    }
    return cached;
  }

  /// Retrieves single cached item by ID.
  T? getById(String id) {
    return localCache.get(id);
  }

  /// Saves or updates [item] offline-first:
  /// Writes to local Hive cache immediately, then enqueues to [SyncQueueManager].
  Future<void> save(T item) async {
    final id = getId(item);
    await localCache.put(id, item);

    final payload = toJson(item);
    final timestamp = getUpdatedAt(item);

    await syncQueueManager.enqueueMutation(
      entityType: entityType,
      action: SyncAction.update,
      payloadJson: payload,
      timestamp: timestamp,
    );
  }

  /// Deletes item by ID offline-first:
  /// Deletes from local Hive cache immediately, then enqueues delete to [SyncQueueManager].
  Future<void> delete(String id) async {
    await localCache.delete(id);

    await syncQueueManager.enqueueMutation(
      entityType: entityType,
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: DateTime.now(),
    );
  }

  /// Fetches latest records from remote datasource and updates local Hive cache.
  Future<List<T>> refreshRemote() async {
    try {
      final remoteItems = await fetchRemote();
      final Map<String, T> itemMap = {
        for (final item in remoteItems) getId(item): item
      };
      await localCache.putAll(itemMap);
      return remoteItems;
    } catch (_) {
      return localCache.getAll();
    }
  }
}
