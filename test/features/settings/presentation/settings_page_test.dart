/// Widget tests for [SettingsPage].
///
/// Verifies that the page renders without exceptions and that key sections
/// (Profile, Language, Theme, Logout, Support) are present on screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:mine_flow/features/settings/presentation/pages/settings_page.dart';

/// A stub [SettingsRepository] that returns hard-coded defaults and ignores
/// all saves — no Hive IO, just in-memory no-ops.
class StubSettingsRepository extends SettingsRepository {
  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}

  @override
  Future<Locale> getLocale() async => const Locale('en');

  @override
  Future<void> saveLocale(Locale locale) async {}
}

/// A stub [SettingsCubit] backed by [StubSettingsRepository].
///
/// Overrides update methods to no-ops so tapping buttons does not trigger
/// real navigation or external URL launches in the test.
class StubSettingsCubit extends SettingsCubit {
  StubSettingsCubit() : super(repository: StubSettingsRepository());

  @override
  Future<void> updateThemeMode(ThemeMode mode) async {}

  @override
  Future<void> updateLocale(Locale locale) async {}
}

/// In-memory [AuthRepository] returning a supervisor user (CF-005).
class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserEntity?> getCurrentUser() async => const UserEntity(
    id: 'u1',
    email: 'super@mineflow.id',
    name: 'Alvin Pratama',
    role: 'supervisor',
    siteId: 's1',
  );

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
  Stream<UserEntity?> get onAuthStateChanges => const Stream.empty();
}

/// Wraps [SettingsPage] with the providers and theme needed in a test.
Widget _buildTestApp() {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const SizedBox(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsPage(),
      ),
    ],
  );

  return FTheme(
    data: FTheme.neutral.light.touch,
    child: MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) =>
              AuthCubit(repository: FakeAuthRepository())..initialize(),
        ),
        BlocProvider<SettingsCubit>(create: (_) => StubSettingsCubit()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('SettingsPage renders all key sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // --- Header ---
    expect(find.text('Pengaturan'), findsOneWidget);

    // --- Profile section ---
    expect(find.byType(FCard), findsWidgets);

    // --- Preferences: language buttons ---
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Indonesia'), findsOneWidget);
    expect(find.text('Terang'), findsOneWidget);
    expect(find.text('Gelap'), findsOneWidget);
    expect(find.text('Sistem'), findsOneWidget);

    // --- Support ---
    expect(find.text('Dukungan'), findsOneWidget);
    expect(find.text('alvin.geomatics@gmail.com'), findsOneWidget);
    expect(find.text('+62 851-5604-2854'), findsOneWidget);

    // --- Logout ---
    expect(find.text('Keluar / Logout'), findsOneWidget);

    // --- App version ---
    expect(find.text('mine-flow v0.1.0'), findsOneWidget);
  });

  testWidgets('profile card shows the authenticated user (CF-005)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // The signed-in supervisor's name and role, not fabricated placeholders.
    expect(find.text('Alvin Pratama'), findsOneWidget);
    expect(find.text('Supervisor'), findsOneWidget);
    expect(find.text('Foreman'), findsNothing);
    expect(find.text('Pengguna'), findsNothing);
  });

  testWidgets('language selector carries a partial-translation note (CF-059)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Terjemahan bahasa Inggris masih sebagian.'),
      findsOneWidget,
    );
  });
}
