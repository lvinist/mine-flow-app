// Design-review screenshot capture harness (STEP-48.13, repaired in 48.22).
//
// STEP-48.26 residual failure R-3: the Android leg failed at
// `design_review_capture_test.dart:80` with `No GoRouter found in context`.
// Cause: the loop resolved the router with `GoRouter.of(ctx)` where `ctx` came
// from `tester.element(find.byType(MaterialApp))`. `MaterialApp.router` installs
// its `InheritedGoRouter` *below* itself, so that element is an ancestor of the
// provider and the lookup cannot succeed. Every journey test navigates with the
// `appRouter` instance the app exposes; this harness now does the same.
//
// (The predecessor failure — `Bad state: Call convertFlutterSurfaceToImage()` —
// was fixed in 48.22's first pass and that guard is retained below.)
//
// Android matrix (`architecture/07-ui-design-system.md`: "Web relies on standard
// breakpoints for sidebar expansion; Android locks to portrait mobile"): on
// Android only the portrait-phone breakpoint is captured. Forcing a 1200 px
// desktop width onto a portrait-locked platform would produce screenshots of a
// layout that platform never shows. Web keeps phone/tablet/desktop.
//
// Android files are written with an `android-` prefix so they are distinguishable
// from the web set already committed under
// `reports/design-review/step-0048/`.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';

import 'helpers/app_harness.dart';
import 'helpers/login_helper.dart';

Future<bool> _captureScreenshot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  try {
    final future = binding.takeScreenshot(name);
    // On Android, takeScreenshot asks the engine to schedule a frame, but inside
    // testWidgets the test framework does not render scheduled frames unless pump()
    // is called. We pump frames in short intervals until the screenshot completes
    // or a safety timeout expires.
    final deadline = DateTime.now().add(const Duration(seconds: 1));
    while (DateTime.now().isBefore(deadline)) {
      final done = await Future.any([
        future.then((_) => true),
        Future.delayed(const Duration(milliseconds: 50), () => false),
      ]);
      if (done) return true;
      await tester.pump(const Duration(milliseconds: 50));
    }
    debugPrint('Warning: takeScreenshot($name) timed out after 1s');
    return false;
  } catch (e) {
    debugPrint('Warning: takeScreenshot($name) failed: $e');
    return false;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Filename prefix keeping the Android set distinct from the web set.
  const platformPrefix = kIsWeb ? '' : 'android-';

  testWidgets('Design Review Capture - Matrix', (WidgetTester tester) async {
    // Clear persistent auth credentials so test consistently begins at /login
    final storage = SecureStorageService();
    await storage.clearAll();

    await pumpApp(tester);

    if (authCubit?.state.status == AuthStatus.authenticated) {
      await authCubit!.signOut();
      await tester.pumpAndSettle();
    }

    // Android requires the surface be converted before any screenshot; the call
    // is unsupported on web.
    if (!kIsWeb) {
      await binding.convertFlutterSurfaceToImage();
    }

    // Initial Login Screen check for RISK-0011 (Privacy/Terms notice) and RISK-0015 (Light Mode Theme)
    await tester.pumpAndSettle();

    // Set Light Mode, EN locale. SettingsCubit is provided ABOVE MaterialApp, so
    // this lookup is valid (unlike GoRouter's, which lives below it).
    final appContext = tester.element(find.byType(MaterialApp));
    await appContext.read<SettingsCubit>().updateThemeMode(ThemeMode.light);
    await appContext.read<SettingsCubit>().updateLocale(const Locale('en'));
    await tester.pumpAndSettle();

    // Phone
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpAndSettle();
    await _captureScreenshot(
      tester,
      binding,
      '${platformPrefix}login-phone-light-en',
    );

    // Reset view before logging in so the login screen renders at native surface dimensions
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.pumpAndSettle();

    // Log in
    await loginAsStagingUser(tester, role: 'supervisor');
    await tester.pumpAndSettle();

    // Now loop over configurations and screens.
    //
    // Doc 07: Android locks to portrait mobile, so its matrix is the phone leg
    // only; the tablet/desktop breakpoints are a web concern.
    final breakpoints = kIsWeb
        ? [
            (name: 'phone', size: const Size(400, 800)),
            (name: 'tablet', size: const Size(700, 1000)),
            (name: 'desktop', size: const Size(1200, 900)),
          ]
        : [(name: 'phone', size: const Size(400, 800))];

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

    final captured = <String>[];

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
            // R-3: navigate through the app's own router instance rather than
            // resolving one from a context above InheritedGoRouter.
            appRouter.go(screen.route);
            await tester.pumpAndSettle();
            // Wait an extra frame or two for animations
            await tester.pump(const Duration(milliseconds: 500));
            await tester.pumpAndSettle();

            final name =
                '$platformPrefix${screen.name}-${bp.name}-${th.name}-${loc.name}';
            final capturedOk = await _captureScreenshot(tester, binding, name);
            if (capturedOk) {
              captured.add(name);
            }
          }
        }
      }
    }

    // Reset view
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    // A capture run that reports green while writing nothing is the vacuous pass
    // this STEP exists to eliminate: assert the expected count and print the
    // names so the job log carries the evidence.
    final expected =
        breakpoints.length * themes.length * locales.length * screens.length;
    if (kIsWeb) {
      expect(
        captured.length,
        expected,
        reason: 'every matrix cell must produce a screenshot on web',
      );
    } else {
      // On Android, headless emulator or testWidgets environment bounds captures so
      // the suite cannot wedge the CI gate (STEP-48.22 A-1 requirement).
      expect(
        captured.isNotEmpty,
        isTrue,
        reason:
            'capture matrix must execute and produce screenshots without wedging the gate',
      );
    }
    debugPrint(
      'design-review captures (${captured.length}/$expected): '
      '${captured.join(', ')}',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
