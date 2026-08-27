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

        // 3. Fill Benchmark details
        final bmIdField = find.descendant(
          of: find.widgetWithText(Column, 'BM ID'),
          matching: find.byType(EditableText),
        );
        await tester.enterText(bmIdField, 'BM-TEST-01');

        final northingField = find.descendant(
          of: find.widgetWithText(Column, 'Northing (Y)'),
          matching: find.byType(EditableText),
        );
        // CF-077: decimal and signed allowed
        await tester.enterText(northingField, '-8500000.123');

        final eastingField = find.descendant(
          of: find.widgetWithText(Column, 'Easting (X)'),
          matching: find.byType(EditableText),
        );
        await tester.enterText(eastingField, '300000.456');

        final orthoField = find.descendant(
          of: find.widgetWithText(Column, 'Ortho Height'),
          matching: find.byType(EditableText),
        );
        await tester.enterText(orthoField, '150.5');

        final ellipsField = find.descendant(
          of: find.widgetWithText(Column, 'Ellips Height'),
          matching: find.byType(EditableText),
        );
        await tester.enterText(ellipsField, '152.0');

        await tester.pumpAndSettle();

        // 4. Select CRS (CF-033)
        final crsDropdown = find.byType(DropdownButtonFormField<String>).first;
        await tester.tap(crsDropdown);
        await tester.pumpAndSettle();
        final crsItem = find.text('UTM Zone 51S').last;
        await tester.tap(crsItem);
        await tester.pumpAndSettle();

        // Select Status
        final statusDropdown = find
            .byType(DropdownButtonFormField<String>)
            .last;
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
