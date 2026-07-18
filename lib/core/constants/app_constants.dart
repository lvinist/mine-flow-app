// Application-wide constants for mine-flow.
//
// Environment values are injected at build time via `--dart-define` from
// GitHub Actions secrets (see Doc 09 — Environments §2). Locally they come
// from the `.env` file, which is read by the build tooling and passed as
// dart-define flags. Never hardcode real values here.

/// The Supabase project URL for the active environment.
/// Injected at build time: `--dart-define=SUPABASE_URL=...`
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

/// The Supabase anon (public) key for the active environment.
/// This key is safe to embed in the client — RLS enforces actual security.
/// Injected at build time: `--dart-define=SUPABASE_ANON_KEY=...`
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// The Google Drive OAuth 2.0 client ID for the active environment.
/// Injected at build time: `--dart-define=GOOGLE_DRIVE_CLIENT_ID=...`
const String googleDriveClientId =
    String.fromEnvironment('GOOGLE_DRIVE_CLIENT_ID');

/// The build environment identifier (local | staging | production).
/// Injected at build time: `--dart-define=APP_ENV=local`
const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'local');

/// The default site identifier for the MVP (single-site).
///
/// All records carry a `site_id` for future multi-tenancy (see Doc 16 — Identity
/// & Auth, §5 Multi-Tenancy and Doc 02 — Phasing & Roadmap, Don't-Foreclose DF-1).
/// For Phase 1 this is a fixed UUID seeded in the database migration.
const String defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
