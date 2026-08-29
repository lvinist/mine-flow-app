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
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

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
        // STEP-48.1: the STEP-45 finders anchored on `find.widgetWithText(Column,
        // 'Northing (Y)')` / `'Easting (X)'` / `'Ortho Height'` / `'Ellips
        // Height'`. None of those labels exist — the form renders 'Northing (m)',
        // 'Easting (m)', 'Ortho Height (m)', 'Ellips Height (m)'
        // (benchmark_form_screen.dart). They would have failed for the wrong
        // reason. Anchoring on the FTextField that owns each label is also
        // unambiguous, whereas `Column` matched several nested ancestors.
        Finder fieldLabelled(String label) => find.descendant(
          of: find.widgetWithText(FTextField, label),
          matching: find.byType(EditableText),
        );

        final bmIdField = fieldLabelled('BM ID');
        await tester.enterText(bmIdField, 'BM-TEST-01');

        // CF-077: decimal and signed allowed
        await tester.enterText(fieldLabelled('Northing (m)'), '-8500000.123');
        await tester.enterText(fieldLabelled('Easting (m)'), '300000.456');

        final orthoField = fieldLabelled('Ortho Height (m)');
        await tester.enterText(orthoField, '150.5');
        await tester.enterText(fieldLabelled('Ellips Height (m)'), '152.0');

        await tester.pumpAndSettle();

        // 4. Select CRS (CF-033).
        //
        // STEP-48.1: the STEP-45 finders used
        // `find.byType(DropdownButtonFormField<String>).first` for CRS and
        // `.last` for Status. Both are wrong: the form builds three of them in
        // the order Status (l.214) → CRS (l.250) → Orde (l.396), so `.first` was
        // the Status dropdown (which has no 'UTM Zone 51S' item) and `.last` was
        // Orde. Anchor each dropdown to its own label instead of tree order.
        Finder dropdownLabelled(String label) => find.descendant(
          of: find
              .ancestor(of: find.text(label), matching: find.byType(Column))
              .first,
          matching: find.byType(DropdownButtonFormField<String>),
        );

        final crsDropdown = dropdownLabelled('CRS');
        expect(crsDropdown, findsOneWidget);
        await tester.tap(crsDropdown);
        await tester.pumpAndSettle();
        final crsItem = find.text('UTM Zone 51S').last;
        await tester.tap(crsItem);
        await tester.pumpAndSettle();

        // Select Status
        final statusDropdown = dropdownLabelled('Status');
        expect(statusDropdown, findsOneWidget);
        await tester.tap(statusDropdown);
        await tester.pumpAndSettle();
        final statusItem = find.text('active').last;
        await tester.tap(statusItem);
        await tester.pumpAndSettle();

        // 5. Save
        final saveBtn = find.widgetWithText(FButton, 'Tambah Benchmark');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 6. Should navigate back to list
        expect(find.byType(BenchmarkListScreen), findsOneWidget);

        // 7. Verify list reflects it
        expect(find.textContaining('BM-TEST-01'), findsWidgets);

        // 8. Open for edit to assert persistence
        final recordCard = find.textContaining('BM-TEST-01').first;
        await tester.tap(recordCard);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);

        // 9. Assert current semantics explicitly on the repository data.
        final benchmarks = await app_main.appServices!.benchmarkRepository
            .getBenchmarks();
        final savedRecord = benchmarks.firstWhere(
          (r) => r.bmId == 'BM-TEST-01',
        );

        expect(savedRecord.northing, closeTo(-8500000.123, 0.001));
        expect(savedRecord.easting, closeTo(300000.456, 0.001));
        expect(savedRecord.crsIdentifier, 'UTM Zone 51S');
        expect(savedRecord.orthoHeight, closeTo(150.5, 0.001));
        expect(savedRecord.status, 'active');

        // Edit
        await tester.enterText(orthoField, '155.0');
        await tester.pumpAndSettle();

        final updateBtn = find.widgetWithText(FButton, 'Simpan');
        await tester.ensureVisible(updateBtn);
        await tester.tap(updateBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should return to list
        expect(find.byType(BenchmarkListScreen), findsOneWidget);

        final updatedBenchmarks = await app_main
            .appServices!
            .benchmarkRepository
            .getBenchmarks();
        final updatedRecord = updatedBenchmarks.firstWhere(
          (r) => r.bmId == 'BM-TEST-01',
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
