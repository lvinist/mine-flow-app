import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
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
}
