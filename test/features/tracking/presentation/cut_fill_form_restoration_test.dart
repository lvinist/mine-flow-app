import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/cut_fill_form_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/volume_input_field.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    registerFallbackValue(
      CutFillRecord(
        id: 'fake',
        siteId: 'site-1',
        zoneId: 'zone-1',
        measurementDate: DateTime(2026, 10, 10),
        measuredBy: 'foreman-1',
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FToaster(child: child!),
        home: Scaffold(
          body: CutFillFormScreen(
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
    final mockTrackingRepo = MockTrackingRepository();
    final mockZoneRepo = MockZoneRepository();
    when(() => mockZoneRepo.getZones()).thenReturn([]);
    // Stub getCutFillRecordById for the reload-before-apply step.
    when(
      () => mockTrackingRepo.getCutFillRecordById(any()),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      createWidgetUnderTest(
        repository: mockTrackingRepo,
        zoneRepository: mockZoneRepo,
        restorationScopeId: 'test-root-cf-restart',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengukuran Baru'), findsOneWidget);

    // Enter unsaved data: BCM volume (first VolumeInputField in the form)
    final bcmField = find.descendant(
      of: find.byType(VolumeInputField).first,
      matching: find.byType(EditableText),
    );
    await tester.enterText(bcmField, '1500');
    await tester.pumpAndSettle();

    // Enter notes
    await tester.enterText(
      find.byKey(const Key('cut_fill_notes_input')),
      'Test note for restoration',
    );
    await tester.pumpAndSettle();

    // Restart the widget tree (simulates OS process death + restoration).
    await tester.restartAndRestore();
    await tester.pumpAndSettle();

    // Sheet identity survives.
    expect(find.text('Pengukuran Baru'), findsOneWidget);

    // The unsaved BCM volume should be restored.
    final restoredBcmField = find.descendant(
      of: find.byType(VolumeInputField).first,
      matching: find.byType(EditableText),
    );
    final restoredBcmController =
        restoredBcmField.evaluate().first.widget as EditableText;
    expect(restoredBcmController.controller.text, '1500.0');

    // The notes should be restored.
    final restoredNotesField = find.descendant(
      of: find.byKey(const Key('cut_fill_notes_input')),
      matching: find.byType(EditableText),
    );
    final restoredNotesController =
        restoredNotesField.evaluate().first.widget as EditableText;
    expect(
      restoredNotesController.controller.text,
      'Test note for restoration',
    );
  });

  testWidgets('fresh form loads with clean state (no prior snapshot)', (
    tester,
  ) async {
    final mockTrackingRepo = MockTrackingRepository();
    final mockZoneRepo = MockZoneRepository();
    when(() => mockZoneRepo.getZones()).thenReturn([]);
    when(
      () => mockTrackingRepo.getCutFillRecordById(any()),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      createWidgetUnderTest(
        repository: mockTrackingRepo,
        zoneRepository: mockZoneRepo,
        restorationScopeId: 'test-root-cf-fresh',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengukuran Baru'), findsOneWidget);

    // BCM field should be empty (no restored value).
    final bcmField = find.descendant(
      of: find.byType(VolumeInputField).first,
      matching: find.byType(EditableText),
    );
    final bcmController = bcmField.evaluate().first.widget as EditableText;
    expect(bcmController.controller.text, isEmpty);
  });
}
