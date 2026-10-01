import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/navigation/route_observer.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// STEP-55.11 RESIDUAL-2 (B2): a popup route pushed over a dirty
/// [AppResponsiveSheet] must NOT trigger the shared dirty-dismiss guard.
///
/// Root cause: `routeObserver` was typed `RouteObserver<ModalRoute<void>>`.
/// `RouteObserver.didPush` only forwards `didPushNext` when BOTH the incoming
/// and previous routes are of its type parameter `R`. A Material
/// `DropdownButtonFormField` opens a `_DropdownRoute`, which is a
/// `PopupRoute` and therefore also a `ModalRoute` — so it matched `R`, fired
/// `didPushNext` on the still-mounted dirty sheet, and raised the
/// non-dismissible `AppDirtyDismissDialog` ON TOP of the dropdown. That
/// swallowed the category tap in the inventory journey on both platforms and
/// is wrong UX for a real user.
///
/// Typing the observer to `RouteObserver<PageRoute<void>>` makes popup routes
/// (dropdown menus, dialogs, the dirty dialog itself) invisible to the
/// page-navigation guard, while page-level `didPushNext`/`didPopNext` (the
/// 55.5/55.6 list-refresh contract) keep working because page routes ARE
/// `PageRoute`s.
void main() {
  Widget host({required Widget child}) => MaterialApp(
    locale: const Locale('id'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('id'), Locale('en')],
    // The sheet subscribes to this observer in didChangeDependencies; wiring
    // it here mirrors the app's real navigatorObservers.
    navigatorObservers: [routeObserver],
    home: MediaQuery(
      data: const MediaQueryData(size: Size(1024, 800)),
      child: Scaffold(body: child),
    ),
  );

  testWidgets(
    'opening a Material dropdown over a dirty sheet does NOT open the discard dialog',
    (tester) async {
      await tester.pumpWidget(
        host(
          child: AppResponsiveSheet(
            routeIdentity: 'popup-regression',
            title: 'Fixture',
            mode: AppResponsiveSheetMode.form,
            isDirty: true,
            onDismissApproved: () {},
            body: const _CategoryDropdown(),
          ),
        ),
      );

      // Open the dropdown menu — this pushes a PopupRoute onto the navigator.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // The dirty-dismiss dialog must NOT appear. Before the fix, the popup
      // push fired didPushNext on the dirty sheet and opened this dialog.
      expect(
        find.text('Perubahan belum disimpan'),
        findsNothing,
        reason:
            'a popup route over a dirty sheet must not trigger the dirty guard',
      );

      // The dropdown itself must be open and its options tappable.
      expect(find.text('Semen').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Semen').hitTestable());
      await tester.pumpAndSettle();
    },
  );
}

class _CategoryDropdown extends StatefulWidget {
  const _CategoryDropdown();

  @override
  State<_CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<_CategoryDropdown> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const Key('category-dropdown'),
      initialValue: _value,
      items: const [
        DropdownMenuItem(value: 'semen', child: Text('Semen')),
        DropdownMenuItem(value: 'solar', child: Text('Solar')),
      ],
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
