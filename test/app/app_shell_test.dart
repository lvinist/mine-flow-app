// Tests for AppShell responsive layout switching.
//
// Verifies that AppShell renders the wide (sidebar) layout when the viewport
// is >= 800px and the narrow (bottom nav) layout when < 800px.
//
// STEP-31.5: Updated tests to account for GlobalAppHeader in both layouts.
//
// Docstrings are required per coding-standards/README.md.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/bloc/theme_cubit.dart';
import 'package:mine_flow/app/presentation/pages/app_shell.dart';
import 'package:mine_flow/app/presentation/widgets/global_app_header.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';

/// Minimal fake that satisfies [SettingsRepository] without touching Hive.
class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;
  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}
  @override
  Future<Locale> getLocale() async => const Locale('id');
  @override
  Future<void> saveLocale(Locale locale) async {}
}

/// Width threshold that matches app_shell.dart's internal constant.

/// Builds a test GoRouter that uses [AppShell] as the shell builder.
///
/// Each branch renders a simple [SizedBox] so we can verify shell layout
/// without feature-screen dependencies.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const SizedBox(key: ValueKey('dashboard')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tools',
                builder: (_, _) => const SizedBox(),
                routes: [
                  GoRoute(
                    path: 'data-bucket',
                    builder: (_, _) => const SizedBox(key: ValueKey('tools')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/operations',
                builder: (_, _) => const SizedBox(),
                routes: [
                  GoRoute(
                    path: 'cut-fill',
                    builder: (_, _) =>
                        const SizedBox(key: ValueKey('operations')),
                  ),
                  GoRoute(
                    path: 'land-clearing',
                    builder: (_, _) =>
                        const SizedBox(key: ValueKey('land-clearing')),
                  ),
                  GoRoute(
                    path: 'benchmark-db',
                    builder: (_, _) =>
                        const SizedBox(key: ValueKey('benchmark-db')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teams',
                builder: (_, _) => const SizedBox(),
                routes: [
                  GoRoute(
                    path: 'attendance',
                    builder: (_, _) => const SizedBox(key: ValueKey('teams')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SizedBox(key: ValueKey('settings')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Wraps the GoRouter in the required providers (ThemeCubit, SettingsCubit + FTheme).
Widget _wrapWithProviders(GoRouter router) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      BlocProvider<SettingsCubit>(
        create: (_) => SettingsCubit(repository: _FakeSettingsRepository()),
      ),
    ],
    child: FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  group('AppShell responsive layout', () {
    testWidgets('renders wide layout (FSidebar) at >= 800px width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
      await tester.pumpAndSettle();

      // Verify FSidebar is present in the wide layout.
      expect(find.byType(FSidebar), findsOneWidget);
      // Verify the bottom navigation bar is NOT present.
      expect(find.byType(FBottomNavigationBar), findsNothing);
    });

    testWidgets(
      'renders narrow layout (FBottomNavigationBar) at < 800px width',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 667));

        await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
        await tester.pumpAndSettle();

        // Verify FBottomNavigationBar is present in the narrow layout.
        expect(find.byType(FBottomNavigationBar), findsOneWidget);
        // Verify the sidebar is NOT present.
        expect(find.byType(FSidebar), findsNothing);
      },
    );

    testWidgets('switches layout when viewport crosses breakpoint', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
      await tester.pumpAndSettle();

      // Start wide — sidebar visible.
      expect(find.byType(FSidebar), findsOneWidget);
      expect(find.byType(FBottomNavigationBar), findsNothing);

      // Shrink to mobile width.
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpAndSettle();

      // Now bottom nav visible, sidebar gone.
      expect(find.byType(FBottomNavigationBar), findsOneWidget);
      expect(find.byType(FSidebar), findsNothing);
    });

    testWidgets('all sidebar items are rendered in wide layout', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
      await tester.pumpAndSettle();

      // Look for FSidebarItem widgets in the tree.
      // The exact count may vary due to ForUI internal items; verify at least 5.
      expect(find.byType(FSidebarItem), findsAtLeast(5));
    });

    testWidgets('all 5 bottom nav items are rendered in narrow layout', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
      await tester.pumpAndSettle();

      // Look for FBottomNavigationBarItem widgets in the tree.
      expect(find.byType(FBottomNavigationBarItem), findsNWidgets(5));
    });

    testWidgets('tapping a sidebar item navigates to the correct branch', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      final router = _buildTestRouter();
      await tester.pumpWidget(_wrapWithProviders(router));
      await tester.pumpAndSettle();

      // Initially on Dashboard (index 0).
      expect(find.byKey(const ValueKey('dashboard')), findsOneWidget);

      // Tap the "Tools" sidebar group to expand it, then tap "Data Bucket".
      final toolsItem = find.text('Tools').last;
      await tester.tap(toolsItem);
      await tester.pumpAndSettle();

      final dataBucketItem = find.text('Data Bucket').last;
      await tester.tap(dataBucketItem);
      await tester.pumpAndSettle();

      // After tapping, we should be on /data-bucket route.
      // The branch content should be visible.
      expect(find.byKey(const ValueKey('tools')), findsOneWidget);
    });

    // --- STEP-31.5: Global App Header tests ---

    testWidgets('GlobalAppHeader is rendered in wide layout (desktop)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
      await tester.pumpAndSettle();

      // Verify the GlobalAppHeader widget is present.
      expect(find.byType(GlobalAppHeader), findsOneWidget);
    });

    testWidgets('GlobalAppHeader is rendered in narrow layout (mobile)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
      await tester.pumpAndSettle();

      // Verify the GlobalAppHeader widget is present.
      expect(find.byType(GlobalAppHeader), findsOneWidget);
    });

    testWidgets('GlobalAppHeader shows breadcrumb text on desktop', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
      await tester.pumpAndSettle();

      // The breadcrumb should show "Dashboard" for the root route.
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('GlobalAppHeader shows search field hint on desktop', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
      await tester.pumpAndSettle();

      // The search hint should be visible.
      expect(find.text('Cari fitur atau data…'), findsOneWidget);
    });

    testWidgets('GlobalAppHeader shows search field hint on mobile', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(_wrapWithProviders(_buildTestRouter()));
      await tester.pumpAndSettle();

      // The search hint should be visible.
      expect(find.text('Cari fitur atau data…'), findsOneWidget);
    });
  });
}
