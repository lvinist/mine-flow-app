import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_entry_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/area_input_field.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    registerFallbackValue(
      LandClearingRecord(
        id: 'fake',
        siteId: 'site-1',
        zoneId: 'zone-1',
        clearingDate: DateTime(2026, 10, 10),
        clearedBy: 'foreman-1',
      ),
    );
  });

  Widget createWidgetUnderTest({
    required MockTrackingRepository repository,
    required MockZoneRepository zoneRepository,
    required String restorationScopeId,
  }) {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        locale: const Locale('id'),
        restorationScopeId: restorationScopeId,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FToaster(child: child!),
        home: Scaffold(
          body: LandClearingEntryScreen(
            repository: repository,
            zoneRepository: zoneRepository,
            siteId: 'site-1',
            foremanId: 'foreman-1',
          ),
        ),
      ),
    );
  }

  testWidgets('restartAndRestore: unsaved draft survives process restart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final mockTrackingRepo = MockTrackingRepository();
    final mockZoneRepo = MockZoneRepository();
    when(() => mockZoneRepo.getZones()).thenReturn([]);
    when(
      () => mockTrackingRepo.getLandClearingRecordById(any()),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      createWidgetUnderTest(
        repository: mockTrackingRepo,
        zoneRepository: mockZoneRepo,
        restorationScopeId: 'test-root-lc-restart',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rencana (Plan)'), findsOneWidget);

    // Enter unsaved data on the Actual tab: actual area
    final actualField = find.descendant(
      of: find.widgetWithText(AreaInputField, 'Luas Aktual (Actual)'),
      matching: find.byType(EditableText),
    );
    await tester.enterText(actualField, '1600');
    await tester.pumpAndSettle();

    // Enter notes on the Actual tab
    await tester.enterText(
      find.byKey(const Key('land_clearing_notes_input')),
      'Restored terrain note',
    );
    await tester.pumpAndSettle();

    // Switch to Plan tab, enter plan area
    await tester.tap(find.text('Rencana (Plan)'));
    await tester.pumpAndSettle();
    final planField = find.descendant(
      of: find.widgetWithText(AreaInputField, 'Luas Rencana (Plan)'),
      matching: find.byType(EditableText),
    );
    await tester.enterText(planField, '1500');
    await tester.pumpAndSettle();

    // Restart the widget tree (simulates OS process death + restoration).
    await tester.restartAndRestore();
    await tester.pumpAndSettle();

    // Tab should be restored to Plan.
    expect(find.textContaining('Luas Rencana'), findsOneWidget);

    // The restored plan area should survive.
    final restoredPlanField = find.descendant(
      of: find.widgetWithText(AreaInputField, 'Luas Rencana (Plan)'),
      matching: find.byType(EditableText),
    );
    final restoredPlanController =
        restoredPlanField.evaluate().first.widget as EditableText;
    expect(restoredPlanController.controller.text, '1500.0');

    // The restored notes should survive.
    // Switch to Actual tab to access the notes field.
    await tester.tap(find.text('Realisasi (Actual)'));
    await tester.pumpAndSettle();
    final restoredNotesField = find.descendant(
      of: find.byKey(
        const Key('land_clearing_notes_input'),
        skipOffstage: false,
      ),
      matching: find.byType(EditableText),
    );
    final restoredNotesController =
        restoredNotesField.evaluate().first.widget as EditableText;
    expect(restoredNotesController.controller.text, 'Restored terrain note');
  });

  testWidgets('fresh form loads with clean state (no prior snapshot)', (
    tester,
  ) async {
    final mockTrackingRepo = MockTrackingRepository();
    final mockZoneRepo = MockZoneRepository();
    when(() => mockZoneRepo.getZones()).thenReturn([]);
    when(
      () => mockTrackingRepo.getLandClearingRecordById(any()),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      createWidgetUnderTest(
        repository: mockTrackingRepo,
        zoneRepository: mockZoneRepo,
        restorationScopeId: 'test-root-lc-fresh',
      ),
    );
    await tester.pumpAndSettle();

    // Should default to Actual tab.
    expect(find.textContaining('Luas Aktual'), findsOneWidget);

    // Actual area field should be empty.
    final actualField = find.descendant(
      of: find.widgetWithText(AreaInputField, 'Luas Aktual (Actual)'),
      matching: find.byType(EditableText),
    );
    final actualController =
        actualField.evaluate().first.widget as EditableText;
    expect(actualController.controller.text, isEmpty);
  });
}
