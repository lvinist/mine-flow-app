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
import 'package:mine_flow/core/presentation/widgets/creatable_combobox.dart';
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

        // Unique-per-run marker (48.20's attendance lesson): the journey is
        // re-run against a staging site that already holds rows from earlier
        // runs, so both the card tap (step 9) and the repository read-back
        // (step 10) anchor on a value no other row can carry.
        final uniqueNote =
            'STEP-48.21 ${DateTime.now().millisecondsSinceEpoch}';

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

        // 4. Select zone. The picker is a CreatableCombobox: the dropdown opens
        // on focus through its opaque GestureDetector (48.22 re-run), and the
        // option tiles carry semantics labels. The former
        // `find.descendant(of: ListView, matching: InkWell.at(0))` can never
        // match again — 48.22 replaced the tiles' Material InkWells with
        // FTappable — so the zone silently stayed unset and the save failed
        // validation with 'Pilih zona terlebih dahulu.' (48.26 R-7a).
        const zoneHint = 'Pilih Zona Operasional...';
        final zoneField = find.text(zoneHint);
        expect(zoneField, findsOneWidget);
        await tester.ensureVisible(zoneField);
        await tester.pumpAndSettle();
        // warnIfMissed: false by design — the tap is absorbed by the
        // combobox's opaque GestureDetector, not by the hint Text. That
        // absorption is the 48.22 fix; proof:
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

        // The soft keyboard shrinks the viewport after enterText on a real
        // device; without dismissing it, everything below the volume fields —
        // including the material field at y≈631 — sits under the keyboard
        // overlay and every tap hit-test misses (the 48.26 R-7 repro:
        // Offset(205.7, 631.3) resolved to the Scaffold's ink layer).
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        // 6. Select Material Type through the ForUI combobox. The dropdown
        // opens on focus via the field's opaque GestureDetector (48.22
        // re-run), so tapping the hint is absorbed by design — hence
        // warnIfMissed: false. Proof:
        // test/core/presentation/widgets/creatable_combobox_open_test.dart.
        final materialField = find.text('Pilih tipe material');
        expect(materialField, findsOneWidget);
        await tester.ensureVisible(materialField);
        await tester.pumpAndSettle();
        await tester.tap(materialField, warnIfMissed: false);
        await tester.pumpAndSettle();
        final obItem = find.bySemanticsLabel('OB / Waste');
        expect(obItem, findsOneWidget);
        await tester.ensureVisible(obItem);
        await tester.pumpAndSettle();
        await tester.tap(obItem);
        await tester.pumpAndSettle();

        // 6b. Notes marker. RISK-0009: target the notes field by its own hint
        // text, never `find.byType(TextField)`; the EditableText inside is the
        // same pattern the land-clearing journey already uses.
        final notesField = find.descendant(
          of: find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.hintText ==
                    'Catatan pengukuran, kondisi lapangan, dll...',
          ),
          matching: find.byType(EditableText),
        );
        expect(notesField, findsOneWidget);
        await tester.enterText(notesField, uniqueNote);
        await tester.pumpAndSettle();

        // 7. Verify Net Volume in UI (Current semantics: BCM + LCM / (1 + swell)).
        // Default swell factor is 0.25 -> 100 + 50/1.25 = 140.0
        expect(find.textContaining('140.0 m³'), findsOneWidget);

        // 8. Save. Dismiss the soft keyboard first: enterText on the notes
        // field re-raised it, and the save button sits below the fold while
        // the viewport is shrunk.
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        final saveBtn = find.byKey(const Key('save_cut_fill_button'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Wait for list screen
        expect(find.byType(CutFillListScreen), findsOneWidget);

        // 9. Edit record to add negative elevation. Tap THIS run's record card
        // by its unique notes text — `.first` over `140.0 m³` was
        // order-dependent against staging rows left by earlier runs (48.20's
        // attendance lesson: journeys must be idempotent against a dirty site).
        final ourCard = find.textContaining(uniqueNote);
        for (var i = 0; i < 50 && ourCard.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(
          ourCard,
          findsOneWidget,
          reason:
              'the just-saved record is the only one carrying the '
              'unique-per-run notes marker',
        );
        await tester.ensureVisible(ourCard);
        await tester.pumpAndSettle();
        await tester.tap(ourCard);
        await tester.pumpAndSettle();

        expect(find.byType(CutFillFormScreen), findsOneWidget);

        final elevationField = find.descendant(
          of: find.widgetWithText(FCard, 'Perubahan Elevasi (opsional)'),
          matching: find.byType(EditableText),
        );
        await tester.enterText(elevationField, '-2.5');
        await tester.pumpAndSettle();

        // Keyboard down again before tapping save (same mechanism as step 8).
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        final saveBtn2 = find.byKey(const Key('save_cut_fill_button'));
        await tester.ensureVisible(saveBtn2);
        await tester.tap(saveBtn2);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(CutFillListScreen), findsOneWidget);

        // 10. Assert current semantics explicitly on the repository data.
        // STEP-48.1: was `siteId: 'site-1'`, which matches nothing — the form
        // saves with `defaultSiteId` (app_constants.dart). The read-back is
        // keyed by this run's notes marker so leftover rows from earlier runs
        // can never satisfy it.
        final records = await app_main.appServices!.trackingRepository
            .getCutFillRecords(siteId: defaultSiteId);
        final savedRecord = records.firstWhere(
          (r) => r.notes == uniqueNote,
          orElse: () => throw StateError(
            'no record with notes "$uniqueNote" — the '
            'edit of the just-saved row did not persist',
          ),
        );

        expect(savedRecord.materialType, 'OB / Waste');
        expect(savedRecord.bcmVolume, 100.0);
        expect(savedRecord.lcmVolume, 50.0);
        expect(savedRecord.elevationChange, -2.5);
        expect(savedRecord.netVolume, closeTo(140.0, 0.01));
      },
    );
  });
}
