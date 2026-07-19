import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_state.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class FakeCutFillRecord extends Fake implements CutFillRecord {}

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';
  late MockTrackingRepository mockRepository;
  late CutFillBloc cutFillBloc;

  setUpAll(() {
    registerFallbackValue(FakeCutFillRecord());
  });

  setUp(() {
    mockRepository = MockTrackingRepository();
    cutFillBloc = CutFillBloc(repository: mockRepository);
  });

  tearDown(() {
    cutFillBloc.close();
  });

  group('LoadCutFillRecordsEvent', () {
    final tRecords = [
      CutFillRecord(
        id: 'cf-001',
        siteId: defaultSiteId,
        zoneId: 'zone-a',
        cutVolumeM3: 1500.0,
        fillVolumeM3: 500.0,
        measurementDate: DateTime(2026, 7, 18),
        measuredBy: 'surveyor-01',
      ),
      CutFillRecord(
        id: 'cf-002',
        siteId: defaultSiteId,
        zoneId: 'zone-b',
        cutVolumeM3: 2000.0,
        fillVolumeM3: 1000.0,
        measurementDate: DateTime(2026, 7, 19),
        measuredBy: 'surveyor-01',
      ),
    ];

    blocTest<CutFillBloc, CutFillState>(
      'emits [CutFillLoading, CutFillRecordsLoaded] with aggregated totals when records loaded successfully',
      build: () {
        when(
          () => mockRepository.getCutFillRecords(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => tRecords);

        return cutFillBloc;
      },
      act: (bloc) => bloc.add(const LoadCutFillRecordsEvent()),
      expect: () => [
        const CutFillLoading(),
        isA<CutFillRecordsLoaded>()
            .having((s) => s.records.length, 'has 2 records', equals(2))
            .having((s) => s.totalCutM3, 'total cut 3500', equals(3500.0))
            .having((s) => s.totalFillM3, 'total fill 1500', equals(1500.0))
            .having((s) => s.totalNetM3, 'total net 2000', equals(2000.0)),
      ],
    );

    blocTest<CutFillBloc, CutFillState>(
      'emits [CutFillLoading, CutFillError] when repository throws',
      build: () {
        when(
          () => mockRepository.getCutFillRecords(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenThrow(Exception('Network error'));

        return cutFillBloc;
      },
      act: (bloc) => bloc.add(const LoadCutFillRecordsEvent()),
      expect: () => [
        const CutFillLoading(),
        isA<CutFillError>().having(
          (s) => s.message,
          'message contains error',
          contains('Network error'),
        ),
      ],
    );
  });

  group('InitializeCutFillFormEvent', () {
    blocTest<CutFillBloc, CutFillState>(
      'emits [CutFillLoading, CutFillFormState] with new blank record',
      build: () => cutFillBloc,
      act: (bloc) => bloc.add(
        const InitializeCutFillFormEvent(
          siteId: defaultSiteId,
          zoneId: 'zone-a',
          foremanId: 'foreman-01',
        ),
      ),
      expect: () => [
        const CutFillLoading(),
        isA<CutFillFormState>()
            .having(
              (s) => s.record.siteId,
              'siteId matches',
              equals(defaultSiteId),
            )
            .having((s) => s.record.zoneId, 'zoneId matches', equals('zone-a'))
            .having((s) => s.record.cutVolumeM3, 'cut volume is 0', equals(0.0))
            .having(
              (s) => s.hasUnsavedChanges,
              'no unsaved changes yet',
              isFalse,
            ),
      ],
    );

    blocTest<CutFillBloc, CutFillState>(
      'emits [CutFillLoading, CutFillFormState] with existing record when editing',
      build: () => cutFillBloc,
      act: (bloc) => bloc.add(
        InitializeCutFillFormEvent(
          siteId: defaultSiteId,
          zoneId: 'zone-a',
          foremanId: 'foreman-01',
          existingRecord: CutFillRecord(
            id: 'cf-edit-001',
            siteId: defaultSiteId,
            zoneId: 'zone-a',
            cutVolumeM3: 1000.0,
            fillVolumeM3: 200.0,
            measurementDate: DateTime(2026, 7, 18),
          ),
        ),
      ),
      expect: () => [
        const CutFillLoading(),
        isA<CutFillFormState>()
            .having(
              (s) => s.record.id,
              'id matches existing',
              equals('cf-edit-001'),
            )
            .having(
              (s) => s.record.cutVolumeM3,
              'cut volume is 1000',
              equals(1000.0),
            ),
      ],
    );
  });

  group('Cut/Fill Form Field Changes', () {
    blocTest<CutFillBloc, CutFillState>(
      'updates cut volume and marks unsaved changes',
      build: () => cutFillBloc,
      seed: () => CutFillFormState(
        record: CutFillRecord(
          id: 'cf-001',
          siteId: defaultSiteId,
          zoneId: 'zone-a',
          cutVolumeM3: 0.0,
          fillVolumeM3: 0.0,
          measurementDate: DateTime(2026, 7, 18),
        ),
      ),
      act: (bloc) => bloc.add(const CutVolumeChangedEvent(1500.0)),
      expect: () => [
        isA<CutFillFormState>()
            .having(
              (s) => s.record.cutVolumeM3,
              'cut volume updated',
              equals(1500.0),
            )
            .having((s) => s.hasUnsavedChanges, 'has unsaved changes', isTrue),
      ],
    );

    blocTest<CutFillBloc, CutFillState>(
      'updates fill volume and marks unsaved changes',
      build: () => cutFillBloc,
      seed: () => CutFillFormState(
        record: CutFillRecord(
          id: 'cf-001',
          siteId: defaultSiteId,
          zoneId: 'zone-a',
          cutVolumeM3: 1500.0,
          fillVolumeM3: 0.0,
          measurementDate: DateTime(2026, 7, 18),
        ),
      ),
      act: (bloc) => bloc.add(const FillVolumeChangedEvent(500.0)),
      expect: () => [
        isA<CutFillFormState>().having(
          (s) => s.record.fillVolumeM3,
          'fill volume updated',
          equals(500.0),
        ),
      ],
    );
  });

  group('SaveCutFillRecordEvent', () {
    blocTest<CutFillBloc, CutFillState>(
      'emits saved state when repository succeeds',
      build: () {
        when(
          () => mockRepository.saveCutFillRecord(any()),
        ).thenAnswer((_) async => {});
        return cutFillBloc;
      },
      seed: () => CutFillFormState(
        record: CutFillRecord(
          id: 'cf-001',
          siteId: defaultSiteId,
          zoneId: 'zone-a',
          cutVolumeM3: 1500.0,
          fillVolumeM3: 500.0,
          measurementDate: DateTime(2026, 7, 18),
        ),
      ),
      act: (bloc) => bloc.add(const SaveCutFillRecordEvent()),
      expect: () => [
        isA<CutFillFormState>()
            .having((s) => s.isSaving, 'isSaving', isTrue)
            .having((s) => s.errorMessage, 'no error', isNull),
        isA<CutFillFormState>()
            .having((s) => s.isSaving, 'done saving', isFalse)
            .having((s) => s.isSaved, 'is saved', isTrue)
            .having((s) => s.successMessage, 'success message', isNotNull),
      ],
    );

    blocTest<CutFillBloc, CutFillState>(
      'emits error state when repository throws',
      build: () {
        when(
          () => mockRepository.saveCutFillRecord(any()),
        ).thenThrow(Exception('Save failed'));
        return cutFillBloc;
      },
      seed: () => CutFillFormState(
        record: CutFillRecord(
          id: 'cf-001',
          siteId: defaultSiteId,
          zoneId: 'zone-a',
          cutVolumeM3: 1500.0,
          fillVolumeM3: 500.0,
          measurementDate: DateTime(2026, 7, 18),
        ),
      ),
      act: (bloc) => bloc.add(const SaveCutFillRecordEvent()),
      expect: () => [
        isA<CutFillFormState>().having((s) => s.isSaving, 'isSaving', isTrue),
        isA<CutFillFormState>()
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

  group('DeleteCutFillRecordEvent', () {
    blocTest<CutFillBloc, CutFillState>(
      'deletes record and reloads list when in loaded state',
      build: () {
        when(
          () => mockRepository.deleteCutFillRecord(any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockRepository.getCutFillRecords(
            siteId: any(named: 'siteId'),
            zoneId: any(named: 'zoneId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);
        return cutFillBloc;
      },
      seed: () => const CutFillRecordsLoaded(records: []),
      act: (bloc) => bloc.add(const DeleteCutFillRecordEvent('cf-001')),
      expect: () => [isA<CutFillLoading>(), isA<CutFillRecordsLoaded>()],
    );

    blocTest<CutFillBloc, CutFillState>(
      'emits error when delete throws',
      build: () {
        when(
          () => mockRepository.deleteCutFillRecord(any()),
        ).thenThrow(Exception('Delete failed'));
        return cutFillBloc;
      },
      act: (bloc) => bloc.add(const DeleteCutFillRecordEvent('cf-001')),
      expect: () => [
        isA<CutFillError>().having(
          (s) => s.message,
          'has delete error',
          contains('Delete failed'),
        ),
      ],
    );
  });
}
