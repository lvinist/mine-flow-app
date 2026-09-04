// E2E Critical User Journey: Inventory (STEP-45.6)
//
// Exercises inventory item creation, stock adjustment (+/-), non-negative quantity
// validation (CF-054 guard), supervisor role-gated deletion confirmation (CF-019 guard),
// and dashboard list / summary reflection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_dashboard_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_item_entry_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/stock_adjustment_dialog.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/inventory_card.dart';
import 'package:mine_flow/main.dart' as app_main;

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Inventory Journey (STEP-45.6)', () {
    testWidgets(
      'login, add inventory item, stock adjust with non-negative validation (CF-054), attempt delete with confirm/role gate (CF-019), and reflect list state E2E',
      (tester) async {
        if (!isStagingConfigured) {
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

        final storage = SecureStorageService();
        await storage.clearAll();

        // 1. Boot app and log in as staging user.
        await pumpApp(tester);
        await loginAsStagingUser(tester);

        expect(authCubit?.state.status, AuthStatus.authenticated);

        // 2. Navigate to Inventory screen.
        appRouter.go(AppRoutes.inventory);
        await tester.pumpAndSettle();

        expect(find.byType(InventoryDashboardScreen), findsOneWidget);

        // 3. Open Inventory Item Entry screen via FAB.
        final addFab = find.byWidgetPredicate(
          (w) => w is FloatingActionButton && w.heroTag == 'add_inventory_btn',
        );
        expect(addFab, findsOneWidget);
        await tester.tap(addFab);
        await tester.pumpAndSettle();

        expect(find.byType(InventoryItemEntryScreen), findsOneWidget);

        // 4. Enter Item Details. Target EditableText finders due to RISK-0009.
        // Item Name
        final testItemName =
            'Solar Industri B30 ${DateTime.now().millisecondsSinceEpoch}';
        final formScope = find.byType(InventoryItemEntryScreen);
        final nameField = find.descendant(
          of: find
              .descendant(of: formScope, matching: find.byType(FTextField))
              .at(0),
          matching: find.byType(EditableText),
        );
        await tester.enterText(nameField, testItemName);
        await tester.pumpAndSettle();

        // Category dropdown.
        //
        // STEP-48.21 R-4 web-leg: tester.tap is hit-testing based and misses
        // silently on web when the target is not where hit-testing expects;
        // a missed selection leaves category null and the save then bounces
        // off CF-038 validation (nothing saved, snackbar long gone by the
        // read-back). Confirm the selection landed in the closed-state field
        // (the selected value renders as text) and retry once if not.
        final categoryDropdown = find.descendant(
          of: formScope,
          matching: find.byType(DropdownButtonFormField<String>),
        );
        Future<bool> selectCategory() async {
          await tester.tap(categoryDropdown);
          await tester.pumpAndSettle();
          final fuelCategoryItem = find.text('Fuel / Lubricants').last;
          // `.last` targets the active overlay menu item: while the dropdown
          // is open the selected-value Text is hidden behind the overlay, so
          // the last match in traversal order is the menu tile (same pattern
          // as the benchmark journey's dropdown items).
          await tester.tap(fuelCategoryItem);
          await tester.pumpAndSettle();
          for (var i = 0; i < 20; i++) {
            if (find.text('Fuel / Lubricants').evaluate().isNotEmpty) {
              return true;
            }
            await tester.pump(const Duration(milliseconds: 100));
          }
          return false;
        }

        final categorySelected = await selectCategory();
        // One retry — the open-affordance may have consumed the first tap.
        final categorySelectedAfterRetry =
            categorySelected || await selectCategory();
        // Enforce the selection: a silently missed dropdown tap leaves
        // category null, the save bounces off CF-038 validation, and the
        // journey fails later with an unrecognizable read-back symptom
        // (web run 3 of the R-4 pass). Fail here, with the cause named.
        expect(
          categorySelectedAfterRetry,
          isTrue,
          reason:
              'The category selection did not land after two attempts — '
              'the dropdown open-tap or menu-item tap is missing its target '
              '(web hit-test offset); the save would be rejected by CF-038.',
        );

        // Quantity (CF-054 guard: quantity dispatched on every change, validated non-negative)
        final qtyField = find.descendant(
          of: find
              .descendant(of: formScope, matching: find.byType(FTextField))
              .at(1),
          matching: find.byType(EditableText),
        );
        await tester.enterText(qtyField, '150');
        await tester.pumpAndSettle();

        // Min Threshold
        final thresholdField = find.descendant(
          of: find
              .descendant(of: formScope, matching: find.byType(FTextField))
              .at(2),
          matching: find.byType(EditableText),
        );
        await tester.enterText(thresholdField, '25');
        await tester.pumpAndSettle();

        // SKU
        final skuField = find.descendant(
          of: find
              .descendant(of: formScope, matching: find.byType(FTextField))
              .at(3),
          matching: find.byType(EditableText),
        );
        await tester.enterText(
          skuField,
          'SLR-B30-E2E-${DateTime.now().millisecondsSinceEpoch}',
        );
        await tester.pumpAndSettle();

        // Notes
        final notesField = find.descendant(
          of: find
              .descendant(of: formScope, matching: find.byType(FTextField))
              .at(4),
          matching: find.byType(EditableText),
        );
        await tester.enterText(notesField, 'Stok bahan bakar genset pit');
        await tester.pumpAndSettle();

        // 5. Save Item.
        //
        // STEP-48.21 R-4 web-leg: the same hit-testing miss class as the
        // category dropdown — a silently missed save tap leaves nothing
        // saved and no error. `ensureVisible` guarantees the button is in
        // the hit-test region before tapping; the post-tap reason names a
        // missed tap explicitly if the save still did not fire.
        final saveBtn = find.byKey(
          const ValueKey<String>('save_inventory_item_button'),
        );
        expect(saveBtn, findsOneWidget);
        await tester.ensureVisible(saveBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveBtn, warnIfMissed: true);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        // Post-tap state gate: success pops the form within 600 ms; a CF-038
        // validation failure or a save exception shows a snackbar and keeps
        // the form open. Both are legitimate. A form still open with NO
        // snackbar means the tap never reached the button (web hit-test
        // miss) and nothing was saved.
        String snackbarEvidence = 'none';
        final entryScreenGone = find
            .byType(InventoryItemEntryScreen)
            .evaluate()
            .isEmpty;
        final snackbarShown = find.byType(SnackBar).evaluate().isNotEmpty;
        if (snackbarShown) {
          // Capture the snackbar text NOW — it is dead within 4 s and the
          // later read-back diagnostics run after it is gone (web logs carry
          // no app-side output, so this is the only chance to record it).
          snackbarEvidence = find
              .descendant(
                of: find.byType(SnackBar),
                matching: find.byWidgetPredicate(
                  (w) => w is Text && w.data != null,
                ),
              )
              .evaluate()
              .map((e) => (e.widget as Text).data)
              .join(' | ');
        }
        expect(
          entryScreenGone || snackbarShown,
          isTrue,
          reason:
              'After the save tap the form is still open with no snackbar — '
              'the tap did not reach the button (web hit-test miss) and '
              'nothing was saved.',
        );

        // 6. Verify item persistence in repository.
        //
        // STEP-48.21 (48.26 re-run 2, R-4 web leg): on web, Hive is
        // IndexedDB-backed with real async I/O — `pumpAndSettle` returns
        // before the save's local put completes, so a single-shot read-back
        // raced the write and threw `Bad state: Saved inventory item not
        // found in repository` (:139). Poll the repository read-back with a
        // bounded loop (same repair the cut/fill journey received for its
        // read-back). A poll that expires still fails at the same assertion,
        // so a genuinely lost write stays an honest failure.
        List<InventoryItem> items = [];
        InventoryItem? savedItem;
        for (var i = 0; i < 30 && savedItem == null; i++) {
          items = await app_main.appServices!.trackingRepository
              .getInventoryItems(siteId: defaultSiteId);
          savedItem = items
              .where((i) => i.itemName == testItemName)
              .firstOrNull;
          if (savedItem == null) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        expect(
          savedItem,
          isNotNull,
          reason: () {
            // STEP-48.21 R-4 web-leg diagnostics: web logs carry no app-side
            // output, so on failure the reason must carry the discriminating
            // evidence itself — did the save succeed (success snackbar /
            // row elsewhere), fail validation (error snackbar), or never
            // fire (neither)? Pure read-only diagnosis; no assertion change.
            final snackbarTexts = find
                .descendant(
                  of: find.byType(SnackBar),
                  matching: find.byWidgetPredicate(
                    (w) => w is Text && w.data != null,
                  ),
                )
                .evaluate()
                .map((e) => (e.widget as Text).data)
                .toList();
            return 'Saved inventory item "$testItemName" not found in '
                'repository after ${30} polls; last read returned '
                '${items.length} items (names: ${items.take(5).map((i) => i.itemName).toList()}); '
                'snackbars visible: $snackbarTexts; gate-time snackbar: '
                '$snackbarEvidence';
          }(),
        );
        expect(savedItem!.quantityOnHand, 150.0);
        expect(savedItem.minThreshold, 25.0);
        expect(savedItem.category, 'Fuel / Lubricants');
        expect(savedItem.sku, startsWith('SLR-B30-E2E-'));
        final savedItemId = savedItem.id;

        // 7. Verify item is displayed in Inventory Dashboard
        expect(find.byType(InventoryDashboardScreen), findsOneWidget);
        final cardFinder = find.widgetWithText(InventoryCard, testItemName);
        for (var i = 0; i < 50 && cardFinder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(cardFinder, findsOneWidget);
        expect(find.byType(InventoryCard), findsWidgets);

        // 8. Stock Adjustment (CF-054 guard: adjust quantity properly parsed and updated)
        await tester.ensureVisible(cardFinder);
        await tester.pumpAndSettle();

        final adjustStockBtn = find.descendant(
          of: cardFinder,
          matching: find.byIcon(LucideIcons.shoppingCart),
        );
        expect(adjustStockBtn, findsOneWidget);
        await tester.tap(adjustStockBtn);
        await tester.pumpAndSettle();

        expect(find.byType(StockAdjustmentDialog), findsOneWidget);

        // Toggle 'Kurang' (decrement)
        final kurangBtn = find.widgetWithText(FButton, 'Kurang');
        await tester.tap(kurangBtn);
        await tester.pumpAndSettle();

        final adjustQtyInput = find.byKey(
          const ValueKey<String>('adjust_quantity_input'),
        );
        await tester.enterText(adjustQtyInput, '30');
        await tester.pumpAndSettle();

        final confirmAdjustBtn = find.byKey(
          const ValueKey<String>('confirm_adjust_stock_button'),
        );
        await tester.tap(confirmAdjustBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify updated quantity in repo (150 - 30 = 120).
        //
        // STEP-48.21 (R-4 web-leg sweep): same single-shot race as the
        // step-6 read-back — poll briefly so a real async local write that
        // has not landed yet is waited for. If expiry coincides with the
        // clobber defect the assertion still fails on the stale value.
        InventoryItem? adjustedItem;
        for (var i = 0; i < 30 && adjustedItem?.quantityOnHand != 120.0; i++) {
          final updatedItems = await app_main.appServices!.trackingRepository
              .getInventoryItems(siteId: defaultSiteId);
          adjustedItem = updatedItems
              .where((i) => i.id == savedItemId)
              .firstOrNull;
          if (adjustedItem?.quantityOnHand != 120.0) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        expect(adjustedItem?.quantityOnHand, 120.0);

        // 9. Delete Item and Confirm/Role Gate (CF-019 guard)
        final cardFinderForDelete = find.widgetWithText(
          InventoryCard,
          testItemName,
        );
        await tester.ensureVisible(cardFinderForDelete);
        await tester.pumpAndSettle();

        final deleteBtn = find.descendant(
          of: cardFinderForDelete,
          matching: find.byIcon(LucideIcons.trash2),
        );
        expect(deleteBtn, findsOneWidget);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        final currentUser = authCubit?.state.user;
        if (currentUser != null && currentUser.isSupervisor) {
          // Destructive confirmation dialog shown
          expect(find.text('Hapus Data'), findsOneWidget);

          // 9a. Cancel first
          final cancelBtn = find.widgetWithText(FButton, 'Batal');
          await tester.tap(cancelBtn);
          await tester.pumpAndSettle();

          // Item still exists
          expect(
            find.widgetWithText(InventoryCard, testItemName),
            findsOneWidget,
          );

          // 9b. Delete and confirm
          await tester.tap(deleteBtn);
          await tester.pumpAndSettle();

          final confirmDeleteBtn = find.widgetWithText(FButton, 'Hapus');
          await tester.tap(confirmDeleteBtn);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify deleted in repository.
          //
          // STEP-48.21 (R-4 web-leg sweep): bounded poll, same class as the
          // step-6/step-8 read-backs — the soft-delete is a local write with
          // real async I/O on web.
          var deleted = false;
          for (var i = 0; i < 30 && !deleted; i++) {
            final remainingItems = await app_main
                .appServices!
                .trackingRepository
                .getInventoryItems(siteId: defaultSiteId);
            deleted = !remainingItems.any((i) => i.id == savedItemId);
            if (!deleted) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }
          expect(deleted, isTrue);
        } else {
          // Non-supervisor: role-gated snackbar shown
          expect(
            find.text('Hanya supervisor yang dapat menghapus data.'),
            findsOneWidget,
          );
        }
      },
    );
  });
}
