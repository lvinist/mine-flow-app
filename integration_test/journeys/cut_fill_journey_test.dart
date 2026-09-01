// E2E Critical User Journey: Cut/Fill (STEP-45.5)
//
// Exercises cut/fill measurement creation, persistence to staging, edit (including
// zero/negative elevation guards CF-035/040), and asserts current documented volume semantics.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/tracking/presentation/pages/cut_fill_form_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/cut_fill_list_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/volume_input_field.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/main.dart' as app_main;

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cut/Fill Journey (STEP-45.5)', () {
    testWidgets(
      'login, create cut/fill with BCM/LCM, edit with negative elevation, and verify current semantics',
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

        // 2. Navigate to Cut/Fill screen.
        appRouter.go(AppRoutes.cutFill);
        await tester.pumpAndSettle();

        expect(find.byType(CutFillListScreen), findsOneWidget);

        // 3. Open Cut/Fill Form page.
        final fab = find.widgetWithText(
          FloatingActionButton,
          'Pengukuran Baru',
        );
        await tester.tap(fab);
        await tester.pumpAndSettle();

        expect(find.byType(CutFillFormScreen), findsOneWidget);

        // 4. Select zone (assuming first zone is 'Pit A' or similar, we just tap the combobox).
        final zonePickerDropdown = find.text('Pilih Zona Operasional...');
        if (zonePickerDropdown.evaluate().isNotEmpty) {
          await tester.tap(zonePickerDropdown);
          await tester.pumpAndSettle();

          final firstZoneItem = find.descendant(
            of: find.byType(ListView),
            matching: find.byType(InkWell).at(0),
          );
          if (firstZoneItem.evaluate().isNotEmpty) {
            await tester.tap(firstZoneItem);
            await tester.pumpAndSettle();
          } else {
            // Dismiss if empty
            await tester.tapAt(const Offset(10, 10));
            await tester.pumpAndSettle();
          }
        }

        // 5. Fill Volume Inputs (BCM and LCM). Target EditableText inside VolumeInputField per RISK-0009.
        final bcmField = find.descendant(
          of: find.widgetWithText(VolumeInputField, 'Volume (BCM)'),
          matching: find.byType(EditableText),
        );
        final lcmField = find.descendant(
          of: find.widgetWithText(VolumeInputField, 'Volume (LCM)'),
          matching: find.byType(EditableText),
        );

        await tester.enterText(bcmField, '100');
        await tester.enterText(lcmField, '50');
        await tester.pumpAndSettle();

        // 6. Select Material Type through the ForUI combobox.
        final materialField = find.text('Pilih tipe material');
        await tester.tap(materialField);
        await tester.pumpAndSettle();
        final obItem = find.bySemanticsLabel('OB / Waste');
        await tester.tap(obItem);
        await tester.pumpAndSettle();

        // 7. Verify Net Volume in UI (Current semantics: BCM + LCM / (1 + swell)).
        // Default swell factor is 0.25 -> 100 + 50/1.25 = 140.0
        expect(find.textContaining('140.0 m³'), findsOneWidget);

        // 8. Save
        final saveBtn = find.byKey(const Key('save_cut_fill_button'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Wait for list screen
        expect(find.byType(CutFillListScreen), findsOneWidget);

        // 9. Edit record to add negative elevation.
        // Tap the top/first matching cut/fill record card in the list to open the edit screen.
        final firstRecordCard = find.textContaining('140.0 m³').first;
        await tester.tap(firstRecordCard);
        await tester.pumpAndSettle();

        expect(find.byType(CutFillFormScreen), findsOneWidget);

        final elevationField = find.descendant(
          of: find.widgetWithText(FCard, 'Perubahan Elevasi (opsional)'),
          matching: find.byType(EditableText),
        );
        await tester.enterText(elevationField, '-2.5');
        await tester.pumpAndSettle();

        final saveBtn2 = find.byKey(const Key('save_cut_fill_button'));
        await tester.ensureVisible(saveBtn2);
        await tester.tap(saveBtn2);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(CutFillListScreen), findsOneWidget);

        // 10. Assert current semantics explicitly on the repository data.
        // STEP-48.1: was `siteId: 'site-1'`, which matches nothing — the form
        // saves with `defaultSiteId` (app_constants.dart), so `firstWhere` threw
        // StateError before any assertion could run.
        final records = await app_main.appServices!.trackingRepository
            .getCutFillRecords(siteId: defaultSiteId);
        final savedRecord = records.firstWhere(
          (r) => r.bcmVolume == 100.0 && r.lcmVolume == 50.0,
        );

        expect(savedRecord.materialType, 'OB / Waste');
        expect(savedRecord.elevationChange, -2.5);
        expect(savedRecord.netVolume, closeTo(140.0, 0.01));
      },
    );
  });
}
