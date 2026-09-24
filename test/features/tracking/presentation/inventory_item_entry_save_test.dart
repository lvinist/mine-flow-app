import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_item_entry_screen.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class _FakeInventoryItem extends Fake implements InventoryItem {}

/// STEP-55.8 residual (E2E routed from 55.11): the inventory journey's save
/// gate failed with "the tap did not reach the button (web hit-test miss)".
/// This widget test proves the save button in the AppResponsiveSheet footer is
/// genuinely reachable — a real save-tap dispatches the save and pops the sheet
/// back to the list — so the journey failure is a fixture defect (a stale
/// `find.byType(SnackBar)` gate; the app moved to FToast in STEP-51.2), not an
/// absorbed-pointer product defect.
void main() {
  setUpAll(() {
    registerFallbackValue(_FakeInventoryItem());
  });

  late MockTrackingRepository repository;

  setUp(() {
    repository = MockTrackingRepository();
    when(() => repository.saveInventoryItem(any())).thenAnswer((_) async {});
    when(
      () => repository.getInventoryItems(
        siteId: any(named: 'siteId'),
        zoneId: any(named: 'zoneId'),
        category: any(named: 'category'),
      ),
    ).thenAnswer((_) async => []);
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/teams/inventory/form',
      routes: [
        GoRoute(
          path: '/teams/inventory',
          builder: (_, _) => const Scaffold(body: Text('INVENTORY LIST')),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, _) => InventoryItemEntryScreen(
                repository: repository,
                siteId: 'site-1',
              ),
            ),
          ],
        ),
      ],
    );

    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FToaster(child: child!),
      ),
    );
  }

  Future<void> runReachabilityCase(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(InventoryItemEntryScreen), findsOneWidget);

    // Enter the required fields (name + category) so CF-038 validation passes.
    final nameField = find.descendant(
      of: find.byType(FTextField).first,
      matching: find.byType(EditableText),
    );
    await tester.enterText(nameField, 'Solar Industri B30');
    await tester.pumpAndSettle();

    final categoryDropdown = find.byType(DropdownButtonFormField<String>);
    expect(categoryDropdown, findsOneWidget);
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fuel / Lubricants').last);
    await tester.pumpAndSettle();

    // The save button lives in the sheet footer, outside the scrollable body.
    final saveBtn = find.byKey(
      const ValueKey<String>('save_inventory_item_button'),
    );
    expect(saveBtn, findsOneWidget);

    // A plain hit-test tap with warnIfMissed — exactly what the journey does.
    // If the footer button were covered/off-screen this warns and the save
    // never fires.
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn, warnIfMissed: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // 1. The tap reached the button: the save was dispatched to the repo.
    verify(() => repository.saveInventoryItem(any())).called(1);

    // 2. The success path popped the sheet back to the list.
    await tester.pumpAndSettle();
    expect(find.byType(InventoryItemEntryScreen), findsNothing);
    expect(find.text('INVENTORY LIST'), findsOneWidget);
  }

  testWidgets(
    'wide (web/desktop) layout: save button in the right-side sheet footer is '
    'reachable and pops the sheet (fixture-vs-product proof for 55.8 residual)',
    (tester) async {
      // Wide surface (>=800dp) -> AppResponsiveSheet renders the right-side
      // panel with a pinned footer, matching the web-server layout.
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await runReachabilityCase(tester);
    },
  );

  testWidgets(
    'mobile (Android) layout: save button in the 0.85 bottom-sheet footer is '
    'reachable and pops the sheet — footer is not pushed below the fold',
    (tester) async {
      // Narrow surface (<800dp) -> AppResponsiveSheet renders the mobile
      // bottom sheet (FractionallySizedBox 0.85), the layout the Android leg
      // exercised. This is where a footer could be pushed off-screen.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await runReachabilityCase(tester);
    },
  );
}
