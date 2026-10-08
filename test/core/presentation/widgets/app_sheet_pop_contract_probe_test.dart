import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// Counts actual route removals, independently of the sheet callbacks.
class _PopObserver extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    super.didPop(route, previousRoute);
  }
}

/// Reproduces a successful programmatic pop before the dirty child rebuilds.
void main() {
  for (final dirty in [true, false]) {
    for (final width in [400.0, 1100.0]) {
      testWidgets(
        'completed pop does not re-enter dismissal dirty=$dirty width=$width',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final navigator = GlobalKey<NavigatorState>();
          final observer = _PopObserver();
          var approvals = 0;
          var taps = 0;
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigator,
              navigatorObservers: [observer],
              locale: const Locale('id'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: Text('Root')),
            ),
          );
          navigator.currentState!.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const Key('history-action'),
                    onPressed: () => taps++,
                    child: const Text('History action'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          navigator.currentState!.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => AppResponsiveSheet(
                routeIdentity: 'pop-probe',
                title: 'Form',
                mode: AppResponsiveSheetMode.form,
                isDirty: dirty,
                body: const Text('Form body'),
                onDismissApproved: () {
                  approvals++;
                  navigator.currentState!.pop();
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          // Navigator.pop is the real successful-save path. PopScope's
          // didPop=true notification must not trigger another dismissal.
          navigator.currentState!.pop();
          await tester.pump();
          await tester.pumpAndSettle();
          expect(find.byType(AppDirtyDismissDialog), findsNothing);
          expect(approvals, 0);
          expect(observer.pops, 1);
          expect(find.byKey(const Key('history-action')), findsOneWidget);
          await tester.tap(find.byKey(const Key('history-action')));
          await tester.pump();
          expect(taps, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
