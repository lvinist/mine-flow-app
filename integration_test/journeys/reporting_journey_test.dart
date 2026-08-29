// E2E Critical User Journey: Reporting (STEP-45.9)
//
// Exercises report generation, asserting that it does not crash,
// handles mid-run config changes (by locking controls), and confirms CF-030/CF-073.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/reporting/presentation/pages/report_config_page.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/date_range_selector.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_state.dart';

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Reporting Journey (STEP-45.9)', () {
    testWidgets(
      'login, navigate to feature screens, open reports, and verify mid-run config lock',
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

        // 2. Navigate to Cut/Fill list and open its Report Config
        appRouter.go(AppRoutes.cutFill);
        await tester.pumpAndSettle();

        // Wait, tooltip might not be set. Let's use Semantics label or byIcon.
        final reportBtnFinder = find.bySemanticsLabel('Buat Laporan Cut/Fill');
        await tester.ensureVisible(reportBtnFinder);
        await tester.tap(reportBtnFinder);
        await tester.pumpAndSettle();

        expect(find.byType(ReportConfigPage), findsOneWidget);

        // Confirm DateRangeSelector is present (CF-073).
        expect(find.byType(DateRangeSelector), findsOneWidget);

        // Tap Generate
        final generateBtn = find.widgetWithText(FButton, 'Buat Laporan');
        await tester.tap(generateBtn);
        // We only pump once to trigger the event loop which synchronously emits ReportLoading.
        await tester.pump();

        // 4. While loading, controls should be disabled (NR-001).
        final dateSelector = tester.widget<DateRangeSelector>(
          find.byType(DateRangeSelector),
        );
        expect(dateSelector.enabled, isFalse);

        final zonePicker = tester.widget<ZonePicker>(find.byType(ZonePicker));
        expect(zonePicker.enabled, isFalse);

        final generateBtnWidget = tester.widget<FButton>(generateBtn);
        expect(
          generateBtnWidget.onPress,
          isNull,
          reason: 'Generate button should be disabled during generation',
        );

        // Verify cubit state is deterministic
        final BuildContext ctx = tester.element(find.byType(ReportConfigPage));
        final cubit = ctx.read<ReportCubit>();
        expect(cubit.state, isA<ReportLoading>());

        await tester.pumpAndSettle(); // Wait for generation to finish.

        // Verify Success view
        expect(find.text('Cetak'), findsOneWidget);
        expect(find.text('Bagikan PDF'), findsOneWidget);
        expect(find.text('Buat Ulang'), findsOneWidget);

        expect(cubit.state, isA<ReportSuccess>());
        final successState = cubit.state as ReportSuccess;
        expect(
          successState.result.pdfBytes.isNotEmpty,
          isTrue,
          reason: 'PDF must be generated',
        );

        // Test Buat Ulang (Regenerate) to ensure controls are re-enabled
        await tester.tap(find.text('Buat Ulang'));
        await tester.pumpAndSettle();

        expect(find.byType(DateRangeSelector), findsOneWidget);
        final dateSelectorAfter = tester.widget<DateRangeSelector>(
          find.byType(DateRangeSelector),
        );
        expect(
          dateSelectorAfter.enabled,
          isTrue,
          reason: 'Controls should be re-enabled after Buat Ulang',
        );

        // Test Attendance report too
        appRouter.go(AppRoutes.attendance);
        await tester.pumpAndSettle();

        final reportAttFinder = find.bySemanticsLabel('Buat Laporan Kehadiran');
        expect(
          reportAttFinder,
          findsOneWidget,
          reason: 'Report button must exist on Attendance page',
        );
        await tester.ensureVisible(reportAttFinder);
        await tester.tap(reportAttFinder);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FButton, 'Buat Laporan'));
        await tester.pumpAndSettle();

        expect(find.text('Cetak'), findsOneWidget);
      },
    );
  });
}
