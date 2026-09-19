// E2E Critical User Journey: Reporting (STEP-45.9)
//
// Exercises report generation, asserting that it does not crash,
// handles mid-run config changes (by locking controls), and confirms CF-030/CF-073.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/report_config_content.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/date_range_selector.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_state.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

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
          recordE2eSkipped(
            'reporting_journey_test: staging credentials absent',
          );
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

        recordE2eExecuted('reporting_journey_test');

        final storage = SecureStorageService();
        await storage.clearAll();

        // 1. Boot app and log in.
        await pumpApp(tester);
        await loginAsStagingUser(tester);

        expect(authCubit?.state.status, AuthStatus.authenticated);

        // 2. Navigate to Cut/Fill list and open its contextual report dialog.
        appRouter.go(AppRoutes.cutFill);
        await tester.pumpAndSettle();

        final reportBtnFinder = find.bySemanticsLabel('Buat Laporan Cut/Fill');
        await tester.ensureVisible(reportBtnFinder);
        await tester.tap(reportBtnFinder);
        await tester.pumpAndSettle();

        // STEP-55.1 replaced the pushed `ReportConfigPage` route with the shared
        // contextual dialog (`showAppContextualReportDialog`), which reuses
        // `ReportConfigContent` inside an `AppContextualReportDialog`. The origin
        // route stays mounted behind it — that is the design, not a defect.
        expect(find.byType(AppContextualReportDialog), findsOneWidget);

        // Confirm DateRangeSelector is present (CF-073).
        expect(find.byType(DateRangeSelector), findsOneWidget);

        // Tap Generate.
        //
        // Keyed, not text-matched: while generating, the button's child swaps
        // from the 'Buat Laporan' label to a spinner, so a text finder cannot
        // locate it in the very state NR-001 asserts about. The assertion below
        // is unchanged — `onPress` must be null while locked.
        final generateBtn = find.byKey(const Key('generate_report_button'));
        expect(generateBtn, findsOneWidget);
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
        final BuildContext ctx = tester.element(
          find.byType(ReportConfigContent),
        );
        final cubit = ctx.read<ReportCubit>();
        expect(cubit.state, isA<ReportLoading>());

        // PDF generation includes staging I/O that is not represented by
        // scheduled Flutter frames on Android. Wait for the cubit outcome,
        // then settle the success view.
        for (var i = 0; i < 600 && cubit.state is ReportLoading; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        // Verify Success view
        //
        // STEP-55.11: the success buttons render localized labels
        // (printReport / sharePdf / regenerateReport), never hardcoded
        // Indonesian copy. Resolve them from the active locale so the
        // journey is correct whatever the device default is.
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ReportConfigContent)),
        );
        expect(find.text(l10n.printReport), findsOneWidget);
        expect(find.text(l10n.sharePdf), findsOneWidget);
        expect(find.text(l10n.regenerateReport), findsOneWidget);

        expect(cubit.state, isA<ReportSuccess>());
        final successState = cubit.state as ReportSuccess;
        expect(
          successState.result.pdfBytes.isNotEmpty,
          isTrue,
          reason: 'PDF must be generated',
        );

        // Test Buat Ulang (Regenerate) to ensure controls are re-enabled
        await tester.tap(find.text(l10n.regenerateReport));
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

        // Test Attendance report too.
        //
        // STEP-55.11: the first report's dialog is still on the root
        // navigator's stack. Its modal barrier absorbs the next FAB tap, so
        // close it explicitly before navigating — `appRouter.go` replaces the
        // go_router stack but does not dispose a dialog pushed via the root
        // navigator. The dialog's accessible close button carries the
        // sheetBarrierLabel semantics ("Close sheet").
        final firstDialog = find.byType(AppContextualReportDialog);
        if (firstDialog.evaluate().isNotEmpty) {
          // STEP-55.11: the dialog's close control is an
          // AppAccessibleIconButton with Icons.close (its semantics carry the
          // sheetBarrierLabel). Match by widget type + icon — semantics-label
          // matching is unreliable when the node merges with the tooltip.
          final closeBtn = find.descendant(
            of: firstDialog.first,
            matching: find.byWidgetPredicate(
              (w) => w is AppAccessibleIconButton && w.icon == Icons.close,
            ),
          );
          expect(closeBtn, findsOneWidget);
          await tester.tap(closeBtn);
          await tester.pumpAndSettle();
        }
        appRouter.go(AppRoutes.attendance);
        await tester.pumpAndSettle();

        // STEP-55.11: the attendance screen loads the roster asynchronously
        // and the report FAB is only interactive once AttendanceLoaded. The
        // HTTP completion does not schedule a Flutter frame on Android, so
        // pumpAndSettle can return before the load resolves and the FAB's
        // semantics are absent. Wait for the loaded state explicitly, reading
        // the bloc from AttendanceView — AttendanceScreen's BlocProvider is
        // created in its own build, so the screen's element sits above it.
        final attendanceCtx = tester.element(find.byType(AttendanceView));
        final attendanceBloc = attendanceCtx.read<AttendanceBloc>();
        for (
          var i = 0;
          i < 600 && attendanceBloc.state is! AttendanceLoaded;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        // STEP-55.11: the Semantics wrapper merges its label into the
        // FloatingActionButton's merged semantics node, so the label lives on
        // the *merged* node — find it on the FAB itself, whose merged
        // semantics carry both the Semantics label and the button flag.
        final reportAttFinder = find.byWidgetPredicate(
          (w) =>
              w is FloatingActionButton && w.heroTag == 'report_attendance_btn',
        );
        expect(
          reportAttFinder,
          findsOneWidget,
          reason: 'Report button must exist on Attendance page',
        );
        await tester.ensureVisible(reportAttFinder);
        await tester.tap(reportAttFinder);
        await tester.pumpAndSettle();

        // STEP-55.11: the report dialog loads its config (zones/date range)
        // asynchronously after the FAB tap. The generate button is always
        // built, but on web the dialog's first frame can land before its
        // content subtree is interactive, so pump in bounded slices until
        // the button resolves before tapping.
        final attendanceGenerateBtn = find.byKey(
          const Key('generate_report_button'),
        );
        for (
          var i = 0;
          i < 50 && attendanceGenerateBtn.evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.ensureVisible(attendanceGenerateBtn);
        await tester.tap(attendanceGenerateBtn);
        final attendanceContext = tester.element(
          find.byType(ReportConfigContent),
        );
        final attendanceCubit = attendanceContext.read<ReportCubit>();
        for (
          var i = 0;
          i < 600 && attendanceCubit.state is ReportLoading;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        expect(find.text(l10n.printReport), findsOneWidget);
      },
    );
  });
}
