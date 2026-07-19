import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class FakeLandClearingRecord extends Fake implements LandClearingRecord {}

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';
  late MockTrackingRepository mockRepository;
  late LandClearingBloc landClearingBloc;

  setUpAll(() {
    registerFallbackValue(FakeLandClearingRecord());
  });

  setUp(() {
    mockRepository = MockTrackingRepository();
    landClearingBloc = LandClearingBloc(repository: mockRepository);
  });

  tearDown(() {
    landClearingBloc.close();
  });

  group('LoadLandClearingRecordsEvent', () {
    final tRecords = [
      LandClearingRecord(
        id: 'lc-001',
        siteId: defaultSiteId,
        zoneId: 'zone-east',
        areaClearedM2: 25000.0,
        clearingMethod: 'Bulldozer',
        clearingDate: DateTime(2026, 7, 18),
        clearedBy: 'crew-01',
      ),
      LandClearingRecord(
        id: 'lc-002',
        siteId: defaultSiteId,
        zoneId: 'zone-west',
        areaClearedM2: 10000.0,
        clearingMethod: 'Manual',
        clearingDate: DateTime(2026, 7, 19),
        clearedBy: 'crew-02',
      ),
    ];

    blocTest<LandClearingBloc, LandClearingState>(
      'emits [LandClearingLoading, LandClearingRecordsLoaded] with aggregated area total',
      build: () {
        when(
          () => mockRepository.getLandClearingRecords(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => tRecords);

        return landClearingBloc;
      },
      act: (bloc) => bloc.add(const LoadLandClearingRecordsEvent()),
      expect: () => [
        const LandClearingLoading(),
        isA<LandClearingRecordsLoaded>()
            .having((s) => s.records.length, 'has 2 records', equals(2))
            .having(
              (s) => s.totalAreaClearedM2,
              'total area 35000 m2',
              equals(35000.0),
            )
            .having(
              (s) => s.totalAreaClearedHa,
              'total area 3.5 ha',
              equals(3.5),
            ),
      ],
    );

    blocTest<LandClearingBloc, LandClearingState>(
      'emits [LandClearingLoading, LandClearingError] when repository throws',
      build: () {
        when(
          () => mockRepository.getLandClearingRecords(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenThrow(Exception('Network error'));

        return landClearingBloc;
      },
      act: (bloc) => bloc.add(const LoadLandClearingRecordsEvent()),
      expect: () => [
        const LandClearingLoading(),
        isA<LandClearingError>().having(
          (s) => s.message,
          'message contains error',
          contains('Network error'),
        ),
      ],
    );
  });

  group('InitializeLandClearingFormEvent', () {
    blocTest<LandClearingBloc, LandClearingState>(
      'emits [LandClearingLoading, LandClearingFormState] with new blank record',
      build: () => landClearingBloc,
      act: (bloc) => bloc.add(
        const InitializeLandClearingFormEvent(
          siteId: defaultSiteId,
          zoneId: 'zone-east',
          foremanId: 'foreman-01',
        ),
      ),
      expect: () => [
        const LandClearingLoading(),
        isA<LandClearingFormState>()
            .having(
              (s) => s.record.siteId,
              'siteId matches',
              equals(defaultSiteId),
            )
            .having(
              (s) => s.record.zoneId,
              'zoneId matches',
              equals('zone-east'),
            )
            .having((s) => s.record.areaClearedM2, 'area is 0', equals(0.0)),
      ],
    );

    blocTest<LandClearingBloc, LandClearingState>(
      'emits [LandClearingLoading, LandClearingFormState] with existing record when editing',
      build: () => landClearingBloc,
      act: (bloc) => bloc.add(
        InitializeLandClearingFormEvent(
          siteId: defaultSiteId,
          zoneId: 'zone-east',
          foremanId: 'foreman-01',
          existingRecord: LandClearingRecord(
            id: 'lc-edit-001',
            siteId: defaultSiteId,
            zoneId: 'zone-east',
            areaClearedM2: 25000.0,
            clearingDate: DateTime(2026, 7, 18),
          ),
        ),
      ),
      expect: () => [
        const LandClearingLoading(),
        isA<LandClearingFormState>()
            .having(
              (s) => s.record.id,
              'id matches existing',
              equals('lc-edit-001'),
            )
            .having(
              (s) => s.record.areaClearedM2,
              'area is 25000 m2',
              equals(25000.0),
            ),
      ],
    );
  });

  group('Land Clearing Form Field Changes', () {
    blocTest<LandClearingBloc, LandClearingState>(
      'updates area cleared and marks unsaved changes',
      build: () => landClearingBloc,
      seed: () => LandClearingFormState(
        record: LandClearingRecord(
          id: 'lc-001',
          siteId: defaultSiteId,
          zoneId: 'zone-east',
          areaClearedM2: 0.0,
          clearingDate: DateTime(2026, 7, 18),
        ),
      ),
      act: (bloc) => bloc.add(const AreaClearedChangedEvent(25000.0)),
      expect: () => [
        isA<LandClearingFormState>()
            .having(
              (s) => s.record.areaClearedM2,
              'area updated',
              equals(25000.0),
            )
            .having((s) => s.hasUnsavedChanges, 'has unsaved changes', isTrue),
      ],
    );
  });

  group('SaveLandClearingRecordEvent', () {
    blocTest<LandClearingBloc, LandClearingState>(
      'emits saved state when repository succeeds',
      build: () {
        when(
          () => mockRepository.saveLandClearingRecord(any()),
        ).thenAnswer((_) async => {});
        return landClearingBloc;
      },
      seed: () => LandClearingFormState(
        record: LandClearingRecord(
          id: 'lc-001',
          siteId: defaultSiteId,
          zoneId: 'zone-east',
          areaClearedM2: 25000.0,
          clearingDate: DateTime(2026, 7, 18),
        ),
      ),
      act: (bloc) => bloc.add(const SaveLandClearingRecordEvent()),
      expect: () => [
        isA<LandClearingFormState>().having(
          (s) => s.isSaving,
          'isSaving',
          isTrue,
        ),
        isA<LandClearingFormState>()
            .having((s) => s.isSaving, 'done saving', isFalse)
            .having((s) => s.isSaved, 'is saved', isTrue)
            .having((s) => s.successMessage, 'has success message', isNotNull),
      ],
    );

    blocTest<LandClearingBloc, LandClearingState>(
      'emits error state when repository throws',
      build: () {
        when(
          () => mockRepository.saveLandClearingRecord(any()),
        ).thenThrow(Exception('Save failed'));
        return landClearingBloc;
      },
      seed: () => LandClearingFormState(
        record: LandClearingRecord(
          id: 'lc-001',
          siteId: defaultSiteId,
          zoneId: 'zone-east',
          areaClearedM2: 25000.0,
          clearingDate: DateTime(2026, 7, 18),
        ),
      ),
      act: (bloc) => bloc.add(const SaveLandClearingRecordEvent()),
      expect: () => [
        isA<LandClearingFormState>().having(
          (s) => s.isSaving,
          'isSaving',
          isTrue,
        ),
        isA<LandClearingFormState>()
            .having((s) => s.isSaving, 'done saving', isFalse)
            .having((s) => s.isSaved, 'not saved', isFalse)
            .having(
              (s) => s.errorMessage,
              'has error',
              contains('Save failed'),
            ),
      ],
    );
  });

  group('DeleteLandClearingRecordEvent', () {
    blocTest<LandClearingBloc, LandClearingState>(
      'deletes record and reloads list when in loaded state',
      build: () {
        when(
          () => mockRepository.deleteLandClearingRecord(any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockRepository.getLandClearingRecords(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);
        return landClearingBloc;
      },
      seed: () => const LandClearingRecordsLoaded(records: []),
      act: (bloc) => bloc.add(const DeleteLandClearingRecordEvent('lc-001')),
      expect: () => [
        isA<LandClearingLoading>(),
        isA<LandClearingRecordsLoaded>(),
      ],
    );

    blocTest<LandClearingBloc, LandClearingState>(
      'emits error when delete throws',
      build: () {
        when(
          () => mockRepository.deleteLandClearingRecord(any()),
        ).thenThrow(Exception('Delete failed'));
        return landClearingBloc;
      },
      act: (bloc) => bloc.add(const DeleteLandClearingRecordEvent('lc-001')),
      expect: () => [
        isA<LandClearingError>().having(
          (s) => s.message,
          'has delete error',
          contains('Delete failed'),
        ),
      ],
    );
  });
}
