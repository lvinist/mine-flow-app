import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_history_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository mockRepository;

  setUp(() {
    mockRepository = MockTrackingRepository();

    when(() => mockRepository.getInventoryItemById(any())).thenAnswer(
      (_) async => const InventoryItem(
        id: 'item-1',
        siteId: 'site-1',
        itemName: 'Test Item',
        quantityOnHand: 10.0,
      ),
    );

    when(
      () => mockRepository.getInventoryTransactions(any()),
    ).thenAnswer((_) async => []);
  });

  Widget buildTestWidget() {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id')],
        home: InventoryHistoryScreen(
          repository: mockRepository,
          itemId: 'item-1',
        ),
      ),
    );
  }

  group('InventoryHistoryScreen Substep 55.8 Widget Tests', () {
    testWidgets('renders detail view and actions', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppResponsiveSheet), findsOneWidget);
      expect(find.text('Test Item'), findsWidgets);

      // Check for actions
      expect(find.widgetWithText(FButton, 'Ubah Data'), findsOneWidget);
      expect(find.widgetWithText(FButton, 'Penyesuaian Stok'), findsOneWidget);
      expect(find.widgetWithText(FButton, 'Hapus Item'), findsOneWidget);
    });
  });
}
