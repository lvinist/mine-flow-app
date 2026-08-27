import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/cut_fill_form_screen.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        home: CutFillFormScreen(
          repository: mockTrackingRepository,
          zoneRepository: mockZoneRepository,
          siteId: 'site-1',
          foremanId: 'foreman-1',
        ),
      ),
    );
  }

  testWidgets(
    'renders Volume (BCM) and Volume (LCM) labels and no stepper buttons',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Volume (BCM)'), findsOneWidget);
      expect(find.text('Volume (LCM)'), findsOneWidget);
      expect(find.byType(ZonePicker), findsOneWidget);
      expect(find.byIcon(LucideIcons.minus), findsNothing);
      expect(find.byIcon(LucideIcons.plus), findsNothing);
    },
  );
}
