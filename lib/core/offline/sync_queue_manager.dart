import 'dart:async';

import 'package:logging/logging.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/battery_state_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Callback type for executing a remote sync operation for a [SyncQueueItem].
typedef RemoteSyncHandler = Future<void> Function(SyncQueueItem item);

/// Background queue manager responsible for enqueuing offline mutations,
/// monitoring network connectivity, and replaying pending queue items
/// against Supabase with timestamp-based last-write-wins conflict resolution.
class SyncQueueManager {
  final HiveCacheRepository<SyncQueueItem> queueRepository;
  final NetworkInfo networkInfo;
  final SupabaseClient? supabaseClient;
  final RemoteSyncHandler? customSyncHandler;
  final int maxRetries;
  final BatteryStateProvider batteryProvider;

  static final Logger _logger = Logger('SyncQueueManager');
  final Map<String, RemoteSyncHandler> _entityHandlers = {};
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isProcessing = false;

  /// Whether a queue drain is currently in flight.
  ///
  /// Exposed so callers/tests can wait for an in-progress (often
  /// connectivity-triggered) drain to finish before issuing a manual
  /// `processQueue`, which would otherwise be skipped by the re-entrancy guard.
  bool get isProcessing => _isProcessing;

  SyncQueueManager({
    required this.queueRepository,
    required this.networkInfo,
    this.supabaseClient,
    this.customSyncHandler,
    this.maxRetries = 3,
    BatteryStateProvider? batteryProvider,
  }) : batteryProvider = batteryProvider ?? DefaultBatteryStateProvider() {
    _initConnectivityListener();
  }

  /// Registers a custom [RemoteSyncHandler] callback for a specific entity type.
  void registerEntityHandler(String entityType, RemoteSyncHandler handler) {
    _entityHandlers[entityType] = handler;
    _logger.info('Registered sync handler for entity type: $entityType');
  }

  /// Unregisters an entity sync handler.
  void unregisterEntityHandler(String entityType) {
    _entityHandlers.remove(entityType);
    _logger.info('Unregistered sync handler for entity type: $entityType');
  }

  /// Checks if a sync handler is registered for a given entity type.
  bool hasEntityHandler(String entityType) =>
      _entityHandlers.containsKey(entityType);

  /// Subscribes to connectivity changes and automatically triggers processing when online.
  void _initConnectivityListener() {
    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) {
        _logger.info('Network connectivity restored. Triggering queue sync.');
        unawaited(processQueue());
      }
    });
  }

  /// Enqueues a new offline mutation item into the local Hive queue box.
  /// If device is currently online, immediately triggers queue processing.
  Future<void> enqueue(SyncQueueItem item) async {
    _logger.info(
      'Enqueuing offline item [${item.id}] for entity "${item.entityType}" (${item.action.name})',
    );
    await queueRepository.put(item.id, item);

    final isOnline = await networkInfo.isConnected;
    if (isOnline) {
      unawaited(processQueue());
    }
  }

  /// Creates and enqueues a [SyncQueueItem] helper method.
  Future<SyncQueueItem> enqueueMutation({
    String? id,
    required String entityType,
    required SyncAction action,
    required Map<String, dynamic> payloadJson,
    required DateTime timestamp,
  }) async {
    final itemId =
        id ??
        '${entityType}_${action.name}_${payloadJson['id'] ?? ''}_${DateTime.now().microsecondsSinceEpoch}';
    final item = SyncQueueItem(
      id: itemId,
      entityType: entityType,
      action: action,
      payloadJson: payloadJson,
      timestamp: timestamp,
      syncStatus: SyncStatus.pending,
    );
    await enqueue(item);
    return item;
  }

  /// Processes all pending items in FIFO order (sorted by timestamp).
  Future<void> processQueue({bool isManual = false}) async {
    // Re-entrancy guard. The flag MUST be set synchronously — before the first
    // `await` below — for the guard to be effective. On reconnect the
    // connectivity listener fires processQueue() at the same time a manual
    // processQueue(isManual: true) may already be in flight. If the flag were
    // only set after the awaits (connectivity/battery checks), both calls would
    // pass the `if (_isProcessing)` check while suspended and then drain the
    // queue concurrently, sending the same mutation twice (STEP-48.10 —
    // "reconnect drains the queue FIFO by timestamp" produced ['earlier',
    // 'later', 'later']). Setting it here, with no await in between, closes that
    // window on Dart's single-threaded event loop.
    if (_isProcessing) {
      _logger.fine('Queue processing already in progress. Skipping.');
      return;
    }
    _isProcessing = true;

    try {
      final isOnline = await networkInfo.isConnected;
      if (!isOnline) {
        _logger.fine('Device offline. Sync processing deferred.');
        return;
      }

      if (!isManual) {
        final isCharging = await batteryProvider.isCharging;
        if (!isCharging) {
          final isSaverOn = await batteryProvider.isInBatterySaveMode;
          final batteryLevel = await batteryProvider.batteryLevel;
          if (isSaverOn || batteryLevel <= 20) {
            _logger.warning(
              'Low battery condition met ($batteryLevel%, saver: $isSaverOn). Pausing automatic sync.',
            );
            return;
          }
        }
      }

      final pendingItems = getPendingItems();
      if (pendingItems.isEmpty) {
        _logger.fine('No pending sync items to process.');
        return;
      }

      _logger.info(
        'Processing ${pendingItems.length} pending sync queue items.',
      );

      for (final item in pendingItems) {
        // Double check connectivity before processing each item
        if (!await networkInfo.isConnected) {
          _logger.warning(
            'Lost connection during queue sync processing. Pausing.',
          );
          break;
        }

        await _processItem(item);
      }
    } catch (e, stack) {
      _logger.severe('Unexpected error during sync queue processing', e, stack);
    } finally {
      _isProcessing = false;
    }
  }

  /// Processes an individual queue item against remote datasource or custom sync handler.
  Future<void> _processItem(SyncQueueItem item) async {
    _logger.info(
      'Syncing queue item [${item.id}] (${item.entityType}:${item.action.name})',
    );

    // Update status to syncing
    final syncingItem = item.copyWith(syncStatus: SyncStatus.syncing);
    await queueRepository.put(item.id, syncingItem);

    try {
      if (customSyncHandler != null) {
        await customSyncHandler!(syncingItem);
      } else if (_entityHandlers.containsKey(syncingItem.entityType)) {
        await _entityHandlers[syncingItem.entityType]!(syncingItem);
      } else if (supabaseClient != null) {
        await _defaultSupabaseSync(syncingItem);
      } else {
        _logger.warning(
          'No SupabaseClient or custom/entity handler configured. Mocking sync success.',
        );
      }

      // Mark completed
      final completedItem = syncingItem.copyWith(
        syncStatus: SyncStatus.completed,
      );
      await queueRepository.put(item.id, completedItem);
      _logger.info('Successfully synced queue item [${item.id}].');
    } catch (e) {
      final newRetryCount = item.retryCount + 1;
      final errorMsg = e.toString();
      _logger.warning(
        'Failed to sync item [${item.id}] (Attempt $newRetryCount/$maxRetries): $errorMsg',
      );

      final failedItem = item.copyWith(
        syncStatus: SyncStatus.failed,
        retryCount: newRetryCount,
        errorMessage: errorMsg,
      );
      await queueRepository.put(item.id, failedItem);
    }
  }

  /// Default Supabase execution logic with timestamp-based last-write-wins conflict resolution.
  Future<void> _defaultSupabaseSync(SyncQueueItem item) async {
    final client = supabaseClient!;
    final tableName = item.entityType;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        // Fetch existing remote record to check timestamp for last-write-wins
        try {
          final remoteData = await client
              .from(tableName)
              .select('updated_at')
              .eq('id', item.payloadJson['id'] ?? item.id)
              .maybeSingle();

          if (remoteData != null && remoteData['updated_at'] != null) {
            final remoteUpdatedAt = DateTime.parse(
              remoteData['updated_at'] as String,
            );
            if (remoteUpdatedAt.isAfter(item.timestamp)) {
              _logger.warning(
                'Conflict detected for record [${item.id}]: Remote timestamp ($remoteUpdatedAt) is newer than local timestamp (${item.timestamp}). Remote record wins.',
              );
              return;
            }
          }
        } catch (_) {
          // Record may not exist remotely yet, proceed with upsert
        }

        // Upsert record with payload and timestamp. UTC-normalized: the queue
        // item's timestamp may be local wall time, and a timestamptz write
        // without an offset is interpreted as UTC — 7h in the future on a
        // +07 device, which then wins every last-write-wins comparison
        // (STEP-48.20 re-run, 48.26 R-6 class).
        final payload = Map<String, dynamic>.from(item.payloadJson);
        payload['updated_at'] = item.timestamp.toUtc().toIso8601String();
        await client.from(tableName).upsert(payload);
        break;

      case SyncAction.delete:
        final recordId = item.payloadJson['id'] ?? item.id;
        await client.from(tableName).delete().eq('id', recordId);
        break;
    }
  }

  /// Returns list of items that are pending sync or failed with retry count < maxRetries,
  /// ordered chronologically by timestamp (FIFO).
  List<SyncQueueItem> getPendingItems() {
    final allItems = queueRepository.getAll();
    final pending = allItems.where((item) {
      return item.syncStatus == SyncStatus.pending ||
          (item.syncStatus == SyncStatus.failed &&
              item.retryCount < maxRetries);
    }).toList();

    pending.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return pending;
  }

  /// Returns list of items that permanently failed after reaching max retries.
  List<SyncQueueItem> getFailedItems() {
    return queueRepository
        .getAll()
        .where(
          (item) =>
              item.syncStatus == SyncStatus.failed &&
              item.retryCount >= maxRetries,
        )
        .toList();
  }

  /// Returns all completed queue items.
  List<SyncQueueItem> getCompletedItems() {
    return queueRepository
        .getAll()
        .where((item) => item.syncStatus == SyncStatus.completed)
        .toList();
  }

  /// Clears completed items from local queue box to free up space.
  Future<void> purgeCompletedItems() async {
    final completed = getCompletedItems();
    for (final item in completed) {
      await queueRepository.delete(item.id);
    }
    _logger.info(
      'Purged ${completed.length} completed sync items from storage.',
    );
  }

  /// Cancels background connectivity listeners and cleans up resources.
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
