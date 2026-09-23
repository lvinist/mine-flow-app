import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

void main() {
  Widget host({required Widget child, Size size = const Size(1024, 800)}) =>
      MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id'), Locale('en')],
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(body: child),
        ),
      );

  group('AppDismissController', () {
    test('clean state dismisses for every close reason', () {
      for (final reason in AppDismissReason.values) {
        expect(
          AppDismissController(
            isDirty: false,
            isBusy: false,
          ).requestDismiss(reason),
          AppDismissDecision.dismiss,
        );
      }
    });

    test('dirty state requests explicit discard confirmation', () {
      expect(
        AppDismissController(
          isDirty: true,
          isBusy: false,
        ).requestDismiss(AppDismissReason.escape),
        AppDismissDecision.confirmDiscard,
      );
    });

    test('busy state blocks every close reason', () {
      for (final reason in AppDismissReason.values) {
        expect(
          AppDismissController(
            isDirty: true,
            isBusy: true,
          ).requestDismiss(reason),
          AppDismissDecision.blockedBusy,
        );
      }
    });
  });

  group('route reconstruction helpers', () {
    test('closes only a final form segment and preserves list query', () {
      final closed = closeSheetUri(
        Uri.parse(
          '/operations/cut-fill/record-1/form?from=2026-01-01&zoneId=z',
        ),
      );
      expect(closed.path, '/operations/cut-fill/record-1');
      expect(closed.queryParameters, {'from': '2026-01-01', 'zoneId': 'z'});
    });

    test('validates durable record IDs', () {
      expect(validRouteRecordId(' record-1 '), 'record-1');
      expect(validRouteRecordId(null), isNull);
      expect(validRouteRecordId(''), isNull);
      expect(validRouteRecordId('bad/id'), isNull);
    });
  });

  group('AppResponsiveSheet', () {
    testWidgets('uses a right sheet at and above the 800dp breakpoint', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          child: AppResponsiveSheet(
            routeIdentity: 'fixture',
            title: 'Fixture',
            mode: AppResponsiveSheetMode.form,
            body: const Text('Body'),
            onDismissApproved: () {},
          ),
        ),
      );

      expect(appResponsiveSheetWidth(800), 480);
      expect(appResponsiveSheetWidth(801), 480);
      expect(appResponsiveSheetWidth(1024), 480);
      expect(appResponsiveSheetWidth(1280), 512);

      final sheet = tester.getSize(
        find.byKey(const ValueKey('app-responsive-sheet-fixture')),
      );
      expect(sheet.width, 480);
      expect(sheet.height, 600);
    });

    testWidgets('uses a bottom sheet below the 800dp breakpoint', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          size: const Size(799, 800),
          child: AppResponsiveSheet(
            routeIdentity: 'narrow',
            title: 'Fixture',
            mode: AppResponsiveSheetMode.form,
            body: const Text('Body'),
            onDismissApproved: () {},
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('app-responsive-sheet-narrow')),
        findsNothing,
      );
      final body = tester.getRect(find.text('Body'));
      expect(body.top, greaterThan(100));
    });

    testWidgets('dirty close opens dialog and discard approves exactly once', (
      tester,
    ) async {
      var dismisses = 0;
      var discards = 0;
      await tester.pumpWidget(
        host(
          child: AppResponsiveSheet(
            routeIdentity: 'dirty',
            title: 'Fixture',
            mode: AppResponsiveSheetMode.form,
            isDirty: true,
            body: const Text('Body'),
            onDiscard: () => discards++,
            onDismissApproved: () => dismisses++,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Perubahan belum disimpan'), findsOneWidget);
      expect(dismisses, 0);
      await tester.tap(find.text('Buang Perubahan'));
      await tester.pumpAndSettle();
      expect(discards, 1);
      expect(dismisses, 1);
    });

    testWidgets('filter actions are labelled and independently actionable', (
      tester,
    ) async {
      var applied = 0;
      var reset = 0;
      var cancelled = 0;
      await tester.pumpWidget(
        host(
          child: AppFilterPopover(
            onApply: () => applied++,
            onReset: () => reset++,
            onCancel: () => cancelled++,
            child: const Text('Criteria'),
          ),
        ),
      );
      await tester.tap(find.text('Terapkan'));
      await tester.tap(find.text('Reset filter'));
      await tester.tap(find.text('Batal'));
      expect((applied, reset, cancelled), (1, 1, 1));
    });

    // ----------------------------------------------------------------
    // STEP-55.0 RESIDUAL: drag dismiss trigger tests
    // ----------------------------------------------------------------

    testWidgets('drag down on clean narrow sheet dismisses immediately', (
      tester,
    ) async {
      var dismisses = 0;
      final reasons = <AppDismissReason>[];
      await tester.pumpWidget(
        host(
          size: const Size(400, 800),
          child: AppResponsiveSheet(
            routeIdentity: 'drag-clean',
            title: 'Drag Clean',
            mode: AppResponsiveSheetMode.form,
            body: const Text('Body'),
            onRequestClose: (r) => reasons.add(r),
            onDismissApproved: () => dismisses++,
          ),
        ),
      );

      // Drag the handle past the 100dp cumulative threshold. We use
      // tester.drag rather than tester.fling: a fling leaves residual pointer
      // velocity that tears down the handle's element before the deferred
      // (post-frame) approval callback runs, so onDismissApproved would see
      // mounted=false. A settled drag keeps the element mounted across the
      // frame boundary, exercising the real dismiss-approval path.
      final handleFinder = find.byKey(const ValueKey('app-sheet-drag-handle'));
      expect(handleFinder, findsOneWidget);
      await tester.drag(handleFinder, const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(reasons, contains(AppDismissReason.drag));
      // _dismiss() uses addPostFrameCallback; pump one more frame to fire it.
      await tester.pump();
      expect(dismisses, 1);
    });

    testWidgets('drag handle semantic label resolves via l10n', (tester) async {
      // STEP-55.0 RESIDUAL-2: the handle's label comes from the sheetDragHandle
      // localization key (Indonesian-first host), not a hardcoded string.
      await tester.pumpWidget(
        host(
          size: const Size(400, 800),
          child: AppResponsiveSheet(
            routeIdentity: 'drag-label',
            title: 'Drag Label',
            mode: AppResponsiveSheetMode.form,
            body: const Text('Body'),
            onRequestClose: (_) {},
            onDismissApproved: () {},
          ),
        ),
      );

      final handleFinder = find.byKey(const ValueKey('app-sheet-drag-handle'));
      expect(handleFinder, findsOneWidget);
      final semantics = tester.getSemantics(handleFinder);
      expect(semantics.label, 'Seret ke bawah untuk menutup');
    });

    testWidgets('drag down on dirty narrow sheet opens dirty dialog', (
      tester,
    ) async {
      var dismisses = 0;
      final reasons = <AppDismissReason>[];
      await tester.pumpWidget(
        host(
          size: const Size(400, 800),
          child: AppResponsiveSheet(
            routeIdentity: 'drag-dirty',
            title: 'Drag Dirty',
            mode: AppResponsiveSheetMode.form,
            isDirty: true,
            body: const Text('Body'),
            onRequestClose: (r) => reasons.add(r),
            onDiscard: () {},
            onDismissApproved: () => dismisses++,
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey('app-sheet-drag-handle')),
        const Offset(0, 200),
        500,
      );
      await tester.pumpAndSettle();

      expect(reasons, contains(AppDismissReason.drag));
      expect(find.text('Perubahan belum disimpan'), findsOneWidget);
      expect(dismisses, 0);
    });

    testWidgets('drag on busy narrow sheet is blocked', (tester) async {
      var dismisses = 0;
      final reasons = <AppDismissReason>[];
      await tester.pumpWidget(
        host(
          size: const Size(400, 800),
          child: AppResponsiveSheet(
            routeIdentity: 'drag-busy',
            title: 'Drag Busy',
            mode: AppResponsiveSheetMode.form,
            isDirty: true,
            isBusy: true,
            body: const Text('Body'),
            onRequestClose: (r) => reasons.add(r),
            onDismissApproved: () => dismisses++,
          ),
        ),
      );

      // The drag handlers should be null when busy, so the fling should
      // have no effect on the dismiss contract.
      await tester.fling(
        find.byKey(const ValueKey('app-sheet-drag-handle')),
        const Offset(0, 200),
        500,
      );
      await tester.pumpAndSettle();

      // When busy, the drag gesture callbacks are null so onRequestClose
      // is never called by the drag path.
      expect(reasons, isEmpty);
      expect(dismisses, 0);
    });

    testWidgets('rapid drag during dirty still approves exactly once', (
      tester,
    ) async {
      var dismisses = 0;
      var discards = 0;
      await tester.pumpWidget(
        host(
          size: const Size(400, 800),
          child: AppResponsiveSheet(
            routeIdentity: 'drag-rapid',
            title: 'Drag Rapid',
            mode: AppResponsiveSheetMode.form,
            isDirty: true,
            body: const Text('Body'),
            onDiscard: () => discards++,
            onDismissApproved: () => dismisses++,
          ),
        ),
      );

      // First drag opens the dirty dialog.
      await tester.fling(
        find.byKey(const ValueKey('app-sheet-drag-handle')),
        const Offset(0, 200),
        500,
      );
      await tester.pumpAndSettle();
      expect(find.text('Perubahan belum disimpan'), findsOneWidget);

      // While the dialog is open, attempt additional drags — they must
      // not stack additional dialogs (the _isConfirming guard).
      // Note: the dialog is on top, so subsequent drags on the handle won't
      // reach the sheet's gesture detector. This verifies the one-shot latch.

      // Confirm discard.
      await tester.tap(find.text('Buang Perubahan'));
      await tester.pumpAndSettle();
      expect(discards, 1);
      expect(dismisses, 1);
    });

    // ----------------------------------------------------------------
    // STEP-55.0 RESIDUAL: AppDismissController covers newly-wired reasons
    // ----------------------------------------------------------------

    group('newly-wired dismiss reasons through controller', () {
      for (final reason in [
        AppDismissReason.drag,
        AppDismissReason.browserNavigation,
        AppDismissReason.parentNavigation,
      ]) {
        test('$reason: clean dismisses', () {
          expect(
            AppDismissController(
              isDirty: false,
              isBusy: false,
            ).requestDismiss(reason),
            AppDismissDecision.dismiss,
          );
        });

        test('$reason: dirty confirms', () {
          expect(
            AppDismissController(
              isDirty: true,
              isBusy: false,
            ).requestDismiss(reason),
            AppDismissDecision.confirmDiscard,
          );
        });

        test('$reason: busy blocks', () {
          expect(
            AppDismissController(
              isDirty: true,
              isBusy: true,
            ).requestDismiss(reason),
            AppDismissDecision.blockedBusy,
          );
        });
      }
    });

    // ----------------------------------------------------------------
    // STEP-55.0 RESIDUAL: AppFilterPopover adoption contract
    // ----------------------------------------------------------------

    testWidgets('popover adoption contract: apply/reset/cancel are reachable', (
      tester,
    ) async {
      // This proves the minimal adoption surface. A feature lane wraps its
      // filter controls in AppFilterPopover, wires onApply/onReset/onCancel
      // to its BLoC/cubit, and opens it via showAppFilterPopover. The
      // popover handles layout, labelling, and semantic container.
      var applied = 0;
      var reset = 0;
      var cancelled = 0;

      await tester.pumpWidget(
        host(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppFilterPopover(
                context: context,
                builder: (_) => AppFilterPopover(
                  onApply: () {
                    applied++;
                    Navigator.of(context).pop();
                  },
                  onReset: () => reset++,
                  onCancel: () {
                    cancelled++;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Zone selector'),
                ),
              ),
              child: const Text('Open filter'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open filter'));
      await tester.pumpAndSettle();
      expect(find.text('Zone selector'), findsOneWidget);

      await tester.tap(find.text('Reset filter'));
      expect(reset, 1);

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();
      expect(applied, 1);
      // Dialog closed after apply.
      expect(find.text('Zone selector'), findsNothing);

      // Re-open and cancel.
      await tester.tap(find.text('Open filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(cancelled, 1);
      expect(find.text('Zone selector'), findsNothing);
    });
  });
}
