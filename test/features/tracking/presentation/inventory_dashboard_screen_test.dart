import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_dashboard_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository mockRepository;

  setUp(() {
    mockRepository = MockTrackingRepository();
    when(
      () => mockRepository.getInventoryItems(
        siteId: any(named: 'siteId'),
        zoneId: any(named: 'zoneId'),
        category: any(named: 'category'),
      ),
    ).thenAnswer((_) async => []);
  });

  Widget buildTestWidget() {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        home: InventoryDashboardScreen(
          repository: mockRepository,
          siteId: 'site-1',
        ),
      ),
    );
  }

  group('InventoryDashboardScreen Substep 38.1 Widget Tests', () {
    testWidgets('renders Tambah Item and Laporan in FABs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Tambah Item FAB
      expect(
        find.widgetWithText(FloatingActionButton, 'Tambah Item'),
        findsOneWidget,
      );

      // Verify Laporan FAB via semantics label
      expect(find.bySemanticsLabel('Buat Laporan Inventaris'), findsOneWidget);
    });
  });
}
