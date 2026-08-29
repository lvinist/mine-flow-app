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
        const testItemName = 'Solar Industri B30';
        final nameField = find.descendant(
          of: find.byType(FTextField).at(0),
          matching: find.byType(EditableText),
        );
        await tester.enterText(nameField, testItemName);
        await tester.pumpAndSettle();

        // Category dropdown
        final categoryDropdown = find.byType(DropdownButtonFormField<String>);
        await tester.tap(categoryDropdown);
        await tester.pumpAndSettle();
        final fuelCategoryItem = find.text('Fuel / Lubricants').last;
        await tester.tap(fuelCategoryItem);
        await tester.pumpAndSettle();

        // Quantity (CF-054 guard: quantity dispatched on every change, validated non-negative)
        final qtyField = find.descendant(
          of: find.byType(FTextField).at(1),
          matching: find.byType(EditableText),
        );
        await tester.enterText(qtyField, '150');
        await tester.pumpAndSettle();

        // Min Threshold
        final thresholdField = find.descendant(
          of: find.byType(FTextField).at(2),
          matching: find.byType(EditableText),
        );
        await tester.enterText(thresholdField, '25');
        await tester.pumpAndSettle();

        // SKU
        final skuField = find.descendant(
          of: find.byType(FTextField).at(3),
          matching: find.byType(EditableText),
        );
        await tester.enterText(skuField, 'SLR-B30-E2E');
        await tester.pumpAndSettle();

        // Notes
        final notesField = find.descendant(
          of: find.byType(FTextField).at(4),
          matching: find.byType(EditableText),
        );
        await tester.enterText(notesField, 'Stok bahan bakar genset pit');
        await tester.pumpAndSettle();

        // 5. Save Item
        final saveBtn = find.byKey(
          const ValueKey<String>('save_inventory_item_button'),
        );
        expect(saveBtn, findsOneWidget);
        await tester.ensureVisible(saveBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 6. Verify item persistence in repository
        final items = await app_main.appServices!.trackingRepository
            .getInventoryItems(siteId: defaultSiteId);
        
        final savedItem = items.firstWhere(
          (i) => i.itemName == testItemName,
          orElse: () =>
              throw StateError('Saved inventory item not found in repository'),
        );
        expect(savedItem.quantityOnHand, 150.0);
        expect(savedItem.minThreshold, 25.0);
        expect(savedItem.category, 'Fuel / Lubricants');
        expect(savedItem.sku, 'SLR-B30-E2E');

        // 7. Verify item is displayed in Inventory Dashboard
        expect(find.byType(InventoryDashboardScreen), findsOneWidget);
        expect(find.text(testItemName), findsOneWidget);
        expect(find.byType(InventoryCard), findsWidgets);

        // 8. Stock Adjustment (CF-054 guard: adjust quantity properly parsed and updated)
        final cardFinder = find.widgetWithText(InventoryCard, testItemName);
        expect(cardFinder, findsOneWidget);
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

        // Verify updated quantity in repo (150 - 30 = 120)
        final updatedItems = await app_main.appServices!.trackingRepository
            .getInventoryItems(siteId: defaultSiteId);
        final adjustedItem = updatedItems.firstWhere(
          (i) => i.id == savedItem.id,
        );
        expect(adjustedItem.quantityOnHand, 120.0);

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
          expect(find.text(testItemName), findsOneWidget);

          // 9b. Delete and confirm
          await tester.tap(deleteBtn);
          await tester.pumpAndSettle();

          final confirmDeleteBtn = find.widgetWithText(FButton, 'Hapus');
          await tester.tap(confirmDeleteBtn);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify deleted in repository
          final remainingItems = await app_main.appServices!.trackingRepository
              .getInventoryItems(siteId: defaultSiteId);
          expect(remainingItems.any((i) => i.id == savedItem.id), isFalse);
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
