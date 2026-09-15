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
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_sheet.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_crew_card.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
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

        // 3. Open the batch sheet via the "Input Absensi" FAB.
        final inputAbsensiFab = find.widgetWithText(
          FloatingActionButton,
          'Input Absensi',
        );
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

        // 4. Set the target crew member's status to 'Sakit' — scoped to the
        // target card: with leftover rows rendered, an unscoped
        // find.text('Sakit').first can hit another card's chip.
        final sakitChoice = find.descendant(
          of: targetCardFinder,
          matching: find.text('Sakit'),
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
        final saveBatchBtn = find.textContaining('Simpan Absensi');
        expect(saveBatchBtn, findsOneWidget);
        await tester.tap(saveBatchBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // The sheet pops itself on a successful save, returning to the list.
        expect(find.byType(AttendanceScreen), findsOneWidget);

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
        // saved target row can remain off-screen; scroll the list until the
        // persisted unique remark is built before asserting it.
        if (remarkFinder.evaluate().isEmpty) {
          expect(attendanceList, findsOneWidget);
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
        await tester.tap(
          find.widgetWithText(FloatingActionButton, 'Input Absensi'),
        );
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
        if (formTargetCard.evaluate().isEmpty) {
          expect(formRosterList, findsOneWidget);
          await tester.scrollUntilVisible(
            formTargetCard,
            300,
            scrollable: formRosterList,
            maxScrolls: 50,
          );
        }
        expect(formTargetCard, findsOneWidget);

        final izinChoice = find.descendant(
          of: formTargetCard,
          matching: find.text('Izin'),
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
          matching: find.textContaining('Simpan Absensi'),
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
