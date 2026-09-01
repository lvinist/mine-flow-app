// E2E Critical User Journey: Attendance (STEP-45.4)
//
// Exercises attendance batch recording, status toggling, remarks editing,
// correct author/recorder attribution (CF-006/007/009 guards), update persistence,
// and summary card / list view reflection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_page.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/crew_roster_item.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/main.dart' as app_main;

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Attendance Journey (STEP-45.4)', () {
    testWidgets(
      'login, create attendance, assert correct author attribution, edit, and reflect in list E2E',
      (tester) async {
        if (!isStagingConfigured) {
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

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

        // 3. Open Attendance Form page via "Input Absensi" FAB.
        final inputAbsensiFab = find.widgetWithText(
          FloatingActionButton,
          'Input Absensi',
        );
        expect(inputAbsensiFab, findsOneWidget);
        await tester.tap(inputAbsensiFab);
        await tester.pumpAndSettle();

        expect(find.byType(AttendanceFormPage), findsOneWidget);

        // If roster is empty, load the default roster. Since STEP-48.20's
        // re-run (48.26 R-6) the seeder loads the REAL site roster
        // (users.id UUIDs) over the network, so wait in slices until the
        // roster renders instead of a single settle.
        final loadDefaultBtn = find.text('Muat Daftar Kru Default (Debug)');
        if (loadDefaultBtn.evaluate().isNotEmpty) {
          await tester.tap(loadDefaultBtn);
          await tester.pump();
          for (
            var i = 0;
            i < 150 && tester.widgetList(find.byType(CrewRosterItem)).isEmpty;
            i++
          ) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          await tester.pumpAndSettle();
        }

        expect(find.byType(CrewRosterItem), findsWidgets);

        // Pick a crew member whose attendance row for today does not exist
        // yet in the repository. Leftover rows from an earlier run of this
        // journey — written before STEP-48.20's UTC-stamp fix, carrying a
        // phantom-future updated_at — would win the sync last-write-wins
        // comparison and silently revert the edit (the re-run logged remote
        // 21:32Z "newer" than a 21:46+07 mutation). Rows written after the
        // fix converge correctly, so repeated runs stay deterministic.
        final now = DateTime.now();
        final existingToday = await app_main.appServices!.attendanceRepository
            .getAttendanceForDate(now);
        final takenUserIds = existingToday.map((r) => r.userId).toSet();

        final rosterItems = tester
            .widgetList<CrewRosterItem>(find.byType(CrewRosterItem))
            .toList();
        CrewRosterItem? targetItem;
        for (final item in rosterItems) {
          if (!takenUserIds.contains(item.record.userId)) {
            targetItem = item;
            break;
          }
        }
        // Fall back to the first item when every crew member already has a
        // row for today — rows written by a fixed build converge under
        // last-write-wins, so the flow still holds.
        targetItem ??= rosterItems.first;
        final targetUserId = targetItem.record.userId;
        final targetItemFinder = find.byWidgetPredicate(
          (w) => w is CrewRosterItem && w.record.userId == targetUserId,
        );

        // 4. Update the target crew member's status to 'Sakit' — scoped to
        // the target item: with leftover rows rendered, an unscoped
        // find.text('Sakit').first can hit another item's chip.
        final sakitChip = find.descendant(
          of: targetItemFinder,
          matching: find.text('Sakit'),
        );
        await tester.tap(sakitChip.first);
        await tester.pumpAndSettle();

        // 5. Add remarks for that crew member. The remark is unique per run
        // so the step-8 list assertion cannot match a leftover row's remark.
        final uniqueRemark =
            'Izin sakit shift pagi ${DateTime.now().millisecondsSinceEpoch}';
        final editRemarksBtn = find.descendant(
          of: targetItemFinder,
          matching: find.byTooltip('Tambah Catatan / Remarks'),
        );
        await tester.tap(editRemarksBtn.first);
        await tester.pumpAndSettle();

        // Enter text into the remarks dialog input using EditableText finder.
        final remarksEditable = find
            .descendant(
              of: find.byType(FDialog),
              matching: find.byType(EditableText),
            )
            .first;
        await tester.enterText(remarksEditable, uniqueRemark);
        await tester.pumpAndSettle();

        final simpanDialogBtn = find.descendant(
          of: find.byType(FDialog),
          matching: find.widgetWithText(FButton, 'Simpan'),
        );
        await tester.tap(simpanDialogBtn);
        await tester.pumpAndSettle();

        // 6. Save attendance batch. Capture the target row's id right before
        // saving: the form reuses an existing row for the crew member when
        // one exists, and read-back assertions must key on THIS record, not
        // on an ambiguous userId match against leftover rows (STEP-48.20
        // re-run).
        final renderedTarget = tester.widget<CrewRosterItem>(
          find.byWidgetPredicate(
            (w) => w is CrewRosterItem && w.record.userId == targetUserId,
          ),
        );
        final targetRecordId = renderedTarget.record.id;
        final saveBatchBtn = find.textContaining('Simpan Absensi');
        expect(saveBatchBtn, findsOneWidget);
        await tester.tap(saveBatchBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 7. Verify persistence and attribution (CF-006/007/009 guards).
        final savedRecords = await app_main.appServices!.attendanceRepository
            .getAttendanceForDate(now);

        expect(savedRecords, isNotEmpty);
        // Assert on the record we actually mutated, keyed by its id — the
        // form reuses existing rows when one already exists for the crew
        // member, so a userId key is ambiguous against leftover rows from an
        // earlier run (STEP-48.20 re-run). The fallback keeps the assertion
        // working against a build where the id is not carried through.
        AttendanceRecord findMutated(List<AttendanceRecord> records) {
          final byId = records.where((r) => r.id == targetRecordId);
          if (byId.isNotEmpty) return byId.first;
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
        // unique-per-run remark makes this exact-match-proof against
        // leftover rows from an earlier run.
        expect(find.byType(AttendanceScreen), findsOneWidget);
        expect(find.textContaining(uniqueRemark), findsOneWidget);

        // 9. Edit flow: Re-open form and change status to 'Izin' (Leave) —
        // chip scoped to the target item, like step 4.
        await tester.tap(
          find.widgetWithText(FloatingActionButton, 'Input Absensi'),
        );
        await tester.pumpAndSettle();

        final izinChip = find.descendant(
          of: targetItemFinder,
          matching: find.text('Izin'),
        );
        await tester.tap(izinChip.first);
        await tester.pumpAndSettle();

        final updateSaveBtn = find.textContaining('Simpan Absensi');
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
