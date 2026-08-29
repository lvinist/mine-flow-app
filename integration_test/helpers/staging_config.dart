/// Reads staging credentials from dart-define.
///
/// See architecture/09-environments.md for staging config details. Values are
/// injected per run (`--dart-define=...`) from GitHub repository secrets; no
/// value is ever hard-coded, logged, or committed.
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
