import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';

import 'helpers/app_harness.dart';
import 'helpers/login_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Design Review Capture - Matrix', (WidgetTester tester) async {
    await pumpApp(tester);

    if (!kIsWeb) {
      await binding.convertFlutterSurfaceToImage();
    }

    // Initial Login Screen check for RISK-0011 (Privacy/Terms notice) and RISK-0015 (Light Mode Theme)
    await tester.pumpAndSettle();

    // Set Light Mode, EN locale
    final appContext = tester.element(find.byType(MaterialApp));
    await appContext.read<SettingsCubit>().updateThemeMode(ThemeMode.light);
    await appContext.read<SettingsCubit>().updateLocale(const Locale('en'));
    await tester.pumpAndSettle();

    // Phone
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpAndSettle();
    await binding.takeScreenshot('login-phone-light-en');

    // Log in
    await loginAsStagingUser(tester, role: 'supervisor');
    await tester.pumpAndSettle();

    // Now loop over configurations and screens
    final breakpoints = [
      (name: 'phone', size: const Size(400, 800)),
      (name: 'tablet', size: const Size(700, 1000)),
      (name: 'desktop', size: const Size(1200, 900)),
    ];

    final themes = [
      (name: 'light', mode: ThemeMode.light),
      (name: 'dark', mode: ThemeMode.dark),
    ];

    final locales = [
      (name: 'id', locale: const Locale('id')),
      (name: 'en', locale: const Locale('en')),
    ];

    final screens = [
      (name: 'dashboard', route: '/'),
      (name: 'daily-log', route: '/teams/daily-log'),
      (name: 'daily-log-form', route: '/teams/daily-log/form'),
      (name: 'operations', route: '/operations'),
      (name: 'teams', route: '/teams'),
      (name: 'tools', route: '/tools'),
    ];

    for (final bp in breakpoints) {
      tester.view.physicalSize = bp.size;
      tester.view.devicePixelRatio = 1.0;

      for (final th in themes) {
        for (final loc in locales) {
          // set theme and locale
          final ctx = tester.element(find.byType(MaterialApp));
          await ctx.read<SettingsCubit>().updateThemeMode(th.mode);
          await ctx.read<SettingsCubit>().updateLocale(loc.locale);
          await tester.pumpAndSettle();

          for (final screen in screens) {
            GoRouter.of(ctx).go(screen.route);
            await tester.pumpAndSettle();
            // Wait an extra frame or two for animations
            await tester.pump(const Duration(milliseconds: 500));
            await tester.pumpAndSettle();

            await binding.takeScreenshot(
              '${screen.name}-${bp.name}-${th.name}-${loc.name}',
            );
          }
        }
      }
    }

    // Reset view
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
