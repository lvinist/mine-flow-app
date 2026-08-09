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
    child: BlocProvider<SettingsCubit>(
      create: (_) => StubSettingsCubit(),
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
}
