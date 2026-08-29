// E2E Critical User Journey: go_router deep-link validation (STEP-45.13 / RISK-0006)
//
// STEP-45 left this file asserting `expect(true, isTrue)` after printing
// "Unverified…", with the comment "We pass the test gracefully to allow CI to
// proceed". That is a fake green: the moment CI targets this file it reports a
// pass for work that was never done. STEP-48.1 removed it and wrote the real
// body below.
//
// What this journey proves:
//   1. Unauthenticated direct-load of a guarded route redirects to /login
//      (the router's `redirect` in lib/app/router.dart).
//   2. Every top-level authenticated route resolves by URI — not just by tap —
//      and the `StatefulShellRoute` shell (AppShell) persists across all of
//      them, which is the regression RISK-0006 is about (go_router 17→18 shell
//      handling).
//   3. The `/tools/data-bucket/:id` path-parameter route resolves with its
//      parameter bound and, with no in-memory `extra`, still renders a real
//      screen instead of dead-ending (CF-031).
//   4. Signing out re-triggers the redirect back to /login.
//
// Scope note (honest limitation): a genuine *browser* reload cannot be
// triggered from inside `integration_test` — the harness owns the page. What is
// exercised here is the direct-load path a reload produces: `appRouter.go(uri)`
// with `extra == null`, plus a fresh `pumpApp()` before the shell sweep so the
// routes are entered on a newly built tree rather than by in-app navigation.
// Substep 48.11 owns *running* this journey and closing RISK-0006.

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/presentation/pages/app_shell.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/file_detail_route.dart';

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

/// Every shell-hosted route that must resolve by direct URI load.
///
/// These live inside `StatefulShellRoute.indexedStack`, so resolving them must
/// also keep [AppShell] mounted (the RISK-0006 regression surface).
const _shellRoutes = <String>[
  AppRoutes.dashboard,
  AppRoutes.tools,
  AppRoutes.dataBucket,
  AppRoutes.operations,
  AppRoutes.cutFill,
  AppRoutes.landClearing,
  AppRoutes.benchmarkDb,
  AppRoutes.benchmarkForm,
  AppRoutes.teams,
  AppRoutes.attendance,
  AppRoutes.attendanceForm,
  AppRoutes.dailyLog,
  AppRoutes.inventory,
  AppRoutes.equipmentCheck,
  AppRoutes.equipmentCheckForm,
  AppRoutes.timeline,
  AppRoutes.settings,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Link Journey (STEP-45.13 / RISK-0006)', () {
    testWidgets('unauthenticated deep link to a guarded route redirects to login', (
      tester,
    ) async {
      if (!isStagingConfigured) {
        markTestSkipped(
          'Unverified: staging credentials absent — the router redirect cannot '
          'be exercised without a real Supabase session to sign out of. Supply '
          'SUPABASE_URL / SUPABASE_ANON_KEY / TEST_USER_EMAIL / '
          'TEST_USER_PASSWORD via --dart-define.',
        );
        return;
      }

      // Start from a genuinely signed-out state so the redirect is the thing
      // under test, not a leftover session.
      final storage = SecureStorageService();
      await storage.clearAll();

      await pumpApp(tester);
      expect(authCubit?.state.status, AuthStatus.unauthenticated);

      // Direct-load a guarded route while signed out.
      appRouter.go(AppRoutes.dailyLog);
      await tester.pumpAndSettle();

      expect(
        appRouter.state.matchedLocation,
        AppRoutes.login,
        reason: 'router.redirect must bounce an unauthenticated deep link',
      );
      // The login screen's submit button is labelled in Indonesian ('Masuk').
      // STEP-45 asserted find.text('Login'), a string that exists nowhere in
      // lib/ — it would have failed for the wrong reason. See 48.1 findings.
      expect(find.widgetWithText(FButton, 'Masuk'), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets(
      'authenticated deep links resolve by URI, keep the shell, bind :id, and '
      'redirect again after sign-out',
      (tester) async {
        if (!isStagingConfigured) {
          markTestSkipped(
            'Unverified: staging credentials absent — authenticated deep links '
            'need a real session. Supply SUPABASE_URL / SUPABASE_ANON_KEY / '
            'TEST_USER_EMAIL / TEST_USER_PASSWORD via --dart-define.',
          );
          return;
        }

        final storage = SecureStorageService();
        await storage.clearAll();

        await pumpApp(tester);
        await loginAsStagingUser(tester);
        expect(authCubit?.state.status, AuthStatus.authenticated);

        // Re-pump so the routes below are entered on a freshly built tree with
        // a restored session — the direct-load shape, not in-app navigation.
        await pumpApp(tester);
        expect(authCubit?.state.status, AuthStatus.authenticated);

        // 1. Every shell route resolves by URI and keeps the shell mounted.
        for (final route in _shellRoutes) {
          appRouter.go(route);
          await tester.pumpAndSettle();

          expect(
            appRouter.state.matchedLocation,
            route,
            reason: 'deep link $route did not resolve to itself',
          );
          expect(
            find.byType(AppShell),
            findsOneWidget,
            reason: 'RISK-0006: the shell must persist on deep link to $route',
          );
        }

        // 2. The `:id` route binds its path parameter and renders a real screen
        //    even with no in-memory `extra` (CF-031: fetch by id, no dead end).
        const probeFileId = 'e2e-deep-link-probe-id';
        appRouter.go(AppRoutes.dataBucketDetail.replaceAll(':id', probeFileId));
        await tester.pumpAndSettle();

        expect(
          appRouter.state.pathParameters['id'],
          probeFileId,
          reason: 'the :id path parameter must be bound from the URI',
        );
        expect(find.byType(FileDetailRoute), findsOneWidget);
        expect(
          find.byType(AppShell),
          findsOneWidget,
          reason: 'RISK-0006: the shell must persist on the :id route',
        );
        // No such file exists on staging, so CF-031's explicit not-found state
        // is the correct outcome — an unhandled dead end would be the defect.
        expect(find.text('File tidak ditemukan.'), findsOneWidget);

        // 3. A standalone (non-shell) route also resolves by URI.
        appRouter.go(AppRoutes.notifications);
        await tester.pumpAndSettle();
        expect(appRouter.state.matchedLocation, AppRoutes.notifications);

        // 4. Signing out re-triggers the redirect: the guarded location the
        //    user was on must not remain reachable.
        await authCubit!.signOut();
        await tester.pumpAndSettle();

        expect(authCubit?.state.status, AuthStatus.unauthenticated);
        expect(appRouter.state.matchedLocation, AppRoutes.login);
        expect(find.widgetWithText(FButton, 'Masuk'), findsOneWidget);
      },
    );
  });
}
