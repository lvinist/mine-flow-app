# mine-flow-app

> Unified Flutter client application (Android + Web) for mine-flow — an internal
> dashboard to monitor cut/fill volume, land clearing area, crew attendance, work
> timeline, daily logging, inventory tracking, and geospatial data bucket.
> See [`mine-flow-docs/architecture/03-architecture-overview.md`](../mine-flow-docs/architecture/03-architecture-overview.md)
> for the system-wide architecture.

## Overview

`mine-flow-app` is the single unified client for all users of the mine-flow
system. It runs as:

- **Android APK** — distributed directly to foremen operating in the field.
  Offline-first: core data entry works without internet and syncs to Supabase
  when connectivity is restored.
- **Flutter Web** — hosted on GitHub Pages for supervisors operating from the
  office; always-connected, access to reports and management features.

The app communicates directly with two backend services — no custom API server:

| Backend | What it handles |
|---------|-----------------|
| **Supabase** | Authentication, structured data (logs, checks, users), RLS-enforced access control |
| **Google Drive** | Heavy geospatial file storage (`.shp`, `.tiff`) uploaded directly from the app |

Internally, the codebase follows **Clean Architecture** (Data → Domain →
Presentation layers) organised by feature domain. State management uses the
**BLoC pattern** (`flutter_bloc`). See [`ARCHITECTURE.md`](ARCHITECTURE.md) for
the detailed internal design.

## Licensing

See [`LICENSING.md`](LICENSING.md) for the exact scope. The root `LICENSE`
(MIT) governs project-authored content. `LICENSE-THROUGHSTONE` applies only to
retained Throughstone-authored scaffold material.

## Tech stack

| Layer | Choice | Why |
|-------|--------|-----|
| Language | Dart 3.12+ | Stable, sound null-safety |
| Framework | Flutter 3.44+ | Cross-platform Android + Web from one codebase |
| State management | `flutter_bloc` + BLoC pattern | Predictable, testable state |
| Navigation | `go_router` | Declarative, web-URL-aware routing |
| Backend | Supabase (Auth + PostgreSQL) | Managed BaaS; eliminates custom server |
| Local storage | Hive (ADR-0001) | Fast, pure Dart, works on Web target |
| Secure storage | `flutter_secure_storage` | Android Keystore for tokens |
| File uploads | `googleapis` (Drive REST) | Standard Google SDK |

## Prerequisites

- **Flutter SDK** ≥ 3.47.1 (stable channel). Verify: `flutter --version`
- **Dart SDK** ≥ 3.12 (bundled with Flutter)
- **Java / JDK 17 (Temurin)** — required for AGP 9. Wire it via `flutter config --jdk-dir=<path>`.
- **`PUB_CACHE` must be on the same drive** as the Flutter SDK and the project (e.g., `setx PUB_CACHE D:\AppDev\.pub-cache` if the project is on `D:`). Otherwise, Gradle build fails with *"this and base files have different roots"* because Gradle cannot compute a relative path across Windows drive letters.
- **Android toolchain** (Android SDK, accepted licenses) — for APK builds
  - **Android emulator** `Pixel_6a` is required for the local device boot check (matches CI).
- **Chrome** and **chromedriver** — for Web E2E development
- **Kotlin/Gradle posture:** Local Android builds require AGP 9 built-in Kotlin (`android.builtInKotlin=true` in `gradle.properties`). `android.newDsl=false` is Flutter's compatibility shim (re-added automatically by the tool). (Note: `kotlin.compiler.execution.strategy` and `kotlin.incremental` flags are obsolete under AGP 9 and should be removed).
- **Supabase CLI** (optional, for running local Supabase) — `npm i -g supabase`
- A `.env` file at the repo root (copy from `.env.example`, fill in values)

## Setup

1. **Clone the workspace** (if not already done):
   ```bash
   git clone <mine-flow-app-remote-url> Code/mine-flow-app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Copy and fill `.env`:**
   ```bash
   cp .env.example .env
   # Edit .env — add your Supabase URL, anon key, and Google Drive client ID
   ```

4. **Accept Android licenses** (first time only):
   ```bash
   flutter doctor --android-licenses
   ```

## Contract Regeneration

The generated Supabase type file at `lib/core/data/models/generated/database.dart`
must be regenerated whenever you modify the schema in `supabase/migrations/`.

**Prerequisites:**
- Supabase CLI installed: `brew install supabase/tap/supabase` (or see https://supabase.com/docs/guides/cli)
- A non-production project provisioned (see STEP-42 for staging setup)

**Command:**
```bash
supabase gen types dart --project-id $SUPABASE_PROJECT_ID \
  > lib/core/data/models/generated/database.dart
```

Set `SUPABASE_PROJECT_ID` to your non-production project's ID (never production).
Commit the regenerated file in the same commit as the migration.

**CI gate:** `dart run tool/check_supabase_contracts.dart` fails the build if
migrations change without a corresponding update to the generated file.

## Running (local dev)

Credentials are injected via `--dart-define` at run time. Use the helper below
or expand the `dart-define` flags manually.

```bash
# Android (connected device or emulator)
flutter run \
  --dart-define=SUPABASE_URL=$(grep SUPABASE_URL .env | cut -d= -f2) \
  --dart-define=SUPABASE_ANON_KEY=$(grep SUPABASE_ANON_KEY .env | cut -d= -f2) \
  --dart-define=GOOGLE_DRIVE_CLIENT_ID=$(grep GOOGLE_DRIVE_CLIENT_ID .env | cut -d= -f2) \
  --dart-define=APP_ENV=local

# Web (Chrome)
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$(grep SUPABASE_URL .env | cut -d= -f2) \
  --dart-define=SUPABASE_ANON_KEY=$(grep SUPABASE_ANON_KEY .env | cut -d= -f2) \
  --dart-define=GOOGLE_DRIVE_CLIENT_ID=$(grep GOOGLE_DRIVE_CLIENT_ID .env | cut -d= -f2) \
  --dart-define=APP_ENV=local
```

## Testing

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific file
flutter test test/widget_test.dart
```

Test tiers (Doc 12 — Test Strategy):
- **Unit tests** — pure business logic (validators, formatters, BLoC states)
- **Integration tests** — BLoC ↔ mocked repository interactions
- **E2E tests** — `integration_test/` package against the Staging Supabase project

### Running Web E2E Tests Locally

To run web E2E tests locally, `chromedriver` is required and must match your installed Chrome version. `flutter test integration_test -d chrome` is *not supported*. Run chromedriver on port 4444 in the background before invoking `flutter drive`:

```bash
# Terminal 1: Start chromedriver
chromedriver --port=4444

# Terminal 2: Run tests
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_boots_test.dart \
  -d web-server \
  --browser-name=chrome \
  --dart-define=APP_ENV=staging
```
*(Note: Substitute the rest of the `--dart-define` secrets as needed to run actual credential-gated journeys).*

## Configuration

All runtime config is injected via `--dart-define` flags at build/run time.
Never committed to the repo.

| Variable | Where to get it |
|----------|----------------|
| `SUPABASE_URL` | Supabase Dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Project Settings → API |
| `GOOGLE_DRIVE_CLIENT_ID` | Google Cloud Console → APIs & Services → Credentials |
| `APP_ENV` | `local` / `staging` / `production` |

See `.env.example` for the full list with descriptions.

## Project structure

```
lib/
├── main.dart               # Entry point: init logging, Hive, Supabase, run app
├── app/
│   ├── app.dart            # Root MineFlowApp widget, theme, locale
│   ├── router.dart         # GoRouter route definitions
│   └── theme/
│       └── app_theme.dart  # Forest & Stone ThemeData (Doc 07)
├── core/
│   ├── constants/          # App-wide constants (env keys, default site_id)
│   ├── error/              # Base Failure types for the domain layer
│   ├── network/            # ConnectivityService (online/offline stream)
│   └── utils/              # Logger factory (buildLogger)
└── features/
    ├── auth/               # Authentication (STEP-3)
    │   ├── data/           # Supabase data source, models, repository impl
    │   ├── domain/         # Entities, repository interface, use cases
    │   └── presentation/   # BLoC, pages, widgets
    ├── attendance/         # Crew attendance (STEP-4)
    ├── daily_log/          # Daily structured logs (STEP-4)
    ├── equipment_check/    # SOP equipment checks (STEP-5)
    ├── tracking/           # Cut/fill, land clearing, inventory (STEP-7)
    ├── data_bucket/        # Google Drive geospatial file upload (STEP-8)
    └── reporting/          # PDF reports, work timeline (STEP-9)
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `SUPABASE_URL` is empty / app shows blank | Pass `--dart-define=SUPABASE_URL=...` when running |
| `flutter pub get` fails | Run `flutter doctor` — check SDK path and internet |
| Android build fails: license | Run `flutter doctor --android-licenses` and accept all |
| Android build fails: different roots | `PUB_CACHE` is on a different drive than the project. Set `PUB_CACHE` to the same drive as the Flutter SDK and project. |
| Android build fails: `kotlin-android` / `compileSdk` | A legacy plugin predates AGP 9. Upgrade the offending plugin to an AGP-9 native version. |
| Hive error on first run | Delete `build/` and re-run — Hive adapters may need regenerating |

**CI Troubleshooting Note:** CI job logs can be read from the local host without `gh`: use your GitHub PAT with `GET /repos/<owner>/<repo>/actions/jobs/<id>/logs` (follow the 302 redirect with a bare request omitting the GitHub `Authorization` header).
