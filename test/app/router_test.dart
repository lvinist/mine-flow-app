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
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';

/// Minimal fake for AuthRepository
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserEntity?> getCurrentUser() async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> updateProfile({
    required String id,
    required String name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> createUser({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? siteId,
    String? phone,
    String? nationalId,
    String? birthdate,
    String? gender,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<UserEntity>> getSiteRoster({String? siteId}) async => const [];
  @override
  Stream<UserEntity?> get onAuthStateChanges => const Stream.empty();
}

/// Minimal fake that satisfies [SettingsRepository] without touching Hive.
class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;
  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}
  @override
  Future<Locale> getLocale() async => const Locale('id');
  @override
  Future<void> saveLocale(Locale locale) async {}
  @override
  Future<int> getPrivacyAckVersion() async => 1;
  @override
  Future<void> savePrivacyAckVersion(int version) async {}
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
GoRouter _buildTestRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
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
                builder: (_, _) => const SizedBox(
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
                builder: (_, _) => const SizedBox(child: Text('Tools')),
                routes: [
                  GoRoute(
                    path: 'data-bucket',
                    builder: (_, _) => const SizedBox(
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
                builder: (_, _) => const SizedBox(child: Text('Operations')),
                routes: [
                  GoRoute(
                    path: 'cut-fill',
                    builder: (_, _) => const SizedBox(
                      key: _kOperationsKey,
                      child: Text('Cut / Fill'),
                    ),
                    routes: [
                      GoRoute(
                        path: 'form',
                        name: 'cut-fill-create',
                        builder: (_, state) => SizedBox(
                          key: const Key('cut-fill-create-view'),
                          child: Text(
                            'CREATE: zone=${state.uri.queryParameters['zoneId'] ?? ''}',
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':id/form',
                        name: 'cut-fill-edit',
                        builder: (_, state) => SizedBox(
                          key: const Key('cut-fill-edit-view'),
                          child: Text('EDIT: id=${state.pathParameters['id']}'),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'land-clearing',
                    builder: (_, _) =>
                        const SizedBox(child: Text('Land Clearing')),
                  ),
                  GoRoute(
                    path: 'benchmark-db',
                    builder: (_, _) =>
                        const SizedBox(child: Text('Benchmark DB')),
                    routes: [
                      GoRoute(
                        path: 'form',
                        name: 'benchmark-form',
                        builder: (_, _) => const SizedBox(
                          key: Key('benchmark-create-view'),
                          child: Text('Benchmark CREATE'),
                        ),
                      ),
                      GoRoute(
                        path: ':id',
                        name: 'benchmark-detail',
                        builder: (_, state) => SizedBox(
                          key: const Key('benchmark-detail-view'),
                          child: Text(
                            'Benchmark DETAIL id=${state.pathParameters['id']}',
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':id/form',
                        name: 'benchmark-edit',
                        builder: (_, state) => SizedBox(
                          key: const Key('benchmark-edit-view'),
                          child: Text(
                            'Benchmark EDIT id=${state.pathParameters['id']}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teams',
                builder: (_, _) => const SizedBox(child: Text('Teams')),
                routes: [
                  GoRoute(
                    path: 'attendance',
                    builder: (_, _) => const SizedBox(
                      key: _kTeamsKey,
                      child: Text('Attendance'),
                    ),
                  ),
                  GoRoute(
                    path: 'daily-log',
                    builder: (_, _) => const SizedBox(child: Text('Daily Log')),
                  ),
                  GoRoute(
                    path: 'inventory',
                    builder: (_, _) => const SizedBox(child: Text('Inventory')),
                  ),
                  GoRoute(
                    path: 'equipment-check',
                    builder: (_, _) =>
                        const SizedBox(child: Text('Equipment Check')),
                    routes: [
                      GoRoute(
                        path: 'form',
                        name: 'equipment-check-form',
                        builder: (_, state) => SizedBox(
                          key: const Key('equipment-check-create-view'),
                          child: Text(
                            'EQUIPMENT-CREATE: siteId=${state.uri.queryParameters['siteId'] ?? ''}',
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':id',
                        name: 'equipment-check-detail',
                        builder: (_, state) => SizedBox(
                          key: const Key('equipment-check-detail-view'),
                          child: Text(
                            'EQUIPMENT-DETAIL: id=${state.pathParameters['id']}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) =>
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
      BlocProvider<AuthCubit>(
        create: (_) => AuthCubit(repository: _FakeAuthRepository()),
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
      // Taller surface so the Settings item (last in the sidebar) is visible.
      await tester.binding.setSurfaceSize(const Size(1024, 1200));
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

  group('Cut & Fill route paths', () {
    test('AppRoutes defines canonical Cut & Fill paths', () {
      expect(AppRoutes.cutFill, '/operations/cut-fill');
      expect(AppRoutes.cutFillForm, '/operations/cut-fill/form');
      expect(AppRoutes.cutFillEdit('cf-42'), '/operations/cut-fill/cf-42/form');
    });

    testWidgets(
      'cold create route navigates to cut-fill create and parses query parameters',
      (tester) async {
        final router = _buildTestRouter(
          initialLocation:
              '/operations/cut-fill/form?from=2026-03-01&to=2026-03-15&zoneId=zone-1',
        );

        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(_appWrapper(router));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('cut-fill-create-view')), findsOneWidget);
        expect(find.text('CREATE: zone=zone-1'), findsOneWidget);
      },
    );

    testWidgets(
      'cold edit route navigates to cut-fill edit and parses recordId parameter without extra',
      (tester) async {
        final router = _buildTestRouter(
          initialLocation: '/operations/cut-fill/cf-cold-99/form',
        );

        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(_appWrapper(router));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('cut-fill-edit-view')), findsOneWidget);
        expect(find.text('EDIT: id=cf-cold-99'), findsOneWidget);
      },
    );
  });

  group('Equipment Check route paths', () {
    test('AppRoutes defines canonical Equipment Check paths', () {
      expect(AppRoutes.equipmentCheck, '/teams/equipment-check');
      expect(AppRoutes.equipmentCheckForm, '/teams/equipment-check/form');
      expect(
        AppRoutes.equipmentCheckDetail('eq-101'),
        '/teams/equipment-check/eq-101',
      );
    });

    testWidgets(
      'cold create route navigates to equipment-check create and parses query parameters',
      (tester) async {
        final router = _buildTestRouter(
          initialLocation: '/teams/equipment-check/form?siteId=site-pit-01',
        );

        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(_appWrapper(router));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('equipment-check-create-view')),
          findsOneWidget,
        );
        expect(
          find.text('EQUIPMENT-CREATE: siteId=site-pit-01'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'cold detail route navigates to equipment-check detail and parses id parameter without extra',
      (tester) async {
        final router = _buildTestRouter(
          initialLocation: '/teams/equipment-check/eq-cold-88',
        );

        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(_appWrapper(router));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('equipment-check-detail-view')),
          findsOneWidget,
        );
        expect(find.text('EQUIPMENT-DETAIL: id=eq-cold-88'), findsOneWidget);
      },
    );
  });

  group('Benchmark route paths', () {
    test('AppRoutes defines canonical Benchmark paths', () {
      expect(AppRoutes.benchmarkDb, '/operations/benchmark-db');
      expect(AppRoutes.benchmarkForm, '/operations/benchmark-db/form');
      expect(
        AppRoutes.benchmarkDetail('bm-42'),
        '/operations/benchmark-db/bm-42',
      );
      expect(
        AppRoutes.benchmarkEdit('bm-42'),
        '/operations/benchmark-db/bm-42/form',
      );
    });

    testWidgets(
      'cold create route navigates to benchmark form and parses no params',
      (tester) async {
        final router = _buildTestRouter(
          initialLocation: '/operations/benchmark-db/form',
        );

        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(_appWrapper(router));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('benchmark-create-view')), findsOneWidget);
        expect(find.text('Benchmark CREATE'), findsOneWidget);
      },
    );

    testWidgets(
      'cold detail route navigates to benchmark detail and resolves id from path without extra',
      (tester) async {
        final router = _buildTestRouter(
          initialLocation: '/operations/benchmark-db/bm-cold-77',
        );

        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(_appWrapper(router));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('benchmark-detail-view')), findsOneWidget);
        expect(find.text('Benchmark DETAIL id=bm-cold-77'), findsOneWidget);
      },
    );

    testWidgets(
      'cold edit route navigates to benchmark edit and resolves id from path without extra',
      (tester) async {
        final router = _buildTestRouter(
          initialLocation: '/operations/benchmark-db/bm-cold-77/form',
        );

        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(_appWrapper(router));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('benchmark-edit-view')), findsOneWidget);
        expect(find.text('Benchmark EDIT id=bm-cold-77'), findsOneWidget);
      },
    );
  });
}
