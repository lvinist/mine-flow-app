// E2E Critical User Journey: Equipment Checks (STEP-45.6)
//
// Exercises equipment SOP condition check form, serial number validation gate (CF-039),
// non-default checklist state submission (CF-017 guard against all-PASS default),
// condition badge derivation, offline persistence, and history list/filtering reflection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_check_form_screen.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_history_screen.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/condition_summary_badge.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_check_card.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/sop_checklist_item_card.dart';
import 'package:mine_flow/main.dart' as app_main;

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Equipment Check Journey (STEP-45.6)', () {
    testWidgets(
      'login, open SOP inspection, submit with genuine non-default checklist state (CF-017) and required serial (CF-039), and reflect in history E2E',
      (tester) async {
        if (!isStagingConfigured) {
          recordE2eSkipped(
            'equipment_check_journey_test: staging credentials absent',
          );
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

        recordE2eExecuted('equipment_check_journey_test');

        final storage = SecureStorageService();
        await storage.clearAll();

        // 1. Boot app and log in as staging user.
        await pumpApp(tester);
        await loginAsStagingUser(tester);

        expect(authCubit?.state.status, AuthStatus.authenticated);
        final currentUserIdVal = currentUserId();
        expect(currentUserIdVal, isNotNull);
        expect(currentUserIdVal, isNotEmpty);

        // 2. Navigate to Equipment Check screen.
        appRouter.go(AppRoutes.equipmentCheck);
        await tester.pumpAndSettle();

        expect(find.byType(EquipmentHistoryScreen), findsOneWidget);

        // 3. Open Equipment Check Form via FAB.
        final newCheckFab = find.byKey(
          const Key('create_new_equipment_check_fab'),
        );
        expect(newCheckFab, findsOneWidget);
        await tester.tap(newCheckFab);
        await tester.pumpAndSettle();

        expect(find.byType(EquipmentCheckFormScreen), findsOneWidget);

        // 4. Assert initial un-answered SOP checklist state (CF-017 guard).
        // Form starts with 5 un-answered items and submit button is disabled.
        expect(find.byType(SopChecklistItemCard), findsNWidgets(5));
        expect(find.textContaining('Jawab semua item SOP'), findsOneWidget);

        // 5. Enter Serial Number (CF-039 guard: serial required).
        //
        // STEP-48.1 / RISK-0009: target the EditableText inside the field rather
        // than the field itself.
        Finder textFieldLabelled(String label) => find.descendant(
          of: find.widgetWithText(FTextField, label),
          matching: find.byType(EditableText),
        );

        // Unique per run so the repository firstWhere cannot match a prior
        // run's row (concurrent CI legs share the staging backend).
        final runId = DateTime.now().microsecondsSinceEpoch;
        final testSerial = 'GNSS-E2E-$runId';
        final serialField = textFieldLabelled('Nomor Seri Alat / ID Unit');
        expect(serialField, findsOneWidget);
        await tester.enterText(serialField, testSerial);
        await tester.pumpAndSettle();

        // 6. Fill Checklist items with a genuine non-default state:
        // Set first 4 items to PASS, and 5th item to FAIL (guards CF-017).
        final checklistCards = find.byType(SopChecklistItemCard);
        expect(checklistCards, findsNWidgets(5));

        for (int i = 0; i < 4; i++) {
          final passBtn = find.descendant(
            of: checklistCards.at(i),
            matching: find.text('PASS'),
          );
          await tester.ensureVisible(passBtn);
          await tester.pumpAndSettle();
          await tester.tap(passBtn);
          await tester.pumpAndSettle();
        }

        // Set 5th item ('Kondisi Fisik Pole & Gelembung Nivo') to FAIL
        final failBtn = find.descendant(
          of: checklistCards.at(4),
          matching: find.text('FAIL'),
        );
        await tester.ensureVisible(failBtn);
        await tester.pumpAndSettle();
        await tester.tap(failBtn);
        await tester.pumpAndSettle();

        // Enter failure remark in 5th item's mandatory remark field
        final failureRemarkField = find.descendant(
          of: checklistCards.at(4),
          matching: textFieldLabelled('Catatan Kerusakan / Kendala (Wajib)'),
        );
        expect(failureRemarkField, findsOneWidget);
        await tester.ensureVisible(failureRemarkField);
        await tester.pumpAndSettle();
        final testFailureRemark = 'Nivo pecah, pole sedikit bengkok (#$runId)';
        await tester.enterText(failureRemarkField, testFailureRemark);
        await tester.pumpAndSettle();

        // 7. Enter overall inspection remarks
        final overallRemarksField = textFieldLabelled(
          'Catatan Tambahan Inspeksi',
        );
        expect(overallRemarksField, findsOneWidget);
        await tester.ensureVisible(overallRemarksField);
        await tester.pumpAndSettle();
        final testOverallRemark =
            'E2E test: alat perlu servis sebelum masuk Pit B (#$runId)';
        await tester.enterText(overallRemarksField, testOverallRemark);
        await tester.pumpAndSettle();

        // 8. Verify condition summary badge reflects non-operational / flagged state.
        //
        // STEP-48.1: the STEP-45 assertion was
        // `expect(find.textContaining('4/5 Lolos'), findsWidgets)`. That is not
        // wrong — the submit button renders 'Simpan Inspeksi SOP (4/5 Lolos)',
        // which contains it — but it is weak: it passes on the button alone and
        // therefore proves nothing about the badge it claims to check. The badge
        // renders '$passedCount dari $totalCount Item SOP Lolos Check'
        // (condition_summary_badge.dart), using "dari" rather than a slash, plus
        // a flagged/operational title. Assert each against its real shape.
        expect(find.byType(ConditionSummaryBadge), findsOneWidget);
        expect(
          find.text('PERLU MAINTENANCE / FLAGGED'),
          findsOneWidget,
          reason: 'one FAIL item must flag the whole check as non-operational',
        );
        expect(find.text('4 dari 5 Item SOP Lolos Check'), findsOneWidget);

        // 9. Submit inspection
        final submitBtn = find.text('Simpan Inspeksi SOP (4/5 Lolos)');
        expect(submitBtn, findsOneWidget);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 10. Verify persistence in repository with genuine non-default state (CF-017)
        final checks = await app_main.appServices!.equipmentCheckRepository
            .getEquipmentChecks(siteId: defaultSiteId);
        final savedCheck = checks.firstWhere(
          (c) => c.serialNumber == testSerial,
          orElse: () =>
              throw StateError('Saved equipment check not found in repository'),
        );

        expect(savedCheck.foremanId, equals(currentUserIdVal));
        expect(savedCheck.equipmentType, EquipmentType.gnss);
        expect(savedCheck.checkType, CheckType.preWork);
        expect(savedCheck.isOperational, isFalse);
        expect(savedCheck.status, CheckStatus.flagged);
        expect(savedCheck.remarks, testOverallRemark);
        expect(savedCheck.checklist.length, 5);

        final failedItem = savedCheck.checklist.firstWhere(
          (i) => i.isPassed == false,
        );
        expect(failedItem.id, 'gnss_level_vial');
        expect(failedItem.remarks, testFailureRemark);

        final passedItems = savedCheck.checklist.where(
          (i) => i.isPassed == true,
        );
        expect(passedItems.length, 4);

        // 11. Verify visibility and filter in EquipmentHistoryScreen.
        //
        // STEP-55.11 RESIDUAL-2 (B4) + follow-up (2026-10-08): on submit the
        // form's success listener closes itself (_handleClose ->
        // context.go(equipmentCheck)); the shared AppResponsiveSheet pop guard
        // (fixed: onPopInvokedWithResult now honors didPop=true) no longer
        // re-opens the discard dialog over history. The correct post-submit
        // behaviour is to WAIT for that pop — never a second appRouter.go().
        // Cross the pop window exactly like the green baseline (2bacca9):
        // pump-cadence poll until the form unmounts, then a fixed 20-frame
        // settling loop so the route's exit transition is fully torn down
        // before the final settle. Removing this loop (b74f341) trips the
        // live-binding semantics rebuild — flutter#189902 '!child.attached'
        // storm, reproduced locally 2026-10-09 on the emulator.
        var formGone = false;
        for (var i = 0; i < 50; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byType(EquipmentCheckFormScreen).evaluate().isEmpty) {
            formGone = true;
            break;
          }
        }
        expect(
          formGone,
          isTrue,
          reason:
              'the equipment-check form sheet never closed after submit — the '
              'submit/persist path regressed (STEP-55.11 RESIDUAL-2 B4)',
        );
        // Let the form route's exit animation finish so its transparent modal
        // barrier is torn down before any tap. pumpAndSettle alone after the
        // widget is gone is not enough — the route's exit transition keeps the
        // barrier mounted a few more frames.
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        expect(find.byType(EquipmentHistoryScreen), findsOneWidget);
        expect(find.byType(EquipmentCheckCard), findsWidgets);
        expect(find.textContaining(testSerial), findsOneWidget);
        // The stale-dirty-discard defect (run 37707666304's absorbed history
        // taps) must stay fixed: no orphan discard dialog after save/pop.
        expect(find.byType(AppDirtyDismissDialog), findsNothing);

        // Filter for flagged checks: a single tap on the filter button must
        // open the panel now that no orphan barrier remains.
        await tester.tap(find.byKey(const Key('equipment_filter_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('filter_status_flagged')), findsOneWidget);
        await tester.tap(find.byKey(const Key('filter_status_flagged')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();
        expect(find.textContaining(testSerial), findsOneWidget);

        // Filter for passed checks (savedCheck should not appear)
        await tester.tap(find.byKey(const Key('equipment_filter_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('filter_status_passed')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();
        expect(find.textContaining(testSerial), findsNothing);
      },
    );
  });
}
