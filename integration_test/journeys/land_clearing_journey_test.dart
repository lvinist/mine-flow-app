// E2E Critical User Journey: Land Clearing (STEP-45.5)
//
// Exercises land clearing measurement creation across Plan and Actual tabs,
// verifies shared date/zone (CF-044), method combobox (CF-043), and area unit
// handling (CF-013), and persists to staging.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
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

/// Selects the Plan tab on the land-clearing entry sheet.
///
/// STEP-55.3 renders only the selected tab body (AnimatedBuilder, not
/// TabBarView), so any finder for a Plan-only field resolves to nothing while
/// the Actual tab is active. The create route carries no `?tab=plan`, so the
/// journey must select Plan explicitly before touching those fields.
Future<void> _selectPlanTab(WidgetTester tester) async {
  final planTab = find.text('Rencana (Plan)');
  expect(planTab, findsOneWidget, reason: 'the Plan tab must be reachable');
  await tester.ensureVisible(planTab);
  await tester.pumpAndSettle();
  await tester.tap(planTab);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Land Clearing Journey (STEP-45.5)', () {
    testWidgets('login, create land clearing, verify tabs/units/combobox, and save', (
      tester,
    ) async {
      if (!isStagingConfigured) {
        recordE2eSkipped(
          'land_clearing_journey_test: staging credentials absent',
        );
        markTestSkipped('Unverified: Staging credentials absent');
        return;
      }

      recordE2eExecuted('land_clearing_journey_test');

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

      // 2. Navigate to Land Clearing screen and open the CREATE form.
      //
      // STEP-55.3 split the form into Plan/Actual tabs built by an
      // AnimatedBuilder that renders only the selected tab. The create route
      // carries no `?tab=plan`, so the entry screen defaults to the ACTUAL
      // tab (initialTab = 1) and the Plan-area field below is never built.
      // Open the route with the explicit plan tab so the field exists.
      appRouter.go(AppRoutes.landClearing);
      await tester.pumpAndSettle();

      expect(find.byType(LandClearingSummaryScreen), findsOneWidget);

      // 3. Open Form page.
      //
      // STEP-55.3 replaced the Material `FloatingActionButton` with the shared
      // ForUI action (`FButton` inside a `Semantics(label:)`). Anchor on the
      // FButton that owns the label rather than the retired FAB.
      final newClearingBtn = find.widgetWithText(FButton, 'Clearing Baru');
      expect(newClearingBtn, findsOneWidget);
      await tester.ensureVisible(newClearingBtn);
      await tester.pumpAndSettle();
      await tester.tap(newClearingBtn);
      await tester.pumpAndSettle();

      // STEP-55.11: land-clearing-create defaults to the Actual tab; the
      // journey's area/zone fields live on the Plan tab, so select it.
      expect(find.byType(LandClearingEntryScreen), findsOneWidget);
      await _selectPlanTab(tester);

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

      // 6. Select Method (Combobox - CF-043). STEP-51.7 moved this to one
      // shared selection-only control above both tabs and changed its hint.
      // The tap is still absorbed by the combobox's opaque GestureDetector.
      const methodHint = 'Pilih metode clearing...';
      final methodField = find.text(methodHint);
      expect(methodField, findsOneWidget);
      await tester.ensureVisible(methodField);
      await tester.pumpAndSettle();
      await tester.tap(methodField, warnIfMissed: false);
      await tester.pumpAndSettle();
      final excavatorItem = find.bySemanticsLabel('Excavator');
      expect(
        excavatorItem,
        findsOneWidget,
        reason: 'the shared method combobox offers one Excavator option',
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
                (w) => w is CreatableCombobox && w.hint == methodHint,
              ),
              matching: find.text('Excavator'),
            )
            .evaluate()
            .isNotEmpty;
      }
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is CreatableCombobox && w.hint == methodHint,
          ),
          matching: find.text('Excavator'),
        ),
        findsOneWidget,
        reason: 'the selected method round-trips into the combobox field',
      );

      // 7. Switch to Actual Tab.
      //
      // STEP-55.11: the tab bar sits inside the sheet's scrollable body, so
      // after the plan-tab interactions it can be scrolled off-viewport and a
      // bare tap silently misses — the journey then keeps entering the plan
      // area and the Ha conversion assertion reads the wrong card. Scroll the
      // tab into view first and require the switch before continuing.
      final actualTab = find.text('Realisasi (Actual)');
      await tester.ensureVisible(actualTab);
      await tester.pumpAndSettle();
      await tester.tap(actualTab);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AreaInputField, 'Luas Aktual (Actual)'),
        findsOneWidget,
        reason: 'switching to the Actual tab must build its area field',
      );

      // 8. Enter Actual Area. Target EditableText inside AreaInputField per RISK-0009.
      //
      // STEP-55.11: after the tab switch the AnimatedBuilder rebuilds the tab
      // body, and the field can be re-created mid-sequence. A `find.descendant`
      // captured before the pump can therefore point at a stale EditableText
      // whose controller is detached — `enterText` writes nothing (observed:
      // `controller=` empty in the failure diagnostics). Re-resolve the finder
      // immediately before each use, tap to focus first, and verify the text
      // actually landed in the controller before moving on.
      Finder actualAreaField() => find.descendant(
        of: find.widgetWithText(AreaInputField, 'Luas Aktual (Actual)'),
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(actualAreaField());
      await tester.pumpAndSettle();
      await tester.tap(actualAreaField());
      await tester.pumpAndSettle();
      await tester.enterText(actualAreaField(), '1600');
      await tester.pumpAndSettle();
      for (var i = 0; i < 10; i++) {
        final ha = find.text('0.1600');
        if (ha.evaluate().isNotEmpty) break;
        final et = tester.widget<EditableText>(actualAreaField());
        if (et.controller.text != '1600') {
          await tester.enterText(actualAreaField(), '1600');
        }
        await tester.pump(const Duration(milliseconds: 100));
      }

      // CF-013: Verify Actual area unit (Ha) conversion text (1600 m^2 = 0.1600 Ha).
      // STEP-55.11: the bloc emit + AnimatedBuilder rebuild can lag the
      // enterText frame on Android (the field's onChanged reaches the bloc
      // asynchronously relative to the last pumped frame), so pump in
      // bounded slices until the conversion text is present rather than
      // asserting on the first frame.
      final haText = find.text('0.1600');
      for (var i = 0; i < 50 && haText.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // STEP-55.11: the diagnostics must reach the failure report. On web,
      // `flutter drive` only surfaces the `reason` string in its result JSON,
      // not debugPrint, so fold the live field/bloc/summary state into the
      // reason the failure carries.
      final fieldWidget = tester.widget<AreaInputField>(
        find.widgetWithText(AreaInputField, 'Luas Aktual (Actual)'),
      );
      // The EditableText's controller text tells us whether enterText even
      // reached the field (controller has the text but the bloc does not =>
      // onChanged was swallowed; both empty => the field found was stale).
      final editable = tester.widget<EditableText>(actualAreaField());
      final controllerText = editable.controller.text;
      // STEP-55.11: read the bloc from *below* the MultiBlocProvider.
      // LandClearingEntryScreen's build *returns* the MultiBlocProvider, so
      // its own element sits ABOVE the provider and `context.read` throws
      // ProviderNotFoundException. Any widget built inside the provider's
      // child subtree has it in scope.
      final lcCtx = tester.element(
        find.widgetWithText(AreaInputField, 'Luas Aktual (Actual)'),
      );
      final lcBloc = lcCtx.read<LandClearingBloc>();
      final lcState = lcBloc.state;
      final stateRecord = lcState is LandClearingFormState
          ? lcState.record
          : null;
      final fieldShown = fieldWidget.value > 0
          ? fieldWidget.value.toStringAsFixed(1)
          : 'empty';
      final haShown = <String>[];
      tester
          .widgetList(find.byType(Text))
          .cast<Text>()
          .forEach((t) => haShown.add(t.data ?? ''));
      expect(
        haText,
        findsOneWidget,
        reason:
            'CF-013 Ha conversion (1600 m2 -> 0.1600 Ha) missing. '
            'field.value=$fieldShown '
            'controller=$controllerText '
            'state=${lcState.runtimeType} '
            'actual=${stateRecord?.actualArea} '
            'plan=${stateRecord?.planArea} '
            'onScreenHa=${haShown.where((s) => s.contains('0.16')).join('|')} '
            'screenTexts=${haShown.take(12).join('|')}',
      );

      // Enter Notes. RISK-0009: never anchor on `find.byType(TextField)` —
      // target the notes field by its own hint text instead. The Actual tab's
      // "Catatan Terrain" TextField is the only field carrying this hint
      // (land_clearing_entry_screen.dart), so this is unambiguous, whereas
      // `.last` over every TextField depended on widget order.
      //
      // STEP-55.11: the notes field sits below the fold of the sheet's
      // scrollable body, and the area-field enterText above can leave the
      // scroll position shifted. Anchor on the field's stable `Key` and scroll
      // it into view first, otherwise the finder matches nothing on web.
      final notesField = find.descendant(
        of: find.byKey(const Key('land_clearing_notes_input')),
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(
        find.byKey(const Key('land_clearing_notes_input')),
      );
      await tester.pumpAndSettle();
      expect(notesField, findsOneWidget);
      await tester.tap(notesField);
      await tester.pumpAndSettle();
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
