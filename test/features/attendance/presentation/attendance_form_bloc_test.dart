import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/domain/entities/user_entity.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_state.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockQueueRepository extends Mock
    implements HiveCacheRepository<SyncQueueItem> {}

/// Form bloc tests (STEP-55.5, master spec §4.4 items 1–2, 5, 8, and the
/// per-record sync truth of item 6 / FC-54.5-007).
void main() {
  const siteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  final date = DateTime(2026, 9, 11);

  late MockAttendanceRepository mockRepository;
  late MockAuthRepository mockAuthRepository;
  late MockSyncQueueManager mockQueueManager;
  late MockQueueRepository mockQueueRepository;

  const roster = [
    UserEntity(
      id: 'a1aaaaaa-1111-4111-8111-111111111111',
      email: 'kru1@mineflow.dev',
      name: 'Alex Supervisor',
      role: 'supervisor',
      siteId: 'site-001',
    ),
    UserEntity(
      id: 'b2bbbbbb-2222-4222-8222-222222222222',
      email: 'kru2@mineflow.dev',
      name: 'Frank Foreman',
      role: 'foreman',
      siteId: 'site-001',
    ),
  ];

  setUpAll(() {
    registerFallbackValue(
      AttendanceRecord(
        id: 'fallback',
        siteId: siteId,
        userId: 'u',
        date: date,
        status: AttendanceStatus.present,
      ),
    );
    registerFallbackValue(<AttendanceRecord>[]);
    registerFallbackValue(
      SyncQueueItem(
        id: 'fallback-item',
        entityType: 'attendance_records',
        action: SyncAction.create,
        payloadJson: const <String, dynamic>{},
        timestamp: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockAttendanceRepository();
    mockAuthRepository = MockAuthRepository();
    mockQueueManager = MockSyncQueueManager();
    mockQueueRepository = MockQueueRepository();

    when(
      () => mockAuthRepository.getSiteRoster(siteId: any(named: 'siteId')),
    ).thenAnswer((_) async => roster);
    when(
      () => mockRepository.getAttendanceForDate(
        any(),
        siteId: any(named: 'siteId'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.saveAttendanceBatch(any()),
    ).thenAnswer((_) async {});
  });

  /// A bloc with no queue wiring (sync truth stays empty).
  AttendanceFormBloc buildBloc() => AttendanceFormBloc(
    repository: mockRepository,
    authRepository: mockAuthRepository,
  );

  /// A bloc wired to a fake queue stream for sync-truth assertions.
  AttendanceFormBloc buildSyncBloc(Stream<List<SyncQueueItem>> queueStream) {
    when(
      () => mockQueueManager.queueRepository,
    ).thenReturn(mockQueueRepository);
    when(() => mockQueueRepository.watchAll()).thenAnswer((_) => queueStream);
    when(() => mockQueueRepository.getAll()).thenReturn(const []);
    when(
      () => mockQueueManager.processQueue(isManual: any(named: 'isManual')),
    ).thenAnswer((_) async {});
    return AttendanceFormBloc(
      repository: mockRepository,
      authRepository: mockAuthRepository,
      syncQueueManager: mockQueueManager,
    );
  }

  group('AttendanceFormStarted — roster draft (spec §4.4 item 1)', () {
    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'fresh roster loads every crew member unset — never pre-marked present',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(AttendanceFormStarted(date: date, siteId: siteId)),
      expect: () => [
        isA<AttendanceFormLoading>(),
        isA<AttendanceFormLoaded>()
            .having((s) => s.drafts.length, 'two roster rows', 2)
            .having(
              (s) => s.drafts.every((d) => d.isUnset),
              'all rows unset',
              isTrue,
            )
            .having((s) => s.crewCount, 'crew count', 2),
      ],
    );

    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'mixed roster: existing record keeps its status, the other stays unset',
      build: () {
        when(
          () => mockRepository.getAttendanceForDate(
            any(),
            siteId: any(named: 'siteId'),
          ),
        ).thenAnswer(
          (_) async => [
            AttendanceRecord(
              id: 'existing-1',
              siteId: siteId,
              userId: 'b2bbbbbb-2222-4222-8222-222222222222',
              date: date,
              status: AttendanceStatus.sick,
              remarks: 'Demam',
            ),
          ],
        );
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(AttendanceFormStarted(date: date, siteId: siteId)),
      expect: () => [
        isA<AttendanceFormLoading>(),
        isA<AttendanceFormLoaded>()
            .having(
              (s) => s.drafts
                  .firstWhere(
                    (d) => d.userId == 'a1aaaaaa-1111-4111-8111-111111111111',
                  )
                  .isUnset,
              'first row unset',
              isTrue,
            )
            .having(
              (s) => s.drafts
                  .firstWhere(
                    (d) => d.userId == 'b2bbbbbb-2222-4222-8222-222222222222',
                  )
                  .status,
              'second row keeps sick',
              AttendanceStatus.sick,
            ),
      ],
    );
  });

  group('Status and reason edits', () {
    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'selecting a status marks the sheet dirty',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AttendanceFormStarted(date: date, siteId: siteId));
        await bloc.stream.firstWhere((s) => s is AttendanceFormLoaded);
        bloc.add(
          const AttendanceFormStatusSelected(
            userId: 'a1aaaaaa-1111-4111-8111-111111111111',
            status: AttendanceStatus.leave,
          ),
        );
      },
      skip: 2,
      expect: () => [
        isA<AttendanceFormLoaded>()
            .having((s) => s.isDirty, 'dirty', isTrue)
            .having(
              (s) => s.drafts
                  .firstWhere(
                    (d) => d.userId == 'a1aaaaaa-1111-4111-8111-111111111111',
                  )
                  .status,
              'status applied',
              AttendanceStatus.leave,
            ),
      ],
    );

    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'explicit reason clearing removes a previously typed reason',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AttendanceFormStarted(date: date, siteId: siteId));
        await bloc.stream.firstWhere((s) => s is AttendanceFormLoaded);
        bloc.add(
          const AttendanceFormStatusSelected(
            userId: 'a1aaaaaa-1111-4111-8111-111111111111',
            status: AttendanceStatus.sick,
          ),
        );
        bloc.add(
          const AttendanceFormRemarksChanged(
            userId: 'a1aaaaaa-1111-4111-8111-111111111111',
            remarks: 'Demam',
          ),
        );
        bloc.add(
          const AttendanceFormRemarksChanged(
            userId: 'a1aaaaaa-1111-4111-8111-111111111111',
            clear: true,
          ),
        );
      },
      skip: 4,
      expect: () => [
        isA<AttendanceFormLoaded>().having(
          (s) => s.drafts
              .firstWhere(
                (d) => d.userId == 'a1aaaaaa-1111-4111-8111-111111111111',
              )
              .remarks,
          'reason cleared',
          isNull,
        ),
      ],
    );
  });

  group('Tandai Semua Masuk — bulk action (spec §4.4 item 2)', () {
    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'marks only still-unset rows present and preserves explicit exceptions',
      build: () {
        when(
          () => mockRepository.getAttendanceForDate(
            any(),
            siteId: any(named: 'siteId'),
          ),
        ).thenAnswer(
          (_) async => [
            AttendanceRecord(
              id: 'existing-1',
              siteId: siteId,
              userId: 'b2bbbbbb-2222-4222-8222-222222222222',
              date: date,
              status: AttendanceStatus.leave,
              remarks: 'Izin',
            ),
          ],
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(AttendanceFormStarted(date: date, siteId: siteId));
        await bloc.stream.firstWhere((s) => s is AttendanceFormLoaded);
        bloc.add(const AttendanceFormBulkMarkPresent());
      },
      skip: 2,
      expect: () => [
        isA<AttendanceFormLoaded>()
            .having(
              (s) => s.drafts
                  .firstWhere(
                    (d) => d.userId == 'a1aaaaaa-1111-4111-8111-111111111111',
                  )
                  .status,
              'unset row became present',
              AttendanceStatus.present,
            )
            .having(
              (s) => s.drafts
                  .firstWhere(
                    (d) => d.userId == 'b2bbbbbb-2222-4222-8222-222222222222',
                  )
                  .status,
              'explicit leave preserved',
              AttendanceStatus.leave,
            ),
      ],
    );

    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'is a no-op when no row is unset',
      build: () {
        when(
          () => mockRepository.getAttendanceForDate(
            any(),
            siteId: any(named: 'siteId'),
          ),
        ).thenAnswer(
          (_) async => [
            AttendanceRecord(
              id: 'e1',
              siteId: siteId,
              userId: 'a1aaaaaa-1111-4111-8111-111111111111',
              date: date,
              status: AttendanceStatus.present,
            ),
            AttendanceRecord(
              id: 'e2',
              siteId: siteId,
              userId: 'b2bbbbbb-2222-4222-8222-222222222222',
              date: date,
              status: AttendanceStatus.absent,
            ),
          ],
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(AttendanceFormStarted(date: date, siteId: siteId));
        await bloc.stream.firstWhere((s) => s is AttendanceFormLoaded);
        bloc.add(const AttendanceFormBulkMarkPresent());
      },
      skip: 2,
      expect: () => <AttendanceFormState>[],
    );
  });

  group('Submit validation (spec §4.4 item 8)', () {
    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'refuses an unset roster and names the first invalid row',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AttendanceFormStarted(date: date, siteId: siteId));
        await bloc.stream.firstWhere((s) => s is AttendanceFormLoaded);
        bloc.add(const AttendanceFormSubmitted(loggedBy: 'foreman-1'));
      },
      skip: 2,
      expect: () => [
        isA<AttendanceFormLoaded>()
            .having(
              (s) => s.firstInvalidUserId,
              'first invalid row set',
              'a1aaaaaa-1111-4111-8111-111111111111',
            )
            .having(
              (s) => s.validationError,
              'status-required message',
              isNotNull,
            ),
      ],
      verify: (_) =>
          verifyNever(() => mockRepository.saveAttendanceBatch(any())),
    );

    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'refuses a leave row with a blank trimmed reason',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AttendanceFormStarted(date: date, siteId: siteId));
        await bloc.stream.firstWhere((s) => s is AttendanceFormLoaded);
        bloc.add(const AttendanceFormBulkMarkPresent());
        bloc.add(
          const AttendanceFormStatusSelected(
            userId: 'a1aaaaaa-1111-4111-8111-111111111111',
            status: AttendanceStatus.leave,
          ),
        );
        bloc.add(
          const AttendanceFormRemarksChanged(
            userId: 'a1aaaaaa-1111-4111-8111-111111111111',
            remarks: '   ',
          ),
        );
        bloc.add(const AttendanceFormSubmitted(loggedBy: 'foreman-1'));
      },
      skip: 5,
      expect: () => [
        isA<AttendanceFormLoaded>()
            .having(
              (s) => s.firstInvalidUserId,
              'invalid row is the blank-reason leave row',
              'a1aaaaaa-1111-4111-8111-111111111111',
            )
            .having(
              (s) => s.validationError,
              'reason-required message',
              isNotNull,
            ),
      ],
      verify: (_) =>
          verifyNever(() => mockRepository.saveAttendanceBatch(any())),
    );

    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'materializes and saves a fully-valid batch',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(AttendanceFormStarted(date: date, siteId: siteId));
        await bloc.stream.firstWhere((s) => s is AttendanceFormLoaded);
        bloc.add(const AttendanceFormBulkMarkPresent());
        bloc.add(const AttendanceFormSubmitted(loggedBy: 'foreman-1'));
      },
      skip: 2,
      expect: () => [
        isA<AttendanceFormLoaded>().having((s) => s.isDirty, 'dirty', isTrue),
        isA<AttendanceFormLoaded>().having(
          (s) => s.isSubmitting,
          'submitting',
          isTrue,
        ),
        isA<AttendanceFormLoaded>()
            .having((s) => s.isSubmitting, 'settled', isFalse)
            .having((s) => s.isDirty, 'clean after save', isFalse)
            .having(
              (s) => s.drafts.every((d) => d.existingRecord != null),
              'every row now has a persisted record',
              isTrue,
            )
            .having((s) => s.successMessage, 'success message', isNotNull),
      ],
      verify: (_) {
        final captured = verify(
          () => mockRepository.saveAttendanceBatch(captureAny()),
        ).captured;
        final records = captured.single as List<AttendanceRecord>;
        expect(records.length, 2);
        // Every persisted record carries a real status (the draft null is
        // materialized into a non-null status at submit).
        expect(
          records.every((r) => AttendanceStatus.values.contains(r.status)),
          isTrue,
        );
        expect(
          records.every((r) => r.loggedBy == 'foreman-1'),
          isTrue,
          reason: 'attribution is stamped on every record',
        );
      },
    );

    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'keeps user input intact when the repository save fails',
      build: () {
        when(
          () => mockRepository.saveAttendanceBatch(any()),
        ).thenThrow(Exception('disk full'));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(AttendanceFormStarted(date: date, siteId: siteId));
        await bloc.stream.firstWhere((s) => s is AttendanceFormLoaded);
        bloc.add(const AttendanceFormBulkMarkPresent());
        bloc.add(const AttendanceFormSubmitted(loggedBy: 'foreman-1'));
      },
      skip: 4,
      expect: () => [
        isA<AttendanceFormLoaded>()
            .having((s) => s.isSubmitting, 'no longer submitting', isFalse)
            .having((s) => s.saveError, 'save error surfaced', isNotNull)
            .having((s) => s.drafts.length, 'input retained', 2),
      ],
    );
  });

  group('Per-record sync truth (spec §4.4 item 6 / FC-54.5-007)', () {
    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'derives queued/syncing/failed/synced from the queue box, keyed by '
      'record id',
      build: () {
        when(
          () => mockRepository.getAttendanceForDate(
            any(),
            siteId: any(named: 'siteId'),
          ),
        ).thenAnswer(
          (_) async => [
            AttendanceRecord(
              id: 'rec-a',
              siteId: siteId,
              userId: 'a1aaaaaa-1111-4111-8111-111111111111',
              date: date,
              status: AttendanceStatus.present,
            ),
          ],
        );
        return buildSyncBloc(const Stream<List<SyncQueueItem>>.empty());
      },
      act: (bloc) async {
        bloc.add(AttendanceFormStarted(date: date, siteId: siteId));
        await bloc.stream.firstWhere((s) => s is AttendanceFormLoaded);
        bloc.add(
          AttendanceFormQueueChanged([
            SyncQueueItem(
              id: 'q1',
              entityType: 'attendance_records',
              action: SyncAction.update,
              payloadJson: {'id': 'rec-a'},
              timestamp: date,
              syncStatus: SyncStatus.failed,
              errorMessage: 'network',
            ),
          ]),
        );
      },
      skip: 2,
      expect: () => [
        isA<AttendanceFormLoaded>().having(
          (s) => s.syncStates['a1aaaaaa-1111-4111-8111-111111111111'],
          'failed sync truth attributed to the record owner',
          AttendanceSyncState.failed,
        ),
      ],
    );

    blocTest<AttendanceFormBloc, AttendanceFormState>(
      'retry re-enqueues the failed item and drains the queue',
      build: () {
        final failed = SyncQueueItem(
          id: 'q1',
          entityType: 'attendance_records',
          action: SyncAction.update,
          payloadJson: {'id': 'rec-a'},
          timestamp: date,
          syncStatus: SyncStatus.failed,
          errorMessage: 'network',
        );
        final bloc = buildSyncBloc(const Stream<List<SyncQueueItem>>.empty());
        when(() => mockQueueRepository.getAll()).thenReturn([failed]);
        when(
          () => mockQueueRepository.put(any(), any()),
        ).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const AttendanceFormRetrySyncRequested(recordId: 'rec-a')),
      expect: () => <AttendanceFormState>[],
      verify: (_) {
        verify(() => mockQueueRepository.put('q1', any())).called(1);
        verify(() => mockQueueManager.processQueue(isManual: true)).called(1);
      },
    );
  });
}
