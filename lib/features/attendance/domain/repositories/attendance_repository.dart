import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';

/// Abstract contract for managing crew attendance operations.
abstract class AttendanceRepository {
  /// Fetches attendance records for a specific date (and optional site ID).
  Future<List<AttendanceRecord>> getAttendanceForDate(
    DateTime date, {
    String? siteId,
  });

  /// Fetches attendance records for a specific user across a date range.
  Future<List<AttendanceRecord>> getAttendanceForUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Fetches a single attendance record by unique ID.
  Future<AttendanceRecord?> getAttendanceById(String id);

  /// Saves or updates a single attendance record offline-first.
  Future<void> saveAttendance(AttendanceRecord record);

  /// Saves or updates multiple attendance records in batch offline-first.
  Future<void> saveAttendanceBatch(List<AttendanceRecord> records);

  /// Deletes an attendance record by ID offline-first.
  Future<void> deleteAttendance(String id);

  /// Synchronizes remote Supabase data into local Hive cache.
  Future<List<AttendanceRecord>> syncRemote();
}
