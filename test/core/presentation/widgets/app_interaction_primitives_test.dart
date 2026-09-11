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
  });
}
