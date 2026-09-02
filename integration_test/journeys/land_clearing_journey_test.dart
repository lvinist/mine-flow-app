// E2E Critical User Journey: Land Clearing (STEP-45.5)
//
// Exercises land clearing measurement creation across Plan and Actual tabs,
// verifies shared date/zone (CF-044), method combobox (CF-043), and area unit
// handling (CF-013), and persists to staging.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/core/presentation/widgets/creatable_combobox.dart';
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

      // Unique-per-run marker (48.20's attendance lesson): the journey runs
      // against a staging site that already holds rows from earlier runs, so
      // the repository read-back (step 10) anchors on a notes value no other
      // row can carry.
      final uniqueNotes = 'STEP-48.21 ${DateTime.now().millisecondsSinceEpoch}';

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

      // 4. Select zone (shared across tabs - CF-044). The picker is a
      // CreatableCombobox: the dropdown opens on focus through its opaque
      // GestureDetector (48.22 re-run), and the option tiles carry semantics
      // labels. The former `find.descendant(of: ListView, InkWell.at(0))`
      // can never match again — 48.22 replaced the tiles' Material InkWells
      // with FTappable — so the zone silently stayed unset and the save
      // failed validation with 'Pilih zona terlebih dahulu.' (48.26 R-7).
      const zoneHint = 'Pilih Zona Operasional...';
      final zoneField = find.text(zoneHint);
      expect(zoneField, findsOneWidget);
      await tester.ensureVisible(zoneField);
      await tester.pumpAndSettle();
      // warnIfMissed: false by design — the tap is absorbed by the combobox's
      // opaque GestureDetector, not by the hint Text. That absorption is the
      // 48.22 fix; proof:
      // test/core/presentation/widgets/creatable_combobox_open_test.dart.
      await tester.tap(zoneField, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Type a unique-per-run zone name. ZoneCubit.loadZones() reads the
      // local Hive cache only — there is NO server fetch (root cause found
      // by this re-run: every `flutter test` run reinstalls the app, so the
      // cache starts empty and the dropdown is structurally empty; the
      // combobox's offline-first create flow is the only interactive way to
      // get a zone, and the daily-log journey already uses it). The test
      // user is a supervisor, so the zones INSERT is permitted by
      // supervisor_zones_all.
      final uniqueZone =
          'STEP-48.21 Zone ${DateTime.now().millisecondsSinceEpoch}';
      // byType(CreatableCombobox) would compare the exact runtimeType
      // INCLUDING generics (CreatableCombobox<ZoneEntity> here), so match
      // the type with a predicate instead. enterText needs the
      // EditableText itself — the hint is a plain Text.
      final zoneInput = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is CreatableCombobox && w.hint == zoneHint,
        ),
        matching: find.byType(EditableText),
      );
      expect(zoneInput, findsOneWidget);
      await tester.enterText(zoneInput, uniqueZone);
      await tester.pumpAndSettle();

      final addZoneTile = find.text('Tambah "$uniqueZone"');
      expect(
        addZoneTile,
        findsOneWidget,
        reason:
            'the combobox offers a Tambah tile for a query matching no item',
      );
      await tester.ensureVisible(addZoneTile);
      await tester.pumpAndSettle();
      await tester.tap(addZoneTile);
      await tester.pumpAndSettle();

      // The created zone is selected asynchronously: _createNew clears the
      // field, the bloc writes the zone, and ZonePicker rebuilds the
      // combobox with initialValue = the new name (didUpdateWidget). Wait
      // for the name to appear IN the field (match by predicate — see the
      // generics note above), then require it.
      var zoneShown = false;
      for (var i = 0; i < 50 && !zoneShown; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        zoneShown = find
            .descendant(
              of: find.byWidgetPredicate(
                (w) => w is CreatableCombobox && w.hint == zoneHint,
              ),
              matching: find.text(uniqueZone),
            )
            .evaluate()
            .isNotEmpty;
      }
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is CreatableCombobox && w.hint == zoneHint,
          ),
          matching: find.text(uniqueZone),
        ),
        findsOneWidget,
        reason: 'the created zone round-trips back into the combobox field',
      );

      // 5. Enter Plan Area. Target EditableText inside AreaInputField per RISK-0009.
      final planAreaField = find.descendant(
        of: find.widgetWithText(AreaInputField, 'Luas Rencana (Plan)'),
        matching: find.byType(EditableText),
      );
      await tester.enterText(planAreaField, '1500');
      await tester.pumpAndSettle();

      // CF-013: Verify Plan area unit (Ha) conversion text in the summary card (1500 m^2 = 0.1500 Ha).
      expect(find.text('0.1500'), findsOneWidget);

      // The soft keyboard shrinks the viewport after enterText on a real
      // device; without dismissing it, taps below the fold (the method
      // combobox and the save button) hit-test onto the scaffold ink layer
      // (48.21 repro: Offset(219.7, 265.3) and Offset(219.7, 509.5) misses).
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      // 6. Select Method (Combobox - CF-043). Same combobox contract as the
      // zone picker (48.22 re-run): the tap on the hint is absorbed by the
      // opaque GestureDetector (warnIfMissed: false), and while the Plan tab
      // is active the Actual tab's identical combobox is not yet built
      // (TabBarView builds lazily), so the semantics label matches exactly
      // one tile.
      final methodField = find.text('Pilih atau tambah metode clearing...');
      expect(methodField, findsOneWidget);
      await tester.ensureVisible(methodField);
      await tester.pumpAndSettle();
      await tester.tap(methodField, warnIfMissed: false);
      await tester.pumpAndSettle();
      final excavatorItem = find.bySemanticsLabel('Excavator');
      expect(
        excavatorItem,
        findsOneWidget,
        reason:
            'Plan-tab method combobox is the only one mounted (TabBarView builds lazily)',
      );
      await tester.ensureVisible(excavatorItem);
      await tester.pumpAndSettle();
      await tester.tap(excavatorItem);
      await tester.pumpAndSettle();
      // The selected method round-trips into the combobox field: _selectItem
      // clears it, then the bloc's MethodChangedEvent rebuild restores it via
      // didUpdateWidget (initialValue = record.method). The former
      // `widgetWithText(FCard, 'Excavator')` asserted a summary card that has
      // not displayed the method since the v2 form rework — no live run ever
      // reached this step to disprove it (BH-016's `Too many elements` fired
      // earlier in every attempt). Same predicate pattern as the zone picker:
      // byType(CreatableCombobox) would compare runtimeType INCLUDING
      // generics. Bounded wait: the restore is asynchronous, like the zone.
      var methodShown = false;
      for (var i = 0; i < 50 && !methodShown; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        methodShown = find
            .descendant(
              of: find.byWidgetPredicate(
                (w) =>
                    w is CreatableCombobox &&
                    w.hint == 'Pilih atau tambah metode clearing...',
              ),
              matching: find.text('Excavator'),
            )
            .evaluate()
            .isNotEmpty;
      }
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) =>
                w is CreatableCombobox &&
                w.hint == 'Pilih atau tambah metode clearing...',
          ),
          matching: find.text('Excavator'),
        ),
        findsOneWidget,
        reason: 'the selected method round-trips into the combobox field',
      );

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
      await tester.enterText(notesField, uniqueNotes);
      await tester.pumpAndSettle();

      // 9. Save. Dismiss the soft keyboard first: enterText on the notes
      // field re-raised it, and the save button sits below the fold while
      // the viewport is shrunk (48.21 repro: the save tap at
      // Offset(219.7, 509.5) hit only the scaffold ink layer).
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      final saveBtn = find.byKey(const Key('save_land_clearing_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Wait for list screen
      expect(find.byType(LandClearingSummaryScreen), findsOneWidget);

      // 10. Verify via repository.
      // STEP-48.1: was `siteId: 'site-1'`, which matches nothing — the form
      // saves with `defaultSiteId` (app_constants.dart). The read-back is
      // keyed by this run's notes marker so leftover rows from earlier runs
      // can never satisfy it.
      final records = await app_main.appServices!.trackingRepository
          .getLandClearingRecords(siteId: defaultSiteId);
      final savedRecord = records.firstWhere(
        (r) => r.notes == uniqueNotes,
        orElse: () => throw StateError(
          'no record with notes "$uniqueNotes" — the save did not persist',
        ),
      );

      expect(savedRecord.planArea, 1500.0);
      expect(savedRecord.actualArea, 1600.0);
      expect(savedRecord.method, 'Excavator');
    });
  });
}
