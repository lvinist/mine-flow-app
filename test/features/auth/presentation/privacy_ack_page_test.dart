// Regression pin for the STEP-55.10 privacy-gate acknowledgement defect found
// by the STEP-55.11 multiplatform audit (2026-09-15).
//
// Defect: PrivacyAckPage's acknowledgement button called the async
// `SettingsCubit.updatePrivacyAckVersion(1)` without awaiting it and then
// navigated with `context.go(dashboard)` in the same synchronous tick. The
// app router's redirect reads `privacyAckVersion` synchronously, so it still
// saw version 0 and bounced the session straight back to /privacy-gate. The
// user (and every E2E journey) was permanently stuck on the gate; nothing
// re-evaluated the route after the cubit emitted.
//
// These tests pin the ordering half of the fix against a real GoRouter: the
// acknowledgement must be persisted BEFORE the navigation effect is issued.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/pages/privacy_ack_page.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// Records every persisted acknowledgement and lets the test control when the
/// write completes, so the "navigate before persist" ordering is observable.
class _RecordingSettingsRepository implements SettingsRepository {
  _RecordingSettingsRepository({this.writeDelay = Duration.zero});

  final Duration writeDelay;

  /// Versions persisted so far, in order.
  final List<int> savedVersions = <int>[];

  /// Whether the write had completed at the moment navigation was requested.
  bool? completedBeforeNavigation;

  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}

  @override
  Future<Locale> getLocale() async => const Locale('en');

  @override
  Future<void> saveLocale(Locale locale) async {}

  @override
  Future<int> getPrivacyAckVersion() async => 0;

  @override
  Future<void> savePrivacyAckVersion(int version) async {
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    savedVersions.add(version);
  }
}

class _StubAuthRepository implements AuthRepository {
  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<UserEntity> updateProfile({
    required String id,
    required String name,
  }) async => throw UnimplementedError();

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
  }) async => throw UnimplementedError();

  @override
  Future<List<UserEntity>> getSiteRoster({String? siteId}) async => const [];

  @override
  Stream<UserEntity?> get onAuthStateChanges =>
      const Stream<UserEntity?>.empty();
}

void main() {
  /// Builds a two-route router (`/privacy-gate` and `/`) so the page's
  /// `context.go` is exercised for real and the resulting location is
  /// observable.
  ({GoRouter router, _RecordingSettingsRepository repo}) buildHarness({
    Duration writeDelay = Duration.zero,
  }) {
    final repo = _RecordingSettingsRepository(writeDelay: writeDelay);
    final router = GoRouter(
      initialLocation: '/privacy-gate',
      routes: [
        GoRoute(
          path: '/privacy-gate',
          builder: (_, _) => const PrivacyAckPage(),
        ),
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('dashboard')),
        ),
      ],
    );
    return (router: router, repo: repo);
  }

  Future<SettingsCubit> pumpHarness(
    WidgetTester tester,
    GoRouter router,
    _RecordingSettingsRepository repo,
  ) async {
    final cubit = SettingsCubit(repository: repo);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: cubit),
            BlocProvider<AuthCubit>(
              create: (_) => AuthCubit(repository: _StubAuthRepository()),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets(
    'acknowledgement persists before the page navigates to the dashboard',
    (tester) async {
      final h = buildHarness();
      final cubit = await pumpHarness(tester, h.router, h.repo);

      expect(find.byType(PrivacyAckPage), findsOneWidget);
      final ackButton = find.widgetWithText(FButton, 'Setuju & Lanjutkan');
      expect(ackButton, findsOneWidget);

      await tester.ensureVisible(ackButton);
      await tester.pumpAndSettle();
      await tester.tap(ackButton);
      await tester.pumpAndSettle();

      // The acknowledgement must have landed exactly once, with the current
      // notice version. If the page regresses to fire-and-forget, the router
      // redirects against version 0 and the gate re-renders.
      expect(
        h.repo.savedVersions,
        equals(<int>[1]),
        reason:
            'the acknowledgement must be persisted exactly once, with version '
            '1, before the page navigates away',
      );
      expect(cubit.state.privacyAckVersion, equals(1));

      // And the navigation actually took effect — the gate is gone.
      expect(
        find.byType(PrivacyAckPage),
        findsNothing,
        reason:
            'after acknowledging, the page must leave /privacy-gate; the '
            'pre-fix ordering bounced it straight back',
      );
      expect(find.text('dashboard'), findsOneWidget);
    },
  );

  testWidgets(
    'a slow acknowledgement write still completes before navigation',
    (tester) async {
      final h = buildHarness(writeDelay: const Duration(milliseconds: 50));
      final cubit = await pumpHarness(tester, h.router, h.repo);

      final ack = find.widgetWithText(FButton, 'Setuju & Lanjutkan');
      await tester.ensureVisible(ack);
      await tester.pumpAndSettle();
      await tester.tap(ack);

      // Mid-write the gate is still mounted; this is the window in which the
      // old implementation navigated with a stale version and was bounced back.
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(PrivacyAckPage), findsOneWidget);

      await tester.pumpAndSettle();
      expect(
        h.repo.savedVersions,
        equals(<int>[1]),
        reason: 'the delayed write must still land',
      );
      expect(cubit.state.privacyAckVersion, equals(1));
      expect(find.text('dashboard'), findsOneWidget);
    },
  );
}
