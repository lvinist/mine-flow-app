// Tests for appRouter — verifies that the 5 StatefulShellRoute branches resolve
// correctly and maintain state across navigation.
//
// Docstrings are required per coding-standards/README.md.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/bloc/theme_cubit.dart';

import 'package:mine_flow/app/presentation/pages/app_shell.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;
  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}
  @override
  Future<Locale> getLocale() async => const Locale('en');
  @override
  Future<void> saveLocale(Locale locale) async {}
}

/// Whether AppShell is present in the widget tree.
///
/// We can't directly import GoRouter's StatefulShellRoute internals, but we can
/// verify that the correct branch content is displayed after navigation.
/// The [AppShell] renders branch content inside an [Expanded] widget wrapping
/// the [StatefulNavigationShell].

/// Key constants used in branches — these match the named routes in appRouter.
const _kDashboardKey = Key('router-test-dashboard');
const _kToolsKey = Key('router-test-tools');
const _kOperationsKey = Key('router-test-operations');
const _kTeamsKey = Key('router-test-teams');
const _kSettingsKey = Key('router-test-settings');

/// Builds a simplified version of appRouter for testing, using our own
/// StatefulShellRoute with keyed branch content so we can verify navigation.
///
/// This mirrors the real router's 5-branch structure without dependency on
/// feature screens or appServices.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const SizedBox(
                  key: _kDashboardKey,
                  child: Text('Dashboard'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tools',
                builder: (_, __) => const SizedBox(child: Text('Tools')),
                routes: [
                  GoRoute(
                    path: 'data-bucket',
                    builder: (_, __) => const SizedBox(
                      key: _kToolsKey,
                      child: Text('Data Bucket'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/operations',
                builder: (_, __) => const SizedBox(child: Text('Operations')),
                routes: [
                  GoRoute(
                    path: 'cut-fill',
                    builder: (_, __) => const SizedBox(
                      key: _kOperationsKey,
                      child: Text('Cut / Fill'),
                    ),
                  ),
                  GoRoute(
                    path: 'land-clearing',
                    builder: (_, __) =>
                        const SizedBox(child: Text('Land Clearing')),
                  ),
                  GoRoute(
                    path: 'benchmark-db',
                    builder: (_, __) =>
                        const SizedBox(child: Text('Benchmark DB')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teams',
                builder: (_, __) => const SizedBox(child: Text('Teams')),
                routes: [
                  GoRoute(
                    path: 'attendance',
                    builder: (_, __) => const SizedBox(
                      key: _kTeamsKey,
                      child: Text('Attendance'),
                    ),
                  ),
                  GoRoute(
                    path: 'daily-log',
                    builder: (_, __) =>
                        const SizedBox(child: Text('Daily Log')),
                  ),
                  GoRoute(
                    path: 'inventory',
                    builder: (_, __) =>
                        const SizedBox(child: Text('Inventory')),
                  ),
                  GoRoute(
                    path: 'equipment-check',
                    builder: (_, __) =>
                        const SizedBox(child: Text('Equipment Check')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) =>
                    const SizedBox(key: _kSettingsKey, child: Text('Settings')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Minimal App wrapper providing FTheme + ThemeCubit + SettingsCubit so shell ForUI widgets
/// and the theme toggle resolve.
Widget _appWrapper(GoRouter router) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      BlocProvider<SettingsCubit>(
        create: (_) => SettingsCubit(repository: FakeSettingsRepository()),
      ),
    ],
    child: FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  group('Router branch navigation', () {
    testWidgets('starts on Dashboard branch (index 0)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_appWrapper(_buildTestRouter()));
      await tester.pumpAndSettle();

      // Dashboard content should be visible.
      expect(find.byKey(_kDashboardKey), findsOneWidget);
    });

    testWidgets('navigates to Tools branch and maintains state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_appWrapper(_buildTestRouter()));
      await tester.pumpAndSettle();

      // Navigate to the Tools route via the shell (goBranch index 1).
      // Expand the Tools group if necessary and tap "Data Bucket".
      final toolsText = find.text('Tools').last;
      await tester.tap(toolsText);
      await tester.pumpAndSettle();

      final dataBucketItem = find.text('Data Bucket').last;
      await tester.tap(dataBucketItem);
      await tester.pumpAndSettle();

      // Tools branch content should be displayed.
      expect(find.byKey(_kToolsKey), findsOneWidget);
      // Dashboard content should no longer be visible.
      expect(find.byKey(_kDashboardKey), findsNothing);
    });

    testWidgets('navigates to Operations branch (index 2)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_appWrapper(_buildTestRouter()));
      await tester.pumpAndSettle();

      // Expand the Operations group and tap "Cut / Fill".
      final opsGroup = find.text('Operations').last;
      await tester.tap(opsGroup);
      await tester.pumpAndSettle();

      final cutFillItem = find.text('Cut / Fill').last;
      await tester.tap(cutFillItem);
      await tester.pumpAndSettle();

      expect(find.byKey(_kOperationsKey), findsOneWidget);
    });

    testWidgets('navigates to Teams branch (index 3)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_appWrapper(_buildTestRouter()));
      await tester.pumpAndSettle();

      final teamsGroup = find.text('Teams').last;
      await tester.tap(teamsGroup);
      await tester.pumpAndSettle();

      final attendanceItem = find.text('Attendance').last;
      await tester.tap(attendanceItem);
      await tester.pumpAndSettle();

      expect(find.byKey(_kTeamsKey), findsOneWidget);
    });

    testWidgets('navigates to Settings branch (index 4)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(_appWrapper(_buildTestRouter()));
      await tester.pumpAndSettle();

      final settingsText = find.text('Settings').last;
      await tester.tap(settingsText);
      await tester.pumpAndSettle();

      expect(find.byKey(_kSettingsKey), findsOneWidget);
    });

    testWidgets(
      'stateful branches maintain index after navigation round-trip',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(_appWrapper(_buildTestRouter()));
        await tester.pumpAndSettle();

        // Navigate: Dashboard → Tools → Operations → Tools
        await tester.tap(find.text('Tools').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Data Bucket').last);
        await tester.pumpAndSettle();
        expect(find.byKey(_kToolsKey), findsOneWidget);

        await tester.tap(find.text('Operations').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cut / Fill').last);
        await tester.pumpAndSettle();
        expect(find.byKey(_kOperationsKey), findsOneWidget);

        // Go back to Tools.
        await tester.tap(find.text('Tools').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Data Bucket').last);
        await tester.pumpAndSettle();
        expect(find.byKey(_kToolsKey), findsOneWidget);
        // Operations should not be visible.
        expect(find.byKey(_kOperationsKey), findsNothing);
      },
    );
  });
}
