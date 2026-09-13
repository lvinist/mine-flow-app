import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';

class MockDailyLogRepository extends Mock implements DailyLogRepository {}

class FakeDailyLog extends Fake implements DailyLog {}

void main() {
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  late MockDailyLogRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeDailyLog());
  });

  setUp(() {
    mockRepository = MockDailyLogRepository();
  });

  // STEP-48.23 re-run 5 (48.26 gate-5 R-1) — the bloc-tier concurrency pin.
  //
  // Web CI: daily_log_journey_test.dart:136 read `Expected:
  // LogStatus.submitted / Actual: LogStatus.draft` (classified by 48.26
  // re-run 4 as an app defect (concurrency), not a flake). Mechanism: the
  // form's 500 ms debounce (daily_log_form_screen.dart:95-101) is never
  // cancelled by the submit tap (:389-405), and bloc 9.x processes events
  // concurrently by default (no transformer in DailyLogBloc's constructor),
  // so a late AutoSaveDraftEvent starts while _onSubmitDailyLog is still
  // between its two awaits. The autosave handler's only guard was
  // `log.status != draft` — but the submit handler holds the log at `draft`
  // in state across both awaits — so the late autosave passed the guard and
  // reached the repository mid-submit.
  //
  // The repository tier pins (test/unit/daily_log_repository_test.dart,
  // 'STEP-48.23 re-run 5') prove the persistence contract: a late autosave
  // must not demote the stored row. This pin proves the bloc never forwards
  // a DRAFT-status autosave once submit has started — the guard the
  // sequential failure-B pin structurally could not exercise.
  blocTest<DailyLogBloc, DailyLogState>(
    'a mid-submit AutoSaveDraftEvent is dropped, not forwarded to the '
    'repository as a draft write (STEP-48.23 re-run 5 R-1)',
    build: () {
      when(() => mockRepository.autoSaveDraft(any())).thenAnswer((_) async {});
      when(() => mockRepository.submitDailyLog(any())).thenAnswer((_) async {});
      return DailyLogBloc(repository: mockRepository);
    },
    seed: () => DailyLogFormState(
      log: DailyLog(
        id: 'log-001',
        siteId: defaultSiteId,
        foremanId: 'foreman-1',
        logDate: DateTime(2026, 7, 18),
        status: LogStatus.draft,
        summary: 'draft before the tap',
        // STEP-55.6: submit requires an answered hazard question; the pin
        // seeds an explicit none assessment so it still exercises the
        // submit path (not the new validation guard).
        hazard: const HazardAssessment.none(),
      ),
    ),
    act: (bloc) async {
      bloc.add(const SubmitDailyLogEvent());
      // The debounced autosave fires mid-submit: with concurrent event
      // processing this handler runs while _onSubmitDailyLog is between its
      // two awaits (state still holds the pre-submit draft log).
      bloc.add(const AutoSaveDraftEvent());
    },
    expect: () => [
      // Submit's first emission. After the fix, these are the ONLY two
      // emissions: the mid-submit autosave is dropped at the handler guard.
      isA<DailyLogFormState>().having(
        (s) => s.isSubmitting,
        'isSubmitting',
        true,
      ),
      isA<DailyLogFormState>()
          .having((s) => s.isSubmitted, 'isSubmitted', true)
          .having((s) => s.log.status, 'status', LogStatus.submitted),
      // Pre-fix (RED, recorded): the concurrent autosave interleaved two
      // extra emissions between these — isSavingDraft:true ('Menyimpan
      // draft...') then isSaved:true ('Draft tersimpan otomatis') — and
      // forwarded a draft-status autoSaveDraft() to the repository, the
      // write that demoted the submitted row on web CI (:136).
    ],
    verify: (_) {
      verify(() => mockRepository.submitDailyLog('log-001')).called(1);
      // Exactly the autosave the submit flow itself makes (with the
      // submitted entity) may pass — never one carrying the stale draft.
      verifyNever(
        () => mockRepository.autoSaveDraft(
          any(
            that: isA<DailyLog>().having(
              (l) => l.status,
              'status',
              LogStatus.draft,
            ),
          ),
        ),
      );
    },
  );

  // ---------------------------------------------------------------------
  // STEP-55.6 — review workflow, hazard validation, supervisor approval.
  // ---------------------------------------------------------------------

  final tLogs = [
    DailyLog(
      id: 'log-001',
      siteId: defaultSiteId,
      foremanId: 'foreman-1',
      logDate: DateTime(2026, 9, 12),
      status: LogStatus.draft,
      summary: 'Draft log',
      hazard: const HazardAssessment.none(),
    ),
    DailyLog(
      id: 'log-002',
      siteId: defaultSiteId,
      foremanId: 'foreman-2',
      logDate: DateTime(2026, 9, 12),
      status: LogStatus.submitted,
      summary: 'Submitted log',
      hazard: const HazardAssessment(
        state: HazardState.present,
        severity: HazardSeverity.high,
      ),
    ),
    DailyLog(
      id: 'log-003',
      siteId: defaultSiteId,
      foremanId: 'foreman-1',
      logDate: DateTime(2026, 9, 11),
      status: LogStatus.approved,
      summary: 'Approved log',
      hazard: const HazardAssessment.none(),
    ),
  ];

  void stubLoad() {
    when(
      () => mockRepository.getDailyLogs(
        date: any(named: 'date'),
        siteId: any(named: 'siteId'),
        foremanId: any(named: 'foremanId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => tLogs);
  }

  group('STEP-55.6 review list', () {
    blocTest<DailyLogBloc, DailyLogState>(
      'load derives per-tab counts and defaults to the requested tab',
      build: () {
        stubLoad();
        return DailyLogBloc(repository: mockRepository);
      },
      act: (bloc) => bloc
        ..add(const LoadDailyLogsListEvent(siteId: defaultSiteId))
        ..add(const SelectDailyLogTabEvent(DailyLogReviewTab.needsApproval)),
      expect: () => [
        isA<DailyLogLoading>(),
        isA<DailyLogsLoaded>()
            .having((s) => s.tabCounts[DailyLogReviewTab.all], 'count all', 3)
            .having(
              (s) => s.tabCounts[DailyLogReviewTab.draft],
              'count draft',
              1,
            )
            .having(
              (s) => s.tabCounts[DailyLogReviewTab.needsApproval],
              'count submitted',
              1,
            )
            .having(
              (s) => s.tabCounts[DailyLogReviewTab.approved],
              'count approved',
              1,
            ),
        isA<DailyLogsLoaded>()
            .having((s) => s.activeTab, 'tab', DailyLogReviewTab.needsApproval)
            .having((s) => s.logs.length, 'visible', 1)
            .having((s) => s.logs.first.id, 'visible id', 'log-002'),
      ],
    );

    blocTest<DailyLogBloc, DailyLogState>(
      'apply filters preserves the active tab',
      build: () {
        stubLoad();
        return DailyLogBloc(repository: mockRepository);
      },
      seed: () => DailyLogsLoaded(
        logs: tLogs,
        siteId: defaultSiteId,
        activeTab: DailyLogReviewTab.draft,
        tabCounts: const {},
      ),
      act: (bloc) => bloc.add(
        const ApplyDailyLogFiltersEvent(
          zoneId: 'zone-9',
          foremanId: 'foreman-1',
        ),
      ),
      expect: () => [
        isA<DailyLogsLoaded>()
            .having((s) => s.activeTab, 'tab kept', DailyLogReviewTab.draft)
            .having((s) => s.zoneFilter, 'zone', 'zone-9')
            .having((s) => s.foremanFilter, 'foreman', 'foreman-1'),
      ],
    );

    blocTest<DailyLogBloc, DailyLogState>(
      'approve flow: progress state, repository call, refreshed counts, no duplicate dispatch',
      build: () {
        stubLoad();
        when(
          () => mockRepository.approveDailyLog('log-002', approvedBy: 'sup-1'),
        ).thenAnswer((_) async {});
        return DailyLogBloc(repository: mockRepository);
      },
      seed: () => DailyLogsLoaded(
        logs: tLogs.where((l) => l.status == LogStatus.submitted).toList(),
        siteId: defaultSiteId,
        activeTab: DailyLogReviewTab.needsApproval,
        tabCounts: const {},
      ),
      act: (bloc) async {
        bloc.add(
          const ApproveDailyLogEvent(logId: 'log-002', approvedBy: 'sup-1'),
        );
        // A second tap while the first is in flight must not dispatch twice.
        bloc.add(
          const ApproveDailyLogEvent(logId: 'log-002', approvedBy: 'sup-1'),
        );
        await bloc.close();
      },
      expect: () => [
        // 1. Progress: the approving log id is exposed for busy state.
        isA<DailyLogsLoaded>().having(
          (s) => s.approvingLogId,
          'approving id',
          'log-002',
        ),
        // 2. Reloaded counts with the busy flag cleared (the reload emits a
        // fresh DailyLogsLoaded whose approvingLogId defaults to null; the
        // explicit clear emission is Equatable-identical and deduped).
        isA<DailyLogsLoaded>()
            .having((s) => s.approvingLogId, 'cleared', null)
            .having(
              (s) => s.activeTab,
              'tab kept',
              DailyLogReviewTab.needsApproval,
            )
            .having(
              (s) => s.tabCounts[DailyLogReviewTab.all],
              'counts refreshed',
              3,
            ),
      ],
      verify: (_) {
        verify(
          () => mockRepository.approveDailyLog('log-002', approvedBy: 'sup-1'),
        ).called(1);
      },
    );

    blocTest<DailyLogBloc, DailyLogState>(
      'approve failure retains tab/filters and clears the busy state',
      build: () {
        stubLoad();
        when(
          () => mockRepository.approveDailyLog('log-002', approvedBy: 'sup-1'),
        ).thenThrow(StateError('Only a submitted log can be approved'));
        return DailyLogBloc(repository: mockRepository);
      },
      seed: () => DailyLogsLoaded(
        logs: tLogs,
        siteId: defaultSiteId,
        activeTab: DailyLogReviewTab.needsApproval,
        zoneFilter: 'zone-1',
        tabCounts: const {},
      ),
      act: (bloc) async {
        bloc.add(
          const ApproveDailyLogEvent(logId: 'log-002', approvedBy: 'sup-1'),
        );
        await bloc.close();
      },
      expect: () => [
        isA<DailyLogsLoaded>().having(
          (s) => s.approvingLogId,
          'approving id',
          'log-002',
        ),
        isA<DailyLogsLoaded>().having((s) => s.approvingLogId, 'cleared', null),
        isA<DailyLogError>(),
      ],
    );
  });

  group('STEP-55.6 hazard validation on submit', () {
    blocTest<DailyLogBloc, DailyLogState>(
      'not_assessed hazard blocks submit before any repository call',
      build: () => DailyLogBloc(repository: mockRepository),
      seed: () => DailyLogFormState(
        log: DailyLog(
          id: 'log-9',
          siteId: defaultSiteId,
          foremanId: 'foreman-1',
          logDate: DateTime(2026, 9, 12),
          status: LogStatus.draft,
          summary: 'Valid summary',
          hazard: const HazardAssessment.notAssessed(),
        ),
      ),
      act: (bloc) => bloc.add(const SubmitDailyLogEvent()),
      expect: () => [
        isA<DailyLogFormState>().having(
          (s) => s.errorMessage,
          'error',
          'Assessment bahaya wajib diisi sebelum mengirim log',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockRepository.submitDailyLog(any()));
        verifyNever(() => mockRepository.autoSaveDraft(any()));
      },
    );

    blocTest<DailyLogBloc, DailyLogState>(
      'present hazard without severity blocks submit',
      build: () => DailyLogBloc(repository: mockRepository),
      seed: () => DailyLogFormState(
        log: DailyLog(
          id: 'log-9',
          siteId: defaultSiteId,
          foremanId: 'foreman-1',
          logDate: DateTime(2026, 9, 12),
          status: LogStatus.draft,
          summary: 'Valid summary',
          hazard: const HazardAssessment(state: HazardState.present),
        ),
      ),
      act: (bloc) => bloc.add(const SubmitDailyLogEvent()),
      expect: () => [
        isA<DailyLogFormState>().having(
          (s) => s.errorMessage,
          'error',
          'Pilih tingkat keparahan bahaya',
        ),
      ],
      verify: (_) => verifyNever(() => mockRepository.submitDailyLog(any())),
    );

    blocTest<DailyLogBloc, DailyLogState>(
      'HazardChangedEvent normalizes and updates the form log',
      build: () => DailyLogBloc(repository: mockRepository),
      seed: () => DailyLogFormState(
        log: DailyLog(
          id: 'log-9',
          siteId: defaultSiteId,
          foremanId: 'foreman-1',
          logDate: DateTime(2026, 9, 12),
          status: LogStatus.draft,
          summary: 'Valid summary',
          hazard: const HazardAssessment.notAssessed(),
        ),
      ),
      act: (bloc) => bloc.add(
        const HazardChangedEvent(
          HazardAssessmentChange(
            state: HazardState.present,
            severity: HazardSeverity.critical,
          ),
        ),
      ),
      expect: () => [
        isA<DailyLogFormState>()
            .having((s) => s.log.hazard.state, 'state', HazardState.present)
            .having(
              (s) => s.log.hazard.severity,
              'severity',
              HazardSeverity.critical,
            )
            .having((s) => s.hasUnsavedChanges, 'dirty', true),
      ],
    );
  });
}
