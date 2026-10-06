import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_transaction.dart';
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

  Widget buildTestWidget({Locale locale = const Locale('id')}) {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: locale,
        supportedLocales: const [Locale('id'), Locale('en')],
        home: InventoryHistoryScreen(
          repository: mockRepository,
          itemId: 'item-1',
        ),
      ),
    );
  }

  for (final width in [400.0, 1200.0]) {
    for (final language in ['id', 'en']) {
      testWidgets('timestamp provenance at $width in $language', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final eventTime = DateTime.utc(2026, 10, 1, 8);
        final serverTime = DateTime.utc(2026, 10, 6, 12);
        when(() => mockRepository.getInventoryTransactions(any())).thenAnswer(
          (_) async => [
            InventoryTransaction(
              id: 'new',
              siteId: 'site-1',
              itemId: 'item-1',
              delta: 2,
              reason: 'New movement',
              actorId: 'actor',
              createdAt: serverTime,
              occurredAt: eventTime,
              hasServerCreatedAt: true,
            ),
            InventoryTransaction(
              id: 'old',
              siteId: 'site-1',
              itemId: 'item-1',
              delta: 1,
              reason: 'Legacy movement',
              actorId: 'actor',
              createdAt: eventTime,
            ),
          ],
        );
        await tester.pumpWidget(buildTestWidget(locale: Locale(language)));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            language == 'en' ? 'Recorded by server:' : 'Dicatat server:',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            language == 'en'
                ? 'Legacy device time:'
                : 'Waktu perangkat (data lama):',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            language == 'en' ? 'Event time:' : 'Waktu kejadian:',
          ),
          findsNWidgets(2),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('InventoryHistoryScreen Substep 55.8 Widget Tests', () {
    testWidgets('mobile history is a full page, not a draggable bottom sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('app-sheet-drag-handle')), findsNothing);
      expect(tester.getTopLeft(find.text('Detail & Riwayat')).dy, lessThan(40));
      expect(
        tester
            .widget<AppResponsiveSheet>(find.byType(AppResponsiveSheet))
            .mobileFullPage,
        isTrue,
      );
    });

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
