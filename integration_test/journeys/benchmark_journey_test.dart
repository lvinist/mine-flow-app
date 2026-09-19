// E2E Critical User Journey: Benchmark DB (STEP-45.7)
//
// Exercises benchmark creation, persistence, edit (including coordinate and CRS persistence
// guards CF-033/034), and asserts route registration/deep-link (NR-006 / CF-097).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/benchmark/presentation/pages/benchmark_form_screen.dart';
import 'package:mine_flow/features/benchmark/presentation/pages/benchmark_inspector_screen.dart';
import 'package:mine_flow/features/benchmark/presentation/pages/benchmark_list_screen.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/main.dart' as app_main;
import 'package:mine_flow/app/presentation/pages/app_shell.dart';

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Benchmark DB Journey (STEP-45.7)', () {
    testWidgets(
      'login, navigate via deep link, create benchmark with CRS/coords, edit and verify persistence',
      (tester) async {
        if (!isStagingConfigured) {
          recordE2eSkipped(
            'benchmark_journey_test: staging credentials absent',
          );
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

        recordE2eExecuted('benchmark_journey_test');

        final storage = SecureStorageService();
        await storage.clearAll();

        // 1. Boot app and log in.
        await pumpApp(tester);
        await loginAsStagingUser(tester);

        expect(authCubit?.state.status, AuthStatus.authenticated);

        // 2. NR-006 / CF-097: Navigate directly to the form route (deep link).
        // This exercises the route registration under /operations/benchmark-db/form
        appRouter.go(AppRoutes.benchmarkForm);
        await tester.pumpAndSettle();

        // Ensure we reached the form AND the shell is still present (didn't drop shell).
        expect(find.byType(BenchmarkFormScreen), findsOneWidget);
        expect(
          find.byType(AppShell),
          findsOneWidget,
          reason: 'NR-006: Form should render within the shell',
        );

        // 3. Fill Benchmark details.
        //
        // STEP-55.4 rebuilt this form on ForUI. Two things moved since STEP-45:
        //   1. the field labels are the real ones the form renders
        //      ('Northing (Y)', 'Easting (X)', 'Tinggi Orthometrik (Z)',
        //      'Tinggi Elipsoid (Opsional)'), not the STEP-45 guesses;
        //   2. CRS / Orde / Status are now `CreatableCombobox`, not Material
        //      `DropdownButtonFormField`, so they are opened by tapping the
        //      hint and picked by the option's semantics label.
        Finder fieldLabelled(String label) => find.descendant(
          of: find.widgetWithText(FTextField, label),
          matching: find.byType(EditableText),
        );

        final uniqueBmId = 'BM-${DateTime.now().millisecondsSinceEpoch}';
        final bmIdField = fieldLabelled('BM ID');
        await tester.enterText(bmIdField, uniqueBmId);

        // CF-077: decimal and signed allowed
        await tester.enterText(fieldLabelled('Northing (Y)'), '-8500000.123');
        await tester.enterText(fieldLabelled('Easting (X)'), '300000.456');

        final orthoField = fieldLabelled('Tinggi Orthometrik (Z)');
        await tester.enterText(orthoField, '150.5');
        await tester.enterText(
          fieldLabelled('Tinggi Elipsoid (Opsional)'),
          '152.0',
        );

        await tester.pumpAndSettle();

        // 4. Select CRS (CF-033) through the shared combobox. The dropdown opens
        // on focus via the field's opaque GestureDetector, so tapping the hint
        // is absorbed by design — hence warnIfMissed: false (same idiom the
        // cut/fill journey uses; proof:
        // test/core/presentation/widgets/creatable_combobox_open_test.dart).
        final crsHint = find.text('Pilih sistem proyeksi...');
        expect(crsHint, findsOneWidget);
        await tester.ensureVisible(crsHint);
        await tester.pumpAndSettle();
        await tester.tap(crsHint, warnIfMissed: false);
        await tester.pumpAndSettle();
        final crsItem = find.bySemanticsLabel('UTM Zone 51S');
        expect(crsItem, findsOneWidget);
        await tester.ensureVisible(crsItem);
        await tester.pumpAndSettle();
        await tester.tap(crsItem);
        await tester.pumpAndSettle();

        // Select Status
        final statusHint = find.text('Pilih Status...');
        expect(statusHint, findsOneWidget);
        await tester.ensureVisible(statusHint);
        await tester.pumpAndSettle();
        await tester.tap(statusHint, warnIfMissed: false);
        await tester.pumpAndSettle();
        final statusItem = find.bySemanticsLabel('active');
        expect(statusItem, findsOneWidget);
        await tester.ensureVisible(statusItem);
        await tester.pumpAndSettle();
        await tester.tap(statusItem);
        await tester.pumpAndSettle();

        // 5. Save. STEP-55.4 gives the form sheet a single footer action,
        // 'Simpan Benchmark', for both create and edit.
        final saveBtn = find.widgetWithText(FButton, 'Simpan Benchmark');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pump();
        for (
          var i = 0;
          i < 50 && find.byType(BenchmarkListScreen).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        // 6. Should navigate back to list
        expect(find.byType(BenchmarkListScreen), findsOneWidget);

        // 7. Verify list reflects it — search by uniqueBmId so it is positioned
        // on-screen regardless of list length from earlier staging runs.
        final searchField = find.descendant(
          of: find.byType(BenchmarkListScreen),
          matching: find.byType(FTextField),
        );
        final searchEditable = find.descendant(
          of: searchField,
          matching: find.byType(EditableText),
        );
        expect(searchEditable, findsOneWidget);
        await tester.enterText(searchEditable, uniqueBmId);
        await tester.pumpAndSettle();

        final recordCard = find.descendant(
          of: find.byType(FCard),
          matching: find.textContaining(uniqueBmId),
        );
        for (var i = 0; i < 50 && recordCard.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(recordCard, findsOneWidget);

        // Dismiss keyboard from search entry
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        // 8. Open for edit to assert persistence.
        //
        // STEP-55.11: the list card opens the read-only inspector
        // (`benchmark-detail` → BenchmarkInspectorScreen), not the form. The
        // edit route is pushed from the inspector's pencil button
        // (`benchmark-edit` → BenchmarkFormScreen), so tap through it.
        await tester.ensureVisible(recordCard);
        await tester.tap(recordCard);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkInspectorScreen), findsOneWidget);
        final inspectorEditBtn = find.byKey(const Key('benchmark_edit_button'));
        expect(inspectorEditBtn, findsOneWidget);
        await tester.ensureVisible(inspectorEditBtn);
        await tester.tap(inspectorEditBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);

        // 9. Assert current semantics explicitly on the repository data.
        final benchmarks = await app_main.appServices!.benchmarkRepository
            .getBenchmarks();
        final savedRecord = benchmarks.firstWhere((r) => r.bmId == uniqueBmId);

        expect(savedRecord.northing, closeTo(-8500000.123, 0.001));
        expect(savedRecord.easting, closeTo(300000.456, 0.001));
        expect(savedRecord.crsIdentifier, 'UTM Zone 51S');
        expect(savedRecord.orthoHeight, closeTo(150.5, 0.001));
        expect(savedRecord.status, 'active');

        // Edit
        await tester.enterText(orthoField, '155.0');
        await tester.pumpAndSettle();

        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        final updateBtn = find.widgetWithText(FButton, 'Simpan Benchmark');
        await tester.ensureVisible(updateBtn);
        await tester.pumpAndSettle();
        await tester.tap(updateBtn);
        await tester.pump();
        for (
          var i = 0;
          i < 50 && find.byType(BenchmarkListScreen).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        // Should return to list
        expect(find.byType(BenchmarkListScreen), findsOneWidget);

        final updatedBenchmarks = await app_main
            .appServices!
            .benchmarkRepository
            .getBenchmarks();
        final updatedRecord = updatedBenchmarks.firstWhere(
          (r) => r.bmId == uniqueBmId,
        );
        expect(updatedRecord.orthoHeight, closeTo(155.0, 0.001));

        // Cleanup the test benchmark so it doesn't pollute staging db
        await app_main.appServices!.benchmarkRepository.deleteBenchmark(
          savedRecord.id,
        );
      },
    );
  });
}
