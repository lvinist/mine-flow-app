import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mine_flow/features/timeline/data/models/timeline_milestone_model.dart';

/// Remote datasource for timeline data backed by Supabase.
class TimelineRemoteDataSource {
  final SupabaseClient _supabaseClient;

  TimelineRemoteDataSource({required this._supabaseClient});

  /// Fetches milestones for [siteId], optionally filtered by [zoneId].
  Future<List<TimelineMilestoneModel>> getMilestones({
    required String siteId,
    String? zoneId,
  }) async {
    var query = _supabaseClient
        .from('timeline_milestones')
        .select()
        .eq('site_id', siteId)
        .isFilter('deleted_at', null);

    if (zoneId != null) query = query.eq('zone_id', zoneId);

    final data = await query.order('target_date', ascending: true);
    return data.map((json) => TimelineMilestoneModel.fromJson(json)).toList();
  }

  /// Creates a new milestone and returns the server-side result.
  Future<TimelineMilestoneModel> createMilestone(
    TimelineMilestoneModel milestone,
  ) async {
    final data = await _supabaseClient
        .from('timeline_milestones')
        .insert(milestone.toJson())
        .select()
        .single();
    return TimelineMilestoneModel.fromJson(data);
  }

  /// Updates an existing milestone.
  Future<void> updateMilestone(TimelineMilestoneModel milestone) async {
    await _supabaseClient
        .from('timeline_milestones')
        .update(milestone.toJson())
        .eq('id', milestone.id);
  }

  /// Soft-deletes a milestone by [id].
  Future<void> deleteMilestone(String id) async {
    await _supabaseClient
        .from('timeline_milestones')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  /// Fetches raw cut-fill and land-clearing records for aggregation.
  ///
  /// Returns a list of two maps keyed by type (`cut_fill` / `land_clearing`).
  /// Aggregation (grouping by day, cumulative totals) is handled by the
  /// repository implementation.
  Future<List<Map<String, dynamic>>> getProgressData({
    required String siteId,
    String? zoneId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    var cutFillQuery = _supabaseClient
        .from('cut_fill_records')
        .select()
        .eq('site_id', siteId)
        .isFilter('deleted_at', null)
        .gte('measured_at', startDate.toIso8601String())
        .lte('measured_at', endDate.toIso8601String());
    if (zoneId != null) cutFillQuery = cutFillQuery.eq('zone_id', zoneId);

    var landQuery = _supabaseClient
        .from('land_clearing_records')
        .select()
        .eq('site_id', siteId)
        .isFilter('deleted_at', null)
        .gte('cleared_at', startDate.toIso8601String())
        .lte('cleared_at', endDate.toIso8601String());
    if (zoneId != null) landQuery = landQuery.eq('zone_id', zoneId);

    final cutFillData = await cutFillQuery;
    final landData = await landQuery;

    return [
      {'type': 'cut_fill', 'data': cutFillData},
      {'type': 'land_clearing', 'data': landData},
    ];
  }
}
