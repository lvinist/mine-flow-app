import 'package:mine_flow/features/timeline/domain/entities/timeline_data_point.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';

/// Abstract repository for work-timeline data.
///
/// Coordinates milestone CRUD and aggregated progress data from
/// `cut_fill_records` and `land_clearing_records`.
abstract class TimelineRepository {
  /// Returns all milestones for [siteId], optionally filtered by [zoneId].
  Future<List<TimelineMilestone>> getMilestones({
    required String siteId,
    String? zoneId,
  });

  /// Creates a new milestone and returns it with server-generated fields.
  Future<TimelineMilestone> createMilestone(TimelineMilestone milestone);

  /// Updates an existing milestone.
  Future<void> updateMilestone(TimelineMilestone milestone);

  /// Soft-deletes a milestone by [id].
  Future<void> deleteMilestone(String id);

  /// Returns aggregated daily progress data between [startDate] and [endDate].
  ///
  /// Data is built from `cut_fill_records` and `land_clearing_records`,
  /// grouped by day, with cumulative running totals.
  Future<List<TimelineDataPoint>> getProgressData({
    required String siteId,
    String? zoneId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
