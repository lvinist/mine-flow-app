import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_item_entry_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository mockTrackingRepository;

  setUp(() {
    mockTrackingRepository = MockTrackingRepository();
  });

  Widget createWidgetUnderTest({String? itemId, InventoryItem? existingItem}) {
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
        builder: (context, child) => FToaster(child: child!),
        home: InventoryItemEntryScreen(
          repository: mockTrackingRepository,
          siteId: 'site-1',
          itemId: itemId,
          existingItem: existingItem,
        ),
      ),
    );
  }

  testWidgets('cold edit loads and saves the URL item, not a new UUID', (
    tester,
  ) async {
    const item = InventoryItem(
      id: 'e629db4c-1af8-442e-b3f5-b1a6256289c1',
      siteId: 'site-1',
      itemName: 'Existing inventory item',
      category: 'Consumables',
      quantityOnHand: 12,
    );
    when(
      () => mockTrackingRepository.getInventoryItemById(item.id),
    ).thenAnswer((_) async => item);
    registerFallbackValue(item);
    when(
      () => mockTrackingRepository.saveInventoryItem(any()),
    ).thenAnswer((_) async {});
    await tester.pumpWidget(createWidgetUnderTest(itemId: item.id));
    await tester.pumpAndSettle();
    final bloc = tester
        .element(find.byType(FTextField).first)
        .read<InventoryBloc>();
    final state = bloc.state as InventoryFormState;
    expect(
      state.item.id,
      item.id,
      reason: 'a cold edit must not mint a new item',
    );
    expect(state.item.itemName, item.itemName);
    final saved = bloc.stream.firstWhere(
      (state) => state is InventoryFormState && state.isSaved,
    );
    bloc.add(const SaveInventoryItemEvent());
    await saved;
    final written =
        verify(
              () => mockTrackingRepository.saveInventoryItem(captureAny()),
            ).captured.single
            as InventoryItem;
    expect(written.id, item.id);
    expect(written.itemName, item.itemName);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

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
