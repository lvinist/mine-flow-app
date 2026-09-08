/// Reads staging credentials from dart-define.
///
/// See architecture/09-environments.md for staging config details. Values are
/// injected per run (`--dart-define=...`) from GitHub repository secrets; no
/// value is ever hard-coded, logged, or committed.
library;

import 'package:integration_test/integration_test.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const googleDriveClientId = String.fromEnvironment('GOOGLE_DRIVE_CLIENT_ID');
const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'test');
const testUserEmail = String.fromEnvironment('TEST_USER_EMAIL');
const testUserPassword = String.fromEnvironment('TEST_USER_PASSWORD');

/// Exposes whether staging credentials were provided at test boot time.
/// Used by test journeys to mark themselves as "Unverified" when absent,
/// rather than failing opaquely.
bool get isStagingConfigured =>
    supabaseUrl.isNotEmpty &&
    supabaseAnonKey.isNotEmpty &&
    testUserEmail.isNotEmpty &&
    testUserPassword.isNotEmpty;

// Per-role credentials for RLS testing (STEP-45.12, wired in STEP-48.0/48.1).
const testForemanEmail = String.fromEnvironment('TEST_FOREMAN_EMAIL');
const testForemanPassword = String.fromEnvironment('TEST_FOREMAN_PASSWORD');
const testSupervisorEmail = String.fromEnvironment('TEST_SUPERVISOR_EMAIL');
const testSupervisorPassword = String.fromEnvironment(
  'TEST_SUPERVISOR_PASSWORD',
);

/// Crew-role credentials.
///
/// STEP-48.0 created a `crew@mineflow.dev` account in staging but did **not**
/// add `TEST_CREW_EMAIL` / `TEST_CREW_PASSWORD` repository secrets, so the crew
/// leg of the RLS matrix stays unavailable to the suite. [hasCrewAccount] is
/// false until those two secrets exist; nothing silently substitutes another
/// role's credentials for crew (see `login_helper.dart`).
const testCrewEmail = String.fromEnvironment('TEST_CREW_EMAIL');
const testCrewPassword = String.fromEnvironment('TEST_CREW_PASSWORD');

/// Whether the supervisor **and** foreman credential pairs were both injected.
///
/// This gates the per-role RLS matrix. It deliberately does not include crew —
/// see [hasCrewAccount].
bool get hasPerRoleAccounts =>
    testForemanEmail.isNotEmpty &&
    testForemanPassword.isNotEmpty &&
    testSupervisorEmail.isNotEmpty &&
    testSupervisorPassword.isNotEmpty;

/// Whether a dedicated crew-role credential pair was injected.
bool get hasCrewAccount =>
    testCrewEmail.isNotEmpty && testCrewPassword.isNotEmpty;

/// Whether Google Drive service-account credentials were injected.
///
/// Drive-dependent coverage (NR-004 / NR-005 → RISK-0017 / RISK-0018) is
/// deliberately out of STEP-48's scope (PLAN decision D2); journeys read this
/// to skip **honestly** with a named reason instead of asserting nothing.
const googleDriveServiceAccountEmail = String.fromEnvironment(
  'GOOGLE_DRIVE_SERVICE_ACCOUNT_EMAIL',
);
const googleDriveServiceAccountKey = String.fromEnvironment(
  'GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY',
);

bool get isDriveConfigured =>
    googleDriveServiceAccountEmail.isNotEmpty &&
    googleDriveServiceAccountKey.isNotEmpty;

/// Records that an integration-test body passed its honest skip gates and
/// its journey is actually executing.
///
/// **Channel note (STEP-48.29):** on web, app-side `print()` output is NOT
/// forwarded into the `flutter drive` tool log — the only app→driver channel
/// is `reportData`, which the extended driver serializes into the per-file
/// `result {...}` JSON (`data.e2e_executed`). On Android, `flutter test`
/// forwards stdout, but we use reportData on both platforms so the guard
/// (`tool/ci/check_e2e_executed.dart`) has ONE grammar.
///
/// Call this immediately after the last skip gate, before the journey body.
/// CI fails the job if a file's result carries no executed/skipped markers.
void recordE2eExecuted(String testName) {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  binding.reportData ??= <String, dynamic>{};
  final list =
      binding.reportData!.putIfAbsent('e2e_executed', () => <String>[]) as List;
  list.add(testName);
}

/// Records a named, expected skip (credentials absent, Drive/D2 →
/// RISK-0017/0018, crew → RISK-0021) in `reportData` as `e2e_skipped`.
///
/// Call this immediately before `markTestSkipped` so the aggregate guard can
/// tell an honest skip from a wholesale one.
void recordE2eSkipped(String reason) {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  binding.reportData ??= <String, dynamic>{};
  final list =
      binding.reportData!.putIfAbsent('e2e_skipped', () => <String>[]) as List;
  list.add(reason);
}
