// Root application widget for mine-flow.
//
// Configures MaterialApp.router with ForUI FTheme (FTheme.neutral),
// the appRouter for navigation, and locale/theme driven by SettingsCubit
// (which persists user preferences via Hive).
//
// Theme and locale are both managed by SettingsCubit, superseding the
// earlier ThemeCubit that only handled theme mode.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:mine_flow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';

/// The root widget of the mine-flow application.
class MineFlowApp extends StatelessWidget {
  const MineFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      // Reuse the process-wide instance so the router redirect observes the
      // same state the login/settings pages dispatch against. Falls back to a
      // no-op repository only when the app is pumped without `main()` wiring
      // (e.g. the smoke test).
      create: (_) =>
          authCubit ?? AuthCubit(repository: const _NoopAuthRepository()),
      child: BlocProvider<SettingsCubit>(
        create: (_) => SettingsCubit(repository: _createRepository()),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            final brightness = PlatformDispatcher.instance.platformBrightness;
            final isDark =
                settingsState.themeMode == ThemeMode.dark ||
                (settingsState.themeMode == ThemeMode.system &&
                    brightness == Brightness.dark);
            final fThemeData = isDark
                ? FTheme.neutral.dark.touch
                : FTheme.neutral.light.touch;

            return FTheme(
              data: fThemeData,
              child: MaterialApp.router(
                title: 'mine-flow',
                debugShowCheckedModeBanner: false,

                // --- Material Theme baseline (for fallback material routing components) ---
                theme: ThemeData(useMaterial3: true),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                ),
                themeMode: settingsState.themeMode,

                // --- Router (go_router) ---
                routerConfig: appRouter,

                // --- Localization (driven by SettingsCubit locale) ---
                locale: settingsState.settings.locale,
                supportedLocales: const [
                  Locale('en'), // English
                  Locale('id'), // Indonesian
                  Locale('en', 'US'),
                  Locale('id', 'ID'),
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // Wrap descendant tree in FTheme to guarantee ForUI theme availability across routes
                builder: (context, child) {
                  return FTheme(data: fThemeData, child: child!);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Creates the concrete [SettingsRepository] wired to Hive.
  SettingsRepository _createRepository() {
    return SettingsRepositoryImpl(localDataSource: SettingsLocalDataSource());
  }
}

/// Auth repository used only when [authCubit] has not been initialised (tests).
///
/// Resolves to an always-signed-out session so the widget tree renders the
/// login route without requiring Supabase wiring.
class _NoopAuthRepository implements AuthRepository {
  const _NoopAuthRepository();

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Auth not wired in this context.');
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
    throw UnimplementedError('Auth not wired in this context.');
  }

  @override
  Future<List<UserEntity>> getSiteRoster({String? siteId}) async {
    // Auth is not wired in this context (tests) — no roster available.
    return const [];
  }

  @override
  Stream<UserEntity?> get onAuthStateChanges => const Stream.empty();
}
