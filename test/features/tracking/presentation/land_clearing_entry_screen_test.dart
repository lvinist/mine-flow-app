import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/presentation/widgets/creatable_combobox.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_entry_screen.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:forui/forui.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  late MockTrackingRepository mockTrackingRepository;
  late MockZoneRepository mockZoneRepository;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    mockTrackingRepository = MockTrackingRepository();
    mockZoneRepository = MockZoneRepository();
    when(() => mockZoneRepository.getZones()).thenReturn([]);
  });

  Widget createWidgetUnderTest() {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        home: LandClearingEntryScreen(
          repository: mockTrackingRepository,
          zoneRepository: mockZoneRepository,
          siteId: 'site-1',
          foremanId: 'foreman-1',
        ),
      ),
    );
  }

  testWidgets(
    'renders TabBar with Plan and Actual tabs, ZonePicker, and CreatableCombobox',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Rencana (Plan)'), findsOneWidget);
      expect(find.text('Realisasi (Actual)'), findsOneWidget);
      expect(find.byType(ZonePicker), findsAtLeastNWidgets(1));
      expect(find.byType(CreatableCombobox<String>), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.remove), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);

      // Switch to Actual tab
      await tester.tap(find.text('Realisasi (Actual)'));
      await tester.pumpAndSettle();

      expect(find.text('Luas Aktual (Actual)'), findsOneWidget);
      expect(find.text('Catatan Terrain'), findsOneWidget);
    },
  );
}
