import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/auth/presentation/pages/privacy_ack_page.dart';

import 'staging_config.dart';

/// The staging roles the suite can authenticate as.
///
/// A role is only usable when its credential pair was injected via
/// `--dart-define`; see [credentialsForRole].
const stagingRoles = <String>['supervisor', 'foreman', 'crew'];

/// Returns the `(email, password)` pair for [role], or `null` when that role's
/// credentials were not injected.
///
/// STEP-48.0 created three staging accounts (`supervisor@`, `foreman@`,
/// `crew@mineflow.dev`) but published only `TEST_USER_*`, `TEST_SUPERVISOR_*`
/// and `TEST_FOREMAN_*` as repository secrets. Crew therefore resolves to
/// `null` unless `TEST_CREW_EMAIL` / `TEST_CREW_PASSWORD` are supplied.
///
/// Resolution order per role:
///   * `supervisor` → `TEST_SUPERVISOR_*`, else the shared `TEST_USER_*` pair
///     (48.0 assigned the shared account the supervisor role, so this is a
///     truthful fallback, not a substitution).
///   * `foreman` → `TEST_FOREMAN_*` only. Never falls back: a supervisor
///     session masquerading as a foreman would silently invalidate every
///     role-scoped assertion.
///   * `crew` → `TEST_CREW_*` only, same reasoning.
({String email, String password})? credentialsForRole(String role) {
  switch (role) {
    case 'supervisor':
      if (testSupervisorEmail.isNotEmpty && testSupervisorPassword.isNotEmpty) {
        return (email: testSupervisorEmail, password: testSupervisorPassword);
      }
      if (testUserEmail.isNotEmpty && testUserPassword.isNotEmpty) {
        return (email: testUserEmail, password: testUserPassword);
      }
      return null;
    case 'foreman':
      if (testForemanEmail.isNotEmpty && testForemanPassword.isNotEmpty) {
        return (email: testForemanEmail, password: testForemanPassword);
      }
      return null;
    case 'crew':
      if (hasCrewAccount) {
        return (email: testCrewEmail, password: testCrewPassword);
      }
      return null;
    default:
      throw ArgumentError.value(
        role,
        'role',
        'Unknown staging role; expected one of $stagingRoles',
      );
  }
}

/// Logs in through the real login screen as the staging user for [role].
///
/// The app must already be pumped (see `pumpApp`) and sitting on the login
/// screen. On return the caller is authenticated; the helper **fails the test**
/// rather than returning quietly if that cannot be achieved:
///
///   * missing staging credentials → `fail(...)`. Callers are expected to guard
///     with `if (!isStagingConfigured) { markTestSkipped(...); return; }` first,
///     so reaching this point means the guard is missing. A silent return would
///     leave the test on the login screen where later assertions could pass by
///     accident — the same class of defect as a placeholder assertion.
///   * missing credentials for the requested [role] → `fail(...)` naming the
///     two `--dart-define`s needed. `role:` is never quietly downgraded to
///     another account, so a `role: 'foreman'` call can never be mistaken for
///     role-specific coverage when only the shared user exists. Use
///     `hasPerRoleAccounts` / `hasCrewAccount` to gate role-specific tests.
///   * login not accepted (still on the login screen) → `fail(...)`.
///
/// Finder note: fields are located via `find.byType(EditableText)` per
/// RISK-0009 (flutter/flutter#191095 — a `TextField`-typed finder under forui's
/// `MergeSemantics` tripped an assertion), not via `TextField`.
Future<void> loginAsStagingUser(
  WidgetTester tester, {
  String role = 'supervisor',
}) async {
  if (!isStagingConfigured) {
    fail(
      'loginAsStagingUser called without staging credentials. Supply '
      'SUPABASE_URL / SUPABASE_ANON_KEY / TEST_USER_EMAIL / TEST_USER_PASSWORD '
      'via --dart-define, or guard the test with '
      '`if (!isStagingConfigured) { markTestSkipped(...); return; }`.',
    );
  }

  final credentials = credentialsForRole(role);
  if (credentials == null) {
    fail(
      'No staging credentials for role "$role". Supply '
      'TEST_${role.toUpperCase()}_EMAIL / TEST_${role.toUpperCase()}_PASSWORD '
      'via --dart-define. This helper never substitutes another role\'s '
      'account, because that would invalidate role-scoped assertions.',
    );
  }

  final submitButton = find.widgetWithText(FButton, 'Masuk');
  expect(
    submitButton,
    findsOneWidget,
    reason:
        'loginAsStagingUser expects the app to be on the login screen; the '
        '"Masuk" submit button was not found.',
  );

  final emailField = find.byType(EditableText).first;
  final passwordField = find.byType(EditableText).last;

  await tester.enterText(emailField, credentials.email);
  await tester.enterText(passwordField, credentials.password);
  await tester.pumpAndSettle();

  // FScaffold now resizes the login page for the real Android keyboard. Clear
  // focus/insets before locating and tapping the submit action; otherwise the
  // stale pre-keyboard finder can tap outside the resized button while still
  // succeeding on desktop web.
  FocusManager.instance.primaryFocus?.unfocus();
  tester.view.viewInsets = FakeViewPadding.zero;
  await tester.pumpAndSettle();

  final visibleSubmitButton = find.widgetWithText(FButton, 'Masuk');
  expect(visibleSubmitButton, findsOneWidget);
  await tester.ensureVisible(visibleSubmitButton);
  await tester.pumpAndSettle();
  await tester.tap(visibleSubmitButton);

  // A real Supabase sign-in is not tracked as a Flutter frame. On Android the
  // HTTP response can arrive after pumpAndSettle returns, while the web runner
  // usually completes it first. Wait on the actual auth state instead of the
  // button text (which also disappears temporarily while isSubmitting=true).
  for (
    var i = 0;
    i < 300 && authCubit?.state.status != AuthStatus.authenticated;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();

  // Prove the login was actually accepted before checking the route. Without
  // this a still-pending sign-in can hide the button behind its progress icon
  // and look indistinguishable from successful navigation.
  expect(
    authCubit?.state.status,
    AuthStatus.authenticated,
    reason: 'Login as role "$role" did not reach authenticated state.',
  );
  expect(
    find.widgetWithText(FButton, 'Masuk'),
    findsNothing,
    reason:
        'Login as role "$role" was not accepted — still on the login screen. '
        'Check the staging account exists and the injected password is current.',
  );

  // STEP-55.10 added a first-login privacy gate (RISK-0011): a freshly
  // authenticated session whose persisted `privacyAckVersion` is < 1 is
  // redirected to [AppRoutes.privacyGate] and held there until the notice is
  // acknowledged. Every journey that logs in therefore lands on the gate, not
  // on its target route. Clearing secure storage at the start of each journey
  // (the suite's own hygiene step) is exactly what makes the gate fire, so the
  // acknowledgement belongs here, once, for every caller.
  //
  // Without this the journey is parked on /privacy-gate and every subsequent
  // `appRouter.go(target)` is redirected back — the 2026-09-14/15 CI failure
  // class that took out 13 of 16 files on both platforms with
  // `Found 0 widgets with type "<FeatureScreen>"`.
  await acknowledgePrivacyGateIfPresent(tester, role: role);
}

/// Dismisses the first-login privacy notice when the router is holding the
/// session on [AppRoutes.privacyGate].
///
/// No-op when the gate is not shown (an already-acknowledged session, or a
/// build without the gate), so callers stay correct either way. Fails loudly if
/// the gate is displayed but cannot be cleared, because silently continuing
/// would leave the caller asserting against the wrong screen — the same
/// placeholder-pass class this suite exists to prevent.
Future<void> acknowledgePrivacyGateIfPresent(
  WidgetTester tester, {
  String role = 'supervisor',
}) async {
  if (find.byType(PrivacyAckPage).evaluate().isEmpty) return;

  // The acknowledgement button carries its localized label; the privacy page
  // exposes it through [PrivacyAckPage]'s single primary action.
  final ackButton = find.descendant(
    of: find.byType(PrivacyAckPage),
    matching: find.byType(FButton),
  );
  expect(
    ackButton,
    findsWidgets,
    reason: 'the privacy gate must expose an acknowledgement action',
  );

  // The header sign-out button is also an FButton; the acknowledgement is the
  // one inside the card. Prefer the button whose label is not the sign-out
  // action and fall back to the trailing button, so a copy change cannot
  // silently break the whole suite.
  final labelled = find.descendant(
    of: find.byType(PrivacyAckPage),
    matching: find.byWidgetPredicate((w) {
      if (w is! FButton) return false;
      final child = w.child;
      if (child is! Text) return false;
      final data = child.data;
      return data != null && !data.toLowerCase().contains('keluar');
    }),
  );
  final target = labelled.evaluate().isNotEmpty
      ? labelled.first
      : ackButton.last;

  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();

  // Prove the gate actually cleared rather than assuming the tap landed.
  for (
    var i = 0;
    i < 50 && find.byType(PrivacyAckPage).evaluate().isNotEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(
    find.byType(PrivacyAckPage),
    findsNothing,
    reason:
        'the privacy gate did not clear for role "$role"; the acknowledgement '
        'tap was not registered or the redirect is not releasing the session.',
  );
}
