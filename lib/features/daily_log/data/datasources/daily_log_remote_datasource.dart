import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for remote Supabase queries for daily operations logging.
abstract class DailyLogRemoteDataSource {
  /// Fetches all remote daily log entries.
  Future<List<DailyLogDto>> fetchAllDailyLogs();

  /// Fetches a single daily log entry by unique ID.
  Future<DailyLogDto?> fetchDailyLogById(String id);

  /// Upserts (inserts/updates) a daily log record on remote Supabase DB.
  Future<void> upsertDailyLog(DailyLogDto dto);

  /// Deletes a daily log record from remote Supabase DB.
  Future<void> deleteDailyLog(String id);
}

/// Implementation of [DailyLogRemoteDataSource] backed by Supabase.
class SupabaseDailyLogRemoteDataSource implements DailyLogRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupabaseDailyLogRemoteDataSource(this.supabaseClient);

  @override
  Future<List<DailyLogDto>> fetchAllDailyLogs() async {
    final response = await supabaseClient
        .from('daily_logs')
        .select()
        .filter('deleted_at', 'is', null);

    return (response as List<dynamic>)
        .map((json) => DailyLogDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DailyLogDto?> fetchDailyLogById(String id) async {
    final response = await supabaseClient
        .from('daily_logs')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return DailyLogDto.fromJson(response);
  }

  @override
  Future<void> upsertDailyLog(DailyLogDto dto) async {
    await supabaseClient.from('daily_logs').upsert(dto.toJson());
  }

  @override
  Future<void> deleteDailyLog(String id) async {
    await supabaseClient
        .from('daily_logs')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
