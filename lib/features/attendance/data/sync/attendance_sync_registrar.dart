import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';

/// Registers the Attendance offline sync handler with the [SyncQueueManager].
///
/// When network connectivity is restored, queued attendance mutations (save or
/// delete) are replayed against the remote Supabase datasource.
///
/// STEP-48.10: this handler pushes **directly to the remote datasource**, the
/// same way [TrackingSyncRegistrar] does. It previously routed the drained item
/// back through `AttendanceRepository.saveAttendance`, whose local-first write
/// path re-enqueues a fresh mutation and never contacts Supabase — so a queued
/// offline attendance record never reached staging and the queue never drained
/// (silent data loss of a shift's roster). Pushing to the remote datasource here
/// is the only way a drained item leaves the device.
///
/// Conflict resolution mirrors `SyncQueueManager._defaultSupabaseSync`:
/// last-write-wins by `updated_at`. If the remote row is newer than the queued
/// mutation, the remote wins and the local mutation is skipped — an older
/// offline edit must never clobber a newer supervisor correction on the server.
class AttendanceSyncRegistrar {
  static final Logger _logger = Logger('AttendanceSyncRegistrar');

  /// Registers the sync entity handler for `attendance_records`
  /// operations on [syncQueueManager].
  static void registerSyncHandlers(
    SyncQueueManager syncQueueManager,
    AttendanceRemoteDataSource remoteDataSource,
  ) {
    syncQueueManager.registerEntityHandler(
      'attendance_records',
      (item) => _processSyncItem(item, remoteDataSource),
    );
    _logger.info('Registered sync handler for attendance_records');
  }

  /// Unregisters the attendance sync handler.
  static void unregisterSyncHandlers(SyncQueueManager syncQueueManager) {
    syncQueueManager.unregisterEntityHandler('attendance_records');
    _logger.info('Unregistered attendance_records handler');
  }

  /// Processes a single queued sync item by pushing it to the remote datasource.
  static Future<void> _processSyncItem(
    SyncQueueItem item,
    AttendanceRemoteDataSource remoteDataSource,
  ) async {
    _logger.info(
      'Processing attendance sync item [${item.id}]: ${item.action.name}',
    );

    final payload = item.payloadJson;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        final dto = AttendanceRecordDto.fromJson(payload);
        // Last-write-wins: skip when the remote row is newer than this queued
        // mutation (mirrors SyncQueueManager._defaultSupabaseSync).
        final remote = await remoteDataSource.fetchAttendanceById(dto.id);
        if (remote?.updatedAt != null &&
            remote!.updatedAt!.isAfter(item.timestamp)) {
          _logger.warning(
            'Conflict for attendance [${dto.id}]: remote (${remote.updatedAt}) '
            'is newer than queued mutation (${item.timestamp}). Remote wins.',
          );
          return;
        }
        await remoteDataSource.upsertAttendance(dto);
        break;

      case SyncAction.delete:
        await remoteDataSource.deleteAttendance(payload['id'] as String);
        break;
    }
  }
}
