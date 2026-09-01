import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/timeline/data/datasources/timeline_remote_datasource.dart';
import 'package:mine_flow/features/timeline/data/models/timeline_milestone_model.dart';
import 'package:mine_flow/features/timeline/data/repositories/timeline_repository_impl.dart';

class MockTimelineRemoteDataSource implements TimelineRemoteDataSource {
  List<Map<String, dynamic>> progressData = [];

  @override
  Future<List<Map<String, dynamic>>> getProgressData({
    required String siteId,
    String? zoneId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return progressData;
  }

  @override
  Future<TimelineMilestoneModel> createMilestone(
    TimelineMilestoneModel milestone,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteMilestone(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TimelineMilestoneModel>> getMilestones({
    required String siteId,
    String? zoneId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateMilestone(TimelineMilestoneModel milestone) async {
    throw UnimplementedError();
  }
}

void main() {
  late MockTimelineRemoteDataSource mockRemoteDataSource;
  late TimelineRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockTimelineRemoteDataSource();
    repository = TimelineRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  test(
    'getProgressData maps rows keyed with real column names without crashing on null dates',
    () async {
      // Arrange
      mockRemoteDataSource.progressData = [
        {
          'type': 'cut_fill',
          'data': [
            {
              'measured_at': '2026-08-31T10:00:00Z',
              'cut_volume_m3': 100.0,
              'fill_volume_m3': 50.0,
            },
            {
              'measured_at': null,
              'cut_volume_m3': 20.0,
              'fill_volume_m3': 10.0,
            },
          ],
        },
        {
          'type': 'land_clearing',
          'data': [
            {'cleared_at': '2026-08-31T12:00:00Z', 'area_cleared_ha': 2.5},
            {'cleared_at': null, 'area_cleared_ha': 1.0},
          ],
        },
      ];

      // Act
      final result = await repository.getProgressData(
        siteId: 'site-1',
        startDate: DateTime(2026, 8, 30),
        endDate: DateTime(2026, 9, 1),
      );

      // Assert
      expect(result.length, 1); // Only 2026-08-31 should be processed
      expect(result.first.date.year, 2026);
      expect(result.first.date.month, 8);
      expect(result.first.date.day, 31);
      expect(result.first.dailyCutVolume, 100.0);
      expect(result.first.dailyFillVolume, 50.0);
      expect(result.first.dailyLandClearing, 2.5);
      expect(result.first.cumulativeCutVolume, 100.0);
      expect(result.first.cumulativeFillVolume, 50.0);
      expect(result.first.cumulativeLandClearing, 2.5);
    },
  );
}
