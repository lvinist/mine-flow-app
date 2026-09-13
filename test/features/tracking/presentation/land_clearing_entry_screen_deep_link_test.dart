import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_entry_screen.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  late MockTrackingRepository mockTrackingRepository;
  late MockZoneRepository mockZoneRepository;

  setUp(() {
    mockTrackingRepository = MockTrackingRepository();
    mockZoneRepository = MockZoneRepository();
    when(() => mockZoneRepository.getZones()).thenReturn([]);
  });

  testWidgets('cold edit loads record by ID and populates fields', (
    tester,
  ) async {
    final testRecord = LandClearingRecord(
      id: 'lc-test-1',
      siteId: 'site-1',
      zoneId: 'zone-1',
      method: 'Excavator',
      planArea: 100.0,
      actualArea: 50.0,
      clearingDate: DateTime(2026, 9, 9),
      clearedBy: 'foreman-1',
      createdAt: DateTime(2026, 9, 9),
      notes: 'Existing test note',
    );

    // This mock needs to be created or matched, if the function exists
    when(
      () => mockTrackingRepository.getLandClearingRecordById('lc-test-1'),
    ).thenAnswer((_) async => testRecord);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LandClearingEntryScreen(
            repository: mockTrackingRepository,
            zoneRepository: mockZoneRepository,
            siteId: 'site-1',
            foremanId: 'foreman-1',
            recordId: 'lc-test-1', // no existingRecord passed
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Land Clearing'), findsOneWidget);
    expect(find.text('Zona: zone-1'), findsOneWidget);
  });
}
