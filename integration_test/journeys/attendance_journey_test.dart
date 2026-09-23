// E2E Critical User Journey: Attendance (STEP-45.4; retargeted to the
// STEP-55.5 batch sheet).
//
// Exercises attendance batch recording through the route-backed
// `/teams/attendance/form` sheet, status selection, inline reason entry,
// correct author/recorder attribution (CF-006/007/009 guards), update
// persistence, and summary card / list view reflection.
//
// STEP-55.5 replaced the pushed `AttendanceFormPage` with the shared
// responsive sheet (`AttendanceFormSheet`) and its per-crew
// `AttendanceCrewCard`; the roster now loads directly from the auth
// repository (no debug seeder), and the reason is an inline field rather
// than a remarks dialog.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_state.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_sheet.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_crew_card.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mine_flow/main.dart' as app_main;

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Attendance Journey (STEP-45.4 / STEP-55.5)', () {
    testWidgets(
      'login, batch-record attendance, assert correct author attribution, edit, and reflect in list E2E',
      (tester) async {
        if (!isStagingConfigured) {
          recordE2eSkipped(
            'attendance_journey_test: staging credentials absent',
          );
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

        recordE2eExecuted('attendance_journey_test');

        final storage = SecureStorageService();
        await storage.clearAll();

        // 1. Boot app and log in.
        await pumpApp(tester);
        await loginAsStagingUser(tester);

        expect(authCubit?.state.status, AuthStatus.authenticated);
        final currentUserIdVal = currentUserId();
        expect(currentUserIdVal, isNotNull);
        expect(currentUserIdVal, isNotEmpty);

        // 2. Navigate to Attendance screen.
        appRouter.go(AppRoutes.attendance);
        await tester.pumpAndSettle();

        expect(find.byType(AttendanceScreen), findsOneWidget);
        expect(find.byType(AttendanceSummaryCard), findsOneWidget);

        // 3. Open the batch sheet via the "Input Absensi" action button.
        // STEP-55.11 E2E residual: the list FAB was migrated from Material
        // `FloatingActionButton` to a ForUI `FButton` in a `Positioned`
        // overlay (STEP-55.5); target its stable key rather than the widget
        // type + label.
        final inputAbsensiFab = find.byKey(const Key('add_attendance_btn'));
        expect(inputAbsensiFab, findsOneWidget);
        await tester.tap(inputAbsensiFab);
        await tester.pumpAndSettle();

        // The route-hosted sheet loads the real site roster over the network;
        // wait in slices until the crew cards render instead of a single
        // settle.
        for (
          var i = 0;
          i < 150 && tester.widgetList(find.byType(AttendanceCrewCard)).isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        expect(find.byType(AttendanceFormSheet), findsOneWidget);
        expect(find.byType(AttendanceCrewCard), findsWidgets);

        // Pick a crew member whose attendance row for today does not exist
        // yet in the repository. Leftover rows from an earlier run of this
        // journey — written before STEP-48.20's UTC-stamp fix, carrying a
        // phantom-future updated_at — would win the sync last-write-wins
        // comparison and silently revert the edit. Rows written after the fix
        // converge correctly, so repeated runs stay deterministic.
        final now = DateTime.now();
        final existingToday = await app_main.appServices!.attendanceRepository
            .getAttendanceForDate(now);
        final takenUserIds = existingToday.map((r) => r.userId).toSet();

        final crewCards = tester
            .widgetList<AttendanceCrewCard>(find.byType(AttendanceCrewCard))
            .toList();
        AttendanceCrewCard? targetCard;
        for (final card in crewCards) {
          if (!takenUserIds.contains(card.draft.userId)) {
            targetCard = card;
            break;
          }
        }
        // Fall back to the first card when every crew member already has a
        // row for today — rows written by a fixed build converge under
        // last-write-wins, so the flow still holds.
        targetCard ??= crewCards.first;
        final targetUserId = targetCard.draft.userId;
        final targetCardFinder = find.byWidgetPredicate(
          (w) => w is AttendanceCrewCard && w.draft.userId == targetUserId,
        );

        // 4b. STEP-55.11: the sheet loads the full site roster and submit
        // validation requires EVERY crew member to carry a status (spec §4.4
        // item 8 — "Setiap kru harus memiliki status kehadiran sebelum
        // disimpan"). A journey that marks only one member sick is
        // legitimately refused. The sheet's bulk action marks every unset
        // member Present, so use it, then flip the single target to sick
        // (which requires a reason) — the resulting batch is valid.
        final bulkPresentBtn = find.descendant(
          of: find.byType(AttendanceFormSheet),
          matching: find.widgetWithText(
            FButton,
            AppLocalizations.of(
              tester.element(targetCardFinder.first),
            ).attendanceBulkMarkPresent,
          ),
        );
        expect(bulkPresentBtn, findsOneWidget);
        await tester.ensureVisible(bulkPresentBtn);
        await tester.tap(bulkPresentBtn);
        await tester.pumpAndSettle();

        // 4c. Set the target crew member's status to sick — scoped to the
        // target card: with leftover rows rendered, an unscoped
        // find.text('Sakit').first can hit another card's chip.
        //
        // STEP-55.11: the chip labels are localized
        // (attendanceStatusSick / attendanceStatusLeave), not hardcoded
        // strings, so resolve them from the active locale. The app defaults
        // to 'en' and the journey never sets a locale, so the rendered label
        // is the active-locale value.
        //
        // Scope the lookup to the target card: the sheet renders one card per
        // crew member, so an unscoped byType(AttendanceCrewCard) is ambiguous
        // — resolve the BuildContext from the target card itself.
        // STEP-55.11: a crew member can appear on more than one rendered card
        // (leftover rows from earlier runs), so this finder is not unique —
        // match the first card with this user rather than expecting exactly
        // one, and resolve the localization context from it.
        final ctx = tester.element(targetCardFinder.first);
        final l10n = AppLocalizations.of(ctx);
        final sickLabel = l10n.attendanceStatusSick;
        final leaveLabel = l10n.attendanceStatusLeave;
        final sakitChoice = find.descendant(
          of: targetCardFinder,
          matching: find.text(sickLabel),
        );
        expect(sakitChoice, findsOneWidget);
        await tester.tap(sakitChoice.first);
        await tester.pumpAndSettle();

        // 5. Enter the required inline reason for that crew member. The
        // remark is unique per run so the step-8 list assertion cannot match
        // a leftover row's remark.
        final uniqueRemark =
            'Izin sakit shift pagi ${DateTime.now().millisecondsSinceEpoch}';
        final reasonField = find.descendant(
          of: targetCardFinder,
          matching: find.byKey(const Key('attendance_reason_field')),
        );
        expect(reasonField, findsOneWidget);
        await tester.enterText(reasonField, uniqueRemark);
        await tester.pumpAndSettle();

        // 6. Save attendance batch. Capture the target row's id right before
        // saving: the sheet reuses an existing row for the crew member when
        // one exists, and read-back assertions must key on THIS record, not
        // on an ambiguous userId match against leftover rows (STEP-48.20
        // re-run).
        final targetRecordId = targetCard.draft.existingRecord?.id;
        // STEP-55.11: the footer button carries a stable key and its label is
        // localized (attendanceSaveCount), so locate it by key rather than
        // text to stay locale-independent.
        final saveBatchBtn = find.byKey(
          const Key('save_attendance_batch_button'),
        );
        expect(saveBatchBtn, findsOneWidget);
        // STEP-55.11: capture the form bloc reference BEFORE the tap. The
        // BlocProvider lives INSIDE AttendanceFormSheet's build (it wraps
        // AttendanceFormSheetView), so the *sheet* element is above the
        // provider; the save button is built inside the provider subtree, so
        // read the bloc from it. A SUCCESSFUL save pops the sheet route in
        // the same frame the success state is emitted, disposing this button
        // — capturing first keeps the read-back working after the close.
        final formBloc = tester
            .element(find.byKey(const Key('save_attendance_batch_button')))
            .read<AttendanceFormBloc>();
        await tester.ensureVisible(saveBatchBtn);
        await tester.tap(saveBatchBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        var invalidDesc = '';
        bool saved = false;
        for (var i = 0; i < 100; i++) {
          if (find
              .byKey(const Key('save_attendance_batch_button'))
              .evaluate()
              .isEmpty) {
            // The sheet popped itself: the sheet's BlocConsumer listener
            // only closes after successMessage is set, so this is a save.
            saved = true;
            break;
          }
          final st = formBloc.state;
          if (st is AttendanceFormLoaded && st.successMessage != null) {
            saved = true;
            break;
          }
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (!saved) {
          final st = formBloc.state;
          final drafts = st is AttendanceFormLoaded ? st.drafts : <dynamic>[];
          // STEP-55.11: on web, `flutter drive` surfaces only the `reason`
          // string in its result JSON (not debugPrint), so the blocked-save
          // diagnostics must ride in the reason or the failure stays opaque.
          invalidDesc =
              'state=${st.runtimeType} '
              'drafts=${drafts.length} '
              'invalid=${drafts.where((d) => d.isInvalidForSubmit).length} '
              'submitting=${st is AttendanceFormLoaded ? st.isSubmitting : false} '
              'validationError=${st is AttendanceFormLoaded ? st.validationError : null} '
              'saveError=${st is AttendanceFormLoaded ? st.saveError : null} '
              'targetStatus=${st is AttendanceFormLoaded ? () {
                      final d = drafts.where((e) => e.userId == targetUserId).firstOrNull;
                      return d == null ? 'ABSENT_DRAFT' : d.status;
                    }() : null} '
              'targetRemarks=${st is AttendanceFormLoaded ? () {
                      final d = drafts.where((e) => e.userId == targetUserId).firstOrNull;
                      return d?.trimmedRemarks;
                    }() : null} '
              'firstInvalid=${st is AttendanceFormLoaded ? st.firstInvalidUserId : null}';
        }
        expect(
          saved,
          isTrue,
          reason: 'batch save must reach the form bloc. $invalidDesc',
        );

        // The sheet pops itself on a successful save, returning to the list.
        // STEP-55.11: the pop is asynchronous relative to the success emit,
        // and on web the shell can take a frame to settle on the branch page,
        // so poll for the list screen rather than asserting it synchronously.
        for (
          var i = 0;
          i < 50 && find.byType(AttendanceScreen).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          find.byType(AttendanceScreen),
          findsOneWidget,
          reason:
              'matchedLocation=${appRouter.routeInformationProvider.value.uri}',
        );

        // 7. Verify persistence and attribution (CF-006/007/009 guards).
        final savedRecords = await app_main.appServices!.attendanceRepository
            .getAttendanceForDate(now);

        expect(savedRecords, isNotEmpty);
        // Assert on the record we actually mutated, keyed by its id — the
        // sheet reuses existing rows when one already exists for the crew
        // member, so a userId key is ambiguous against leftover rows from an
        // earlier run (STEP-48.20 re-run). The fallback keeps the assertion
        // working against a build where the id is not carried through.
        AttendanceRecord findMutated(List<AttendanceRecord> records) {
          if (targetRecordId != null) {
            final byId = records.where((r) => r.id == targetRecordId);
            if (byId.isNotEmpty) return byId.first;
          }
          return records.firstWhere(
            (r) => r.userId == targetUserId,
            orElse: () => throw StateError(
              'Mutated attendance record ($targetUserId) not found in repository',
            ),
          );
        }

        final recordedCrew = findMutated(savedRecords);
        expect(recordedCrew.loggedBy, isNotNull);
        expect(recordedCrew.loggedBy, isNotEmpty);
        expect(recordedCrew.loggedBy, equals(currentUserIdVal));
        expect(recordedCrew.status, AttendanceStatus.sick);
        expect(recordedCrew.remarks, uniqueRemark);

        // 8. Assert AttendanceScreen list reflects the saved record. The
        // unique-per-run remark makes this exact-match-proof against leftover
        // rows from an earlier run. The screen's list renders through the
        // bloc's async refresh, so poll with a bound before scrolling; a poll
        // that expires still fails at the same assertion, so a genuinely lost
        // write stays an honest failure.
        final remarkFinder = find.textContaining(uniqueRemark);
        final attendanceList = find
            .descendant(
              of: find.byType(AttendanceScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        for (var i = 0; i < 50 && remarkFinder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // FScaffold's Stack keeps the FABs above the CustomScrollView, but the
        // saved target row can remain off-screen.
        //
        // STEP-55.11: scrollUntilVisible is what BUILDS the off-screen row — a
        // SliverList only materializes visible children, so a guard on
        // "remarkFinder already built" would skip exactly the scroll it needs.
        // Guard on the scrollable instead: it exists as soon as the list page
        // renders, and scrollUntilVisible then scrolls until the remark row is
        // built and visible. (The earlier inverted guard made the scroll a
        // no-op whenever the row was below the fold — web passed because the
        // list fit the viewport, android's smaller viewport did not.)
        if (attendanceList.evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            remarkFinder,
            300,
            scrollable: attendanceList,
            maxScrolls: 50,
          );
        }
        expect(remarkFinder, findsOneWidget);

        // 8a. Remove focus before re-tapping the FAB. The ForUI toast is
        // top-aligned and does not overlap the bottom action; requiring it to
        // auto-dismiss is invalid under accessible-navigation test settings.
        FocusManager.instance.primaryFocus?.unfocus();
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        // 9. Edit flow: re-open the sheet and change status to 'Izin' (leave).
        // The reason field is required, so supply one; the choice is scoped to
        // the target card like step 4.
        //
        // STEP-55.11: after the batch save the list bloc refreshes
        // asynchronously; the FAB's onPressed is null until AttendanceLoaded
        // lands, so poll for the button before tapping (the first open at
        // step 3 asserts it up front, but the post-save rebuild does not).
        final reopenFab = find.byKey(const Key('add_attendance_btn'));
        for (var i = 0; i < 50 && reopenFab.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(reopenFab, findsOneWidget);
        await tester.tap(reopenFab);
        await tester.pumpAndSettle();

        for (
          var i = 0;
          i < 150 &&
              find
                  .descendant(
                    of: find.byType(AttendanceFormSheet),
                    matching: find.byType(AttendanceCrewCard),
                  )
                  .evaluate()
                  .isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        final formTargetCard = find.descendant(
          of: find.byType(AttendanceFormSheet),
          matching: find.byWidgetPredicate(
            (w) => w is AttendanceCrewCard && w.draft.userId == targetUserId,
          ),
        );
        final formRosterList = find
            .descendant(
              of: find.byType(AttendanceFormSheet),
              matching: find.byType(Scrollable),
            )
            .first;
        // STEP-55.11: only scroll when the target card is already built —
        // scrollUntilVisible's ensureVisible(element(finder)) throws
        // "No element" on a finder that never resolves (the roster load is
        // async). A genuinely missing card reports honestly at the
        // findsOneWidget assertion below.
        if (formTargetCard.evaluate().isNotEmpty) {
          expect(formRosterList, findsOneWidget);
          await tester.scrollUntilVisible(
            formTargetCard,
            300,
            scrollable: formRosterList,
            maxScrolls: 50,
          );
        }
        expect(formTargetCard, findsOneWidget);

        // STEP-55.11: same localized-label fix as the sick choice above —
        // the chip renders attendanceStatusLeave, not a literal 'Izin'.
        final izinChoice = find.descendant(
          of: formTargetCard,
          matching: find.text(leaveLabel),
        );
        expect(izinChoice, findsOneWidget);
        await tester.tap(izinChoice.first);
        await tester.pumpAndSettle();

        final updateReasonField = find.descendant(
          of: formTargetCard,
          matching: find.byKey(const Key('attendance_reason_field')),
        );
        expect(updateReasonField, findsOneWidget);
        await tester.enterText(updateReasonField, 'Izin resmi shift pagi');
        await tester.pumpAndSettle();

        final updateSaveBtn = find.descendant(
          of: find.byType(AttendanceFormSheet),
          matching: find.byKey(const Key('save_attendance_batch_button')),
        );
        for (var i = 0; i < 50 && updateSaveBtn.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(updateSaveBtn, findsOneWidget);
        await tester.tap(updateSaveBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Confirm update in repository — keyed by the same record id as
        // step 7 (userId is ambiguous against leftover rows).
        final updatedRecords = await app_main.appServices!.attendanceRepository
            .getAttendanceForDate(now);
        final updatedCrew = findMutated(updatedRecords);
        expect(updatedCrew.status, AttendanceStatus.leave);
        expect(updatedCrew.loggedBy, equals(currentUserIdVal));
      },
    );
  });
}
