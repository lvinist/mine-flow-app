// E2E Critical User Journey: Equipment Checks (STEP-45.6)
//
// Exercises equipment SOP condition check form, serial number validation gate (CF-039),
// non-default checklist state submission (CF-017 guard against all-PASS default),
// condition badge derivation, offline persistence, and history list/filtering reflection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
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
        const testSerial = 'GNSS-TRIMBLE-E2E-99';
        final serialTextField = find.widgetWithText(
          TextField,
          'Nomor Seri Alat / ID Unit',
        );
        expect(serialTextField, findsOneWidget);
        await tester.enterText(serialTextField, testSerial);
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
          await tester.tap(passBtn);
          await tester.pumpAndSettle();
        }

        // Set 5th item ('Kondisi Fisik Pole & Gelembung Nivo') to FAIL
        final failBtn = find.descendant(
          of: checklistCards.at(4),
          matching: find.text('FAIL'),
        );
        await tester.tap(failBtn);
        await tester.pumpAndSettle();

        // Enter failure remark in 5th item's mandatory remark field
        final failureRemarkField = find.descendant(
          of: checklistCards.at(4),
          matching: find.widgetWithText(
            TextField,
            'Catatan Kerusakan / Kendala (Wajib)',
          ),
        );
        expect(failureRemarkField, findsOneWidget);
        const testFailureRemark = 'Nivo pecah, pole sedikit bengkok';
        await tester.enterText(failureRemarkField, testFailureRemark);
        await tester.pumpAndSettle();

        // 7. Enter overall inspection remarks
        final overallRemarksField = find.widgetWithText(
          TextField,
          'Catatan Tambahan Inspeksi',
        );
        expect(overallRemarksField, findsOneWidget);
        const testOverallRemark =
            'E2E test: alat perlu servis sebelum masuk Pit B';
        await tester.enterText(overallRemarksField, testOverallRemark);
        await tester.pumpAndSettle();

        // 8. Verify condition summary badge reflects non-operational / flagged state
        expect(find.byType(ConditionSummaryBadge), findsOneWidget);
        expect(find.textContaining('4/5 Lolos'), findsWidgets);

        // 9. Submit inspection
        final submitBtn = find.textContaining(
          'Simpan Inspeksi SOP (4/5 Lolos)',
        );
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

        // 11. Verify visibility and filter in EquipmentHistoryScreen
        appRouter.go(AppRoutes.equipmentCheck);
        await tester.pumpAndSettle();

        expect(find.byType(EquipmentHistoryScreen), findsOneWidget);
        expect(find.byType(EquipmentCheckCard), findsWidgets);
        expect(find.text(testSerial), findsOneWidget);

        // Filter for flagged checks
        final filterFlaggedBtn = find.byKey(const Key('filter_status_flagged'));
        await tester.tap(filterFlaggedBtn);
        await tester.pumpAndSettle();
        expect(find.text(testSerial), findsOneWidget);

        // Filter for passed checks (savedCheck should not appear)
        final filterPassedBtn = find.byKey(const Key('filter_status_passed'));
        await tester.tap(filterPassedBtn);
        await tester.pumpAndSettle();
        expect(find.text(testSerial), findsNothing);
      },
    );
  });
}
