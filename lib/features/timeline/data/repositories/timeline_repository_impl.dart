import 'package:mine_flow/features/timeline/data/datasources/timeline_remote_datasource.dart';
import 'package:mine_flow/features/timeline/data/models/timeline_milestone_model.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_data_point.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';

/// Implementation of [TimelineRepository] backed by Supabase.
class TimelineRepositoryImpl implements TimelineRepository {
  final TimelineRemoteDataSource _remoteDataSource;

  TimelineRepositoryImpl({required this._remoteDataSource});

  @override
  Future<List<TimelineMilestone>> getMilestones({
    required String siteId,
    String? zoneId,
  }) async {
    try {
      final models = await _remoteDataSource.getMilestones(
        siteId: siteId,
        zoneId: zoneId,
      );
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<TimelineMilestone> createMilestone(TimelineMilestone milestone) async {
    final model = TimelineMilestoneModel.fromEntity(milestone);
    final result = await _remoteDataSource.createMilestone(model);
    return result.toEntity();
  }

  @override
  Future<void> updateMilestone(TimelineMilestone milestone) async {
    final model = TimelineMilestoneModel.fromEntity(milestone);
    await _remoteDataSource.updateMilestone(model);
  }

  @override
  Future<void> deleteMilestone(String id) async {
    await _remoteDataSource.deleteMilestone(id);
  }

  @override
  Future<List<TimelineDataPoint>> getProgressData({
    required String siteId,
    String? zoneId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final rawData = await _remoteDataSource.getProgressData(
        siteId: siteId,
        zoneId: zoneId,
        startDate: startDate,
        endDate: endDate,
      );

      final cutFillRecords =
          (rawData.firstWhere((r) => r['type'] == 'cut_fill')['data']
              as List<dynamic>);
      final landRecords =
          (rawData.firstWhere((r) => r['type'] == 'land_clearing')['data']
              as List<dynamic>);

      // Group by day string 'YYYY-MM-DD'
      final Map<String, TimelineDataPoint> dailyMap = {};

      for (final r in cutFillRecords) {
        final dateStr = (r['measurement_date'] as String).substring(0, 10);
        final cut = (r['cut_volume_m3'] as num?)?.toDouble() ?? 0.0;
        final fill = (r['fill_volume_m3'] as num?)?.toDouble() ?? 0.0;

        final existing =
            dailyMap[dateStr] ?? TimelineDataPoint(date: DateTime.parse(dateStr));
        dailyMap[dateStr] = TimelineDataPoint(
          date: existing.date,
          dailyCutVolume: existing.dailyCutVolume + cut,
          dailyFillVolume: existing.dailyFillVolume + fill,
          dailyLandClearing: existing.dailyLandClearing,
        );
      }

      for (final r in landRecords) {
        final dateStr = (r['date'] as String).substring(0, 10);
        final area = (r['area_cleared_ha'] as num?)?.toDouble() ?? 0.0;

        final existing =
            dailyMap[dateStr] ?? TimelineDataPoint(date: DateTime.parse(dateStr));
        dailyMap[dateStr] = TimelineDataPoint(
          date: existing.date,
          dailyCutVolume: existing.dailyCutVolume,
          dailyFillVolume: existing.dailyFillVolume,
          dailyLandClearing: existing.dailyLandClearing + area,
        );
      }

      final sortedDates = dailyMap.keys.toList()..sort();

      // Calculate cumulatives
      double runningCut = 0.0;
      double runningFill = 0.0;
      double runningLand = 0.0;

      final List<TimelineDataPoint> result = [];
      for (final dateStr in sortedDates) {
        final dayData = dailyMap[dateStr]!;
        runningCut += dayData.dailyCutVolume;
        runningFill += dayData.dailyFillVolume;
        runningLand += dayData.dailyLandClearing;

        result.add(
          TimelineDataPoint(
            date: dayData.date,
            dailyCutVolume: dayData.dailyCutVolume,
            dailyFillVolume: dayData.dailyFillVolume,
            dailyLandClearing: dayData.dailyLandClearing,
            cumulativeCutVolume: runningCut,
            cumulativeFillVolume: runningFill,
            cumulativeLandClearing: runningLand,
          ),
        );
      }

      return result;
    } catch (_) {
      return [];
    }
  }
}
