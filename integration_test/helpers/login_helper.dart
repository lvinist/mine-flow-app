import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

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

  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Proof the login was actually accepted: the login screen is gone. Without
  // this a failed sign-in would leave the test on /login and any subsequent
  // "screen renders" assertion could pass for the wrong reason.
  expect(
    find.widgetWithText(FButton, 'Masuk'),
    findsNothing,
    reason:
        'Login as role "$role" was not accepted — still on the login screen. '
        'Check the staging account exists and the injected password is current.',
  );
}
