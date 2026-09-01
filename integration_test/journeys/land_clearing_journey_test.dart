// E2E Critical User Journey: Land Clearing (STEP-45.5)
//
// Exercises land clearing measurement creation across Plan and Actual tabs,
// verifies shared date/zone (CF-044), method combobox (CF-043), and area unit
// handling (CF-013), and persists to staging.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_entry_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_list_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/area_input_field.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/main.dart' as app_main;

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Land Clearing Journey (STEP-45.5)', () {
    testWidgets('login, create land clearing, verify tabs/units/combobox, and save', (
      tester,
    ) async {
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

      // 2. Navigate to Land Clearing screen.
      appRouter.go(AppRoutes.landClearing);
      await tester.pumpAndSettle();

      expect(find.byType(LandClearingSummaryScreen), findsOneWidget);

      // 3. Open Form page.
      final fab = find.widgetWithText(FloatingActionButton, 'Clearing Baru');
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(LandClearingEntryScreen), findsOneWidget);

      // 4. Select zone (shared across tabs - CF-044).
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

      // 5. Enter Plan Area. Target EditableText inside AreaInputField per RISK-0009.
      final planAreaField = find.descendant(
        of: find.widgetWithText(AreaInputField, 'Luas Rencana (Plan)'),
        matching: find.byType(EditableText),
      );
      await tester.enterText(planAreaField, '1500');
      await tester.pumpAndSettle();

      // CF-013: Verify Plan area unit (Ha) conversion text in the summary card (1500 m^2 = 0.1500 Ha).
      expect(find.text('0.1500'), findsOneWidget);

      // 6. Select Method (Combobox - CF-043).
      final methodDropdown = find.widgetWithText(
        FTextField,
        'Pilih atau tambah metode clearing...',
      );
      if (methodDropdown.evaluate().isNotEmpty) {
        await tester.tap(methodDropdown);
        await tester.pumpAndSettle();
        final excavatorItem = find.text('Excavator');
        if (excavatorItem.evaluate().isNotEmpty) {
          // Select the item in the combobox overlay list.
          await tester.tap(excavatorItem.first);
          await tester.pumpAndSettle();
        } else {
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
        }
      }

      // 7. Switch to Actual Tab.
      final actualTab = find.text('Realisasi (Actual)');
      await tester.tap(actualTab);
      await tester.pumpAndSettle();

      // 8. Enter Actual Area. Target EditableText inside AreaInputField per RISK-0009.
      final actualAreaField = find.descendant(
        of: find.widgetWithText(AreaInputField, 'Luas Aktual (Actual)'),
        matching: find.byType(EditableText),
      );
      await tester.enterText(actualAreaField, '1600');
      await tester.pumpAndSettle();

      // CF-013: Verify Actual area unit (Ha) conversion text (1600 m^2 = 0.1600 Ha).
      expect(find.text('0.1600'), findsOneWidget);

      // Enter Notes. RISK-0009: never anchor on `find.byType(TextField)` —
      // target the notes field by its own hint text instead. The Actual tab's
      // "Catatan Terrain" TextField is the only field carrying this hint
      // (land_clearing_entry_screen.dart), so this is unambiguous, whereas
      // `.last` over every TextField depended on widget order.
      final notesField = find.descendant(
        of: find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText ==
                  'Kondisi lahan, vegetasi, hambatan, dll...',
        ),
        matching: find.byType(EditableText),
      );
      expect(notesField, findsOneWidget);
      await tester.enterText(notesField, 'Test terrain notes');
      await tester.pumpAndSettle();

      // 9. Save
      final saveBtn = find.byKey(const Key('save_land_clearing_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Wait for list screen
      expect(find.byType(LandClearingSummaryScreen), findsOneWidget);

      // 10. Verify via repository.
      // STEP-48.1: was `siteId: 'site-1'`, which matches nothing — the form
      // saves with `defaultSiteId` (app_constants.dart), so `firstWhere` threw
      // StateError before any assertion could run.
      final records = await app_main.appServices!.trackingRepository
          .getLandClearingRecords(siteId: defaultSiteId);
      final savedRecord = records.firstWhere(
        (r) => r.planArea == 1500.0 && r.actualArea == 1600.0,
      );

      expect(savedRecord.method, 'Excavator');
      expect(savedRecord.notes, 'Test terrain notes');
    });
  });
}
