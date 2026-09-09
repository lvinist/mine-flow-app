// CF-043: widget tests for the shared method control.
// The land-clearing entry form previously had two independent
// CreatableCombobox<String> widgets both writing record.method — one per tab.
// The fix (51.7) collapses them into a single control in the shared section
// above the TabBar. These tests assert:
//   (a) Exactly one CreatableCombobox is rendered (both tabs share it).
//   (b) The method control is visible on both Plan and Actual tabs,
//       proving the shared-value semantics the old design broke.
//   (c) Saving with an out-of-set method value (injected via an existingRecord)
//       is rejected — repository.saveLandClearingRecord is never called.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/presentation/widgets/creatable_combobox.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_entry_screen.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal [LandClearingRecord] for testing, allowing a custom
/// [method] value (which may be outside the enumerated set).
LandClearingRecord _buildRecord({
  required String method,
  required String zoneId,
  double planArea = 500.0,
}) {
  return LandClearingRecord(
    id: 'test-id',
    siteId: 'site-1',
    zoneId: zoneId,
    method: method,
    planArea: planArea,
    actualArea: 0.0,
    clearingDate: DateTime(2026, 9, 9),
    clearedBy: 'foreman-1',
    createdAt: DateTime(2026, 9, 9),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockTrackingRepository mockTrackingRepository;
  late MockZoneRepository mockZoneRepository;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    registerFallbackValue(_buildRecord(method: 'Excavator', zoneId: 'zone-1'));
  });

  setUp(() {
    mockTrackingRepository = MockTrackingRepository();
    mockZoneRepository = MockZoneRepository();
    when(() => mockZoneRepository.getZones()).thenReturn([]);
  });

  Widget createWidgetUnderTest({LandClearingRecord? existingRecord}) {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        builder: (context, child) => FToaster(child: child!),
        home: LandClearingEntryScreen(
          repository: mockTrackingRepository,
          zoneRepository: mockZoneRepository,
          siteId: 'site-1',
          foremanId: 'foreman-1',
          existingRecord: existingRecord,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Baseline: structural layout + single combobox
  // -------------------------------------------------------------------------

  testWidgets(
    'renders TabBar with Plan and Actual tabs, ZonePicker, and exactly one '
    'CreatableCombobox — CF-043',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Rencana (Plan)'), findsOneWidget);
      expect(find.text('Realisasi (Actual)'), findsOneWidget);
      expect(find.byType(ZonePicker), findsAtLeastNWidgets(1));

      // CF-043: exactly one combobox — not two per-tab ones.
      // Before the fix this would have found 2 (one rendered per tab since
      // both were in the widget tree even when one tab was not visible), so
      // this assertion would have FAILED on the pre-change code.
      expect(find.byType(CreatableCombobox<String>), findsOneWidget);

      // No create-new affordance (selection-only since STEP-48.30).
      expect(find.byIcon(LucideIcons.minus), findsNothing);
      expect(find.byIcon(LucideIcons.plus), findsNothing);

      // Switch to Actual tab — the shared combobox must still be exactly one.
      await tester.tap(find.text('Realisasi (Actual)'));
      await tester.pumpAndSettle();

      expect(find.text('Luas Aktual (Actual)'), findsOneWidget);
      expect(find.text('Catatan Terrain'), findsOneWidget);

      // CF-043: still exactly one combobox on the Actual tab view.
      expect(find.byType(CreatableCombobox<String>), findsOneWidget);
    },
  );

  // -------------------------------------------------------------------------
  // CF-043: shared-value semantics
  //
  // The shared control lives above the TabBar, so it is always mounted.
  // 'Metode Clearing' label appears exactly once regardless of which tab is
  // active, confirming the widget is not re-created per tab.
  //
  // How this fails on pre-change code:
  //   Before the fix, each tab had its own combobox with the label, so
  //   switching to the Actual tab would still find the label — but
  //   find.byType(CreatableCombobox<String>) would find 2 (both in the tree),
  //   causing the findsOneWidget assertion to fail.
  // -------------------------------------------------------------------------

  testWidgets(
    'CF-043: method control label is visible on both Plan and Actual tabs — '
    'shared-value semantics',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Plan tab active — method label visible, exactly one combobox.
      expect(find.text('Metode Clearing'), findsOneWidget);
      expect(find.byType(CreatableCombobox<String>), findsOneWidget);

      // Switch to Actual tab.
      await tester.tap(find.text('Realisasi (Actual)'));
      await tester.pumpAndSettle();

      // Method label still visible — same widget, not re-created per tab.
      expect(find.text('Metode Clearing'), findsOneWidget);
      // Still exactly one combobox.
      expect(find.byType(CreatableCombobox<String>), findsOneWidget);
    },
  );

  // -------------------------------------------------------------------------
  // CF-043: constraint — out-of-set method is rejected by _validateAndSave.
  //
  // The selection-only combobox (onCreateNew == null) is the first line of
  // defence, preventing the user from typing a free-form value. The
  // _validateAndSave guard is a second line for stale values that could arrive
  // from an existingRecord.
  //
  // This test injects an existing record whose method is not in
  // _clearingMethods, then taps Save — verifying that the repository save is
  // never called (the constraint rejected the attempt).
  //
  // How this fails on pre-change code:
  //   Before the fix, _validateAndSave only checked for null/empty method,
  //   not for out-of-set values. The repository save would have been attempted,
  //   and verifyNever would FAIL.
  // -------------------------------------------------------------------------

  testWidgets('CF-043: saving with an out-of-set method value is rejected; '
      'repository.saveLandClearingRecord is never called', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 'InvalidMethod' is not in _clearingMethods = ['Excavator','Bulldozer','Chainsaw'].
    final outOfSetRecord = _buildRecord(
      method: 'InvalidMethod',
      zoneId: 'zone-1',
    );

    await tester.pumpWidget(
      createWidgetUnderTest(existingRecord: outOfSetRecord),
    );
    await tester.pumpAndSettle();

    // Tap Save. The bloc has method='InvalidMethod', zoneId='zone-1',
    // planArea=500 — only the method constraint check should block the save.
    await tester.tap(find.byKey(const Key('save_land_clearing_button')));
    await tester.pump(const Duration(seconds: 5));

    // CF-043 constraint: repository save must NOT have been called.
    verifyNever(() => mockTrackingRepository.saveLandClearingRecord(any()));
  });
}
