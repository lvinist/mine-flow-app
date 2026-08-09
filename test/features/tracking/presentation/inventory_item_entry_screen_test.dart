import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_item_entry_screen.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository mockTrackingRepository;

  setUp(() {
    mockTrackingRepository = MockTrackingRepository();
  });

  Widget createWidgetUnderTest() {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        home: InventoryItemEntryScreen(
          repository: mockTrackingRepository,
          siteId: 'site-1',
        ),
      ),
    );
  }

  testWidgets(
    'renders merged Jumlah & Satuan row with quantity input and unit dropdown',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Jumlah & Satuan Stok'), findsOneWidget);
      expect(find.text('Nama Item'), findsOneWidget);
      expect(find.byType(FTextField), findsAtLeastNWidgets(2));
      expect(find.byType(DropdownButton<String>), findsAtLeastNWidgets(1));
    },
  );
}
