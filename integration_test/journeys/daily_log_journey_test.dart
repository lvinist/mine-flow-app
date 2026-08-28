// E2E Critical User Journey: Daily Logging (STEP-45.4)
//
// Exercises daily log creation with CreatableCombobox zone picker, weather selection,
// required summary and notes fields, submission, author attribution (CF-006/007 guards),
// list visibility, and draft isolation across simulated users (CF-008 guard).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_form_screen.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_list_screen.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/daily_log_card.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/main.dart' as app_main;

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Log Journey (STEP-45.4)', () {
    testWidgets(
      'login, create structured daily log with zone CreatableCombobox, assert attribution (CF-006/007), list visibility, and draft isolation (CF-008) E2E',
      (tester) async {
        if (!isStagingConfigured) {
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

        final storage = SecureStorageService();
        await storage.clearAll();

        // 1. Boot app and log in as staging user.
        await pumpApp(tester);
        await loginAsStagingUser(tester);

        expect(authCubit?.state.status, AuthStatus.authenticated);
        final currentUserIdVal = currentUserId();
        expect(currentUserIdVal, isNotNull);
        expect(currentUserIdVal, isNotEmpty);

        // 2. Navigate to Daily Log screen.
        appRouter.go(AppRoutes.dailyLog);
        await tester.pumpAndSettle();

        expect(find.byType(DailyLogListScreen), findsOneWidget);

        // 3. Tap "Log Baru" FAB to open Daily Log Form.
        final newLogFab = find.byKey(const Key('create_new_daily_log_fab'));
        expect(newLogFab, findsOneWidget);
        await tester.tap(newLogFab);
        await tester.pumpAndSettle();

        expect(find.byType(DailyLogFormScreen), findsOneWidget);

        // 4. Select or create an operational zone using CreatableCombobox (STEP-33).
        final zonePickerFinder = find.byType(ZonePicker);
        expect(zonePickerFinder, findsOneWidget);

        final zoneInputFinder = find.descendant(
          of: zonePickerFinder,
          matching: find.byType(EditableText),
        );
        if (zoneInputFinder.evaluate().isNotEmpty) {
          await tester.enterText(zoneInputFinder.first, 'Pit Alpha');
          await tester.pumpAndSettle();

          final addNewZoneTile = find.text('Tambah "Pit Alpha"');
          if (addNewZoneTile.evaluate().isNotEmpty) {
            await tester.tap(addNewZoneTile);
            await tester.pumpAndSettle();
          }
        }

        // 5. Select weather.
        final weatherChip = find.text('Cerah');
        expect(weatherChip, findsOneWidget);
        await tester.tap(weatherChip);
        await tester.pumpAndSettle();

        // 6. Enter summary text (required field).
        final summaryEditable = find.byWidgetPredicate(
          (w) =>
              w is EditableText &&
              w.maxLines == 4, // Summary field has maxLines: 4
        );
        expect(summaryEditable, findsOneWidget);
        const testSummary =
            'E2E daily log: penggalian pit alpha berjalan sesuai rencana.';
        await tester.enterText(summaryEditable, testSummary);
        await tester.pumpAndSettle();

        // 7. Enter notes / K3 text (optional field).
        final notesEditable = find.byWidgetPredicate(
          (w) =>
              w is EditableText &&
              w.maxLines == 3, // Notes field has maxLines: 3
        );
        expect(notesEditable, findsOneWidget);
        const testNotes = 'E2E catatan K3: nihil insiden, APD lengkap.';
        await tester.enterText(notesEditable, testNotes);
        await tester.pumpAndSettle();

        // 8. Submit daily log.
        final submitBtn = find.byKey(const Key('submit_daily_log_button'));
        expect(submitBtn, findsOneWidget);
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 9. Verify persistence and attribution (CF-006 & CF-007 guards).
        final repoLogs = await app_main.appServices!.dailyLogRepository
            .getDailyLogs(siteId: defaultSiteId);

        final matchingLog = repoLogs.firstWhere(
          (l) => l.summary == testSummary,
          orElse: () =>
              throw StateError('Submitted log not found in repository'),
        );

        // CF-007 guard: author / foremanId is NOT empty, NOT hardcoded, matches authenticated user.
        expect(matchingLog.foremanId, isNotNull);
        expect(matchingLog.foremanId, isNotEmpty);
        expect(matchingLog.foremanId, equals(currentUserIdVal));
        expect(matchingLog.status, LogStatus.submitted);
        expect(matchingLog.notes, testNotes);

        // 10. Verify visibility on DailyLogListScreen (CF-006 guard: not hidden by empty foremanId).
        appRouter.go(AppRoutes.dailyLog);
        await tester.pumpAndSettle();

        expect(find.byType(DailyLogListScreen), findsOneWidget);
        expect(find.byType(DailyLogCard), findsWidgets);
        expect(find.text(testSummary), findsOneWidget);

        // 11. Draft isolation across simulated user switch (CF-008 guard).
        // Save a draft for user A.
        final userADraft = DailyLog(
          id: 'user-a-draft-e2e',
          siteId: defaultSiteId,
          foremanId: currentUserIdVal!,
          logDate: DateTime.now(),
          status: LogStatus.draft,
          summary: 'Draft summary for user A',
        );
        await app_main.appServices!.dailyLogRepository.autoSaveDraft(
          userADraft,
        );

        // Query draft for a different user ID (User B).
        const simulatedUserBId = 'user-b-uuid-simulated';
        final userBDraft = await app_main.appServices!.dailyLogRepository
            .getDraftLogForForeman(
              foremanId: simulatedUserBId,
              date: DateTime.now(),
              siteId: defaultSiteId,
            );

        // Expect User B does NOT receive User A's draft (no cross-user draft leak).
        expect(userBDraft, isNull);
      },
    );
  });
}
