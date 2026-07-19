import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Abstract contract managing daily logging domain operations and persistence.
abstract class DailyLogRepository {
  /// Queries daily log entries with optional filters.
  Future<List<DailyLog>> getDailyLogs({
    DateTime? date,
    String? siteId,
    String? foremanId,
    String? zoneId,
    LogStatus? status,
  });

  /// Retrieves a daily log entry by ID.
  Future<DailyLog?> getDailyLogById(String id);

  /// Retrieves a draft daily log for a specific foreman on a given date, if exists.
  Future<DailyLog?> getDraftLogForForeman({
    required String foremanId,
    required DateTime date,
    String? siteId,
  });

  /// Auto-saves or updates a draft daily log offline-first.
  Future<void> autoSaveDraft(DailyLog log);

  /// Submits a daily log, transitioning status from 'draft' to 'submitted'.
  Future<void> submitDailyLog(String id);

  /// Approves a submitted daily log, recording the approving user ID.
  Future<void> approveDailyLog(String id, {required String approvedBy});

  /// Deletes a daily log entry by ID offline-first (soft-delete).
  Future<void> deleteDailyLog(String id);

  /// Synchronizes remote Supabase data into local Hive cache.
  Future<List<DailyLog>> syncRemote();
}
