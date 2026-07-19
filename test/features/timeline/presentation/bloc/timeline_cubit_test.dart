import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_data_point.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:mine_flow/features/timeline/presentation/bloc/timeline_cubit.dart';
import 'package:mine_flow/features/timeline/presentation/bloc/timeline_state.dart';

class MockTimelineRepository extends Mock implements TimelineRepository {}

void main() {
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  late MockTimelineRepository mockRepository;
  late TimelineCubit timelineCubit;

  setUp(() {
    mockRepository = MockTimelineRepository();
    timelineCubit = TimelineCubit(
      repository: mockRepository,
      siteId: defaultSiteId,
    );
  });

  tearDown(() {
    timelineCubit.close();
  });

  group('loadData', () {
    final tMilestones = [
      TimelineMilestone(
        id: 'ms-001',
        siteId: defaultSiteId,
        title: 'Land Clearing Phase 1',
        category: TimelineCategory.landClearing,
        targetValue: 100.0,
        actualValue: 45.0,
        startDate: DateTime(2026, 7, 1),
        targetDate: DateTime(2026, 7, 15),
        status: MilestoneStatus.inProgress,
        createdAt: DateTime(2026, 7, 1),
      ),
      TimelineMilestone(
        id: 'ms-002',
        siteId: defaultSiteId,
        title: 'Cut/Fill Zone A',
        category: TimelineCategory.cutFill,
        targetValue: 5000.0,
        actualValue: 5000.0,
        startDate: DateTime(2026, 7, 1),
        targetDate: DateTime(2026, 7, 10),
        status: MilestoneStatus.completed,
        createdAt: DateTime(2026, 7, 1),
      ),
    ];

    final tProgressData = [
      TimelineDataPoint(
        date: DateTime(2026, 7, 1),
        dailyCutVolume: 100.0,
        cumulativeCutVolume: 100.0,
      ),
      TimelineDataPoint(
        date: DateTime(2026, 7, 2),
        dailyCutVolume: 150.0,
        cumulativeCutVolume: 250.0,
      ),
    ];

    blocTest<TimelineCubit, TimelineState>(
      'emits [TimelineLoading, TimelineLoaded] when data loads successfully',
      build: () {
        when(
          () => mockRepository.getMilestones(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
          ),
        ).thenAnswer((_) async => tMilestones);

        when(
          () => mockRepository.getProgressData(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => tProgressData);

        return timelineCubit;
      },
      act: (cubit) => cubit.loadData(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      ),
      expect: () => [
        const TimelineLoading(),
        isA<TimelineLoaded>()
            .having((s) => s.milestones.length, 'has 2 milestones', equals(2))
            .having(
              (s) => s.progressData.length,
              'has 2 progress data points',
              equals(2),
            ),
      ],
    );

    blocTest<TimelineCubit, TimelineState>(
      'emits [TimelineLoading, TimelineLoaded] with empty lists when no data',
      build: () {
        when(
          () => mockRepository.getMilestones(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
          ),
        ).thenAnswer((_) async => []);

        when(
          () => mockRepository.getProgressData(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);

        return timelineCubit;
      },
      act: (cubit) => cubit.loadData(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      ),
      expect: () => [
        const TimelineLoading(),
        isA<TimelineLoaded>()
            .having((s) => s.milestones.isEmpty, 'no milestones', isTrue)
            .having((s) => s.progressData.isEmpty, 'no data points', isTrue),
      ],
    );

    blocTest<TimelineCubit, TimelineState>(
      'emits [TimelineLoading, TimelineError] when repository throws',
      build: () {
        when(
          () => mockRepository.getMilestones(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
          ),
        ).thenThrow(Exception('Network error'));
        return timelineCubit;
      },
      act: (cubit) => cubit.loadData(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      ),
      expect: () => [
        const TimelineLoading(),
        isA<TimelineError>().having(
          (s) => s.message,
          'has error message',
          contains('Network error'),
        ),
      ],
    );
  });
}
