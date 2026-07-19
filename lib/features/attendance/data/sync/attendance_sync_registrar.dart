import 'package:logging/logging.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';

/// Registers the Attendance offline sync handler with the [SyncQueueManager].
///
/// When network connectivity is restored, queued attendance mutations (save or
/// delete) are replayed against the remote datasource via [AttendanceRepository].
///
/// Follows the same pattern as [DataBucketSyncRegistrar] from STEP-12.1.
class AttendanceSyncRegistrar {
  static final Logger _logger = Logger('AttendanceSyncRegistrar');

  /// Registers the sync entity handler for `attendance_records`
  /// operations on [syncQueueManager].
  ///
  /// The handler replays pending attendance mutations through
  /// [attendanceRepository] when the queue is flushed on connectivity restore.
  static void registerSyncHandlers(
    SyncQueueManager syncQueueManager,
    AttendanceRepository attendanceRepository,
  ) {
    syncQueueManager.registerEntityHandler(
      'attendance_records',
      (item) => _processSyncItem(item, attendanceRepository),
    );
    _logger.info('Registered sync handler for attendance_records');
  }

  /// Unregisters the attendance sync handler.
  static void unregisterSyncHandlers(SyncQueueManager syncQueueManager) {
    syncQueueManager.unregisterEntityHandler('attendance_records');
    _logger.info('Unregistered attendance_records handler');
  }

  /// Processes a single queued sync item by forwarding it to the repository.
  static Future<void> _processSyncItem(
    SyncQueueItem item,
    AttendanceRepository attendanceRepository,
  ) async {
    _logger.info(
      'Processing attendance sync item [${item.id}]: ${item.action.name}',
    );

    final payload = item.payloadJson;

    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        // Reconstruct the DTO from the payload and save via repository.
        final dto = AttendanceRecordDto.fromJson(payload);
        await attendanceRepository.saveAttendance(dto.toDomain());
        break;

      case SyncAction.delete:
        await attendanceRepository.deleteAttendance(payload['id'] as String);
        break;
    }
  }
}
