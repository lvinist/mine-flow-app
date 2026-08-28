/// Reads staging credentials from dart-define.
///
/// See architecture/09-environments.md for staging config details.
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

// Per-role credentials for RLS testing (STEP-45.12)
const testForemanEmail = String.fromEnvironment('TEST_FOREMAN_EMAIL');
const testForemanPassword = String.fromEnvironment('TEST_FOREMAN_PASSWORD');
const testSupervisorEmail = String.fromEnvironment('TEST_SUPERVISOR_EMAIL');
const testSupervisorPassword = String.fromEnvironment(
  'TEST_SUPERVISOR_PASSWORD',
);

bool get hasPerRoleAccounts =>
    testForemanEmail.isNotEmpty &&
    testForemanPassword.isNotEmpty &&
    testSupervisorEmail.isNotEmpty &&
    testSupervisorPassword.isNotEmpty;
