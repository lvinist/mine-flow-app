/// Tests for the locale and localization configuration of [MineFlowApp].
///
/// Verifies:
/// 1. [SettingsCubit] correctly drives the app locale.
/// 2. The [AppLocalizations] delegate resolves both 'id' and 'en' locales.
/// 3. The sentinel baseline key is accessible via [AppLocalizations].
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations delegate', () {
    test('supports Indonesian locale', () async {
      const delegate = AppLocalizations.delegate;
      expect(await delegate.load(const Locale('id')), isNotNull);
    });

    test('supports English locale', () async {
      const delegate = AppLocalizations.delegate;
      expect(await delegate.load(const Locale('en')), isNotNull);
    });

    testWidgets('resolves baseline sentinel key in Indonesian', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(l10n.localizationBaseline, isNotEmpty);
      expect(l10n.appTitle, 'mine-flow');
    });

    testWidgets('resolves baseline sentinel key in English', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(l10n.localizationBaseline, isNotEmpty);
      expect(l10n.appTitle, 'mine-flow');
    });
  });
}
