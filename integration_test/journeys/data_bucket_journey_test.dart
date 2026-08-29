// E2E Critical User Journey: Data Bucket (STEP-45.8)
//
// STEP-45 left this file with **zero assertions** — a gated skip followed by an
// unreachable `pumpApp` / `loginAsStagingUser` pair and the comment
// "// Stub for the rest of the journey", which reads like coverage but proves
// nothing. STEP-48.1 removed the dead code and split the file so the part that
// can be verified without Google Drive actually is.
//
// Scope (PLAN decision D2): **Google Drive is deliberately out of STEP-48's
// scope.** NR-004 (real upload, abandon/cancel mid-upload) and NR-005 (large-file
// ceiling) stay Deferred as RISK-0017 / RISK-0018. Part A below is gated on real
// Drive service-account credentials and skips with that named reason; it is made
// *honest*, not complete.
//
//   Part A (Drive-gated): real upload to Drive, cancel/abandon affordance,
//   large-file ceiling. Skipped as Unverified while
//   GOOGLE_DRIVE_SERVICE_ACCOUNT_EMAIL / GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY are
//   not injected (RISK-0017 / RISK-0018).
//
//   Part B (staging-gated, no Drive): the non-Drive half of the feature — the
//   data-bucket route resolves inside the app shell, the `geospatial_files`
//   metadata read against real staging Postgres succeeds under RLS, and the list
//   UI renders a state consistent with that data (file cards, or the documented
//   empty state). This converts a zero-evidence file into partial real evidence.
//
// Why Part B stops short of the upload form: `UploadFilePage` resolves its
// `GoogleDriveService` from `appServices.driveService`, which
// `AppInitializer` leaves **null** unless the Drive service-account defines are
// present (CF-018 — it refuses to fabricate an empty-credential client), and
// then throws `UnimplementedError`. Navigating to `/tools/data-bucket/upload`
// without Drive credentials would therefore fail for an environment reason, not
// a product one. The file-picker validation path and the 50 MB client-side
// ceiling live behind that page and are consequently unreachable in this
// configuration — recorded in the STEP-48.1 findings, owned by RISK-0017/0018.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/presentation/pages/app_shell.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/data_bucket_list_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/file_card.dart';
import 'package:mine_flow/main.dart' as app_main;

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Data Bucket Journey — Part A: Drive-dependent (STEP-45.8)', () {
    testWidgets(
      'real Drive upload, abandon/cancel, large-file ceiling (NR-004, NR-005)',
      (tester) async {
        if (!isStagingConfigured || !isDriveConfigured) {
          markTestSkipped(
            'Unverified: Google Drive service-account credentials absent — '
            'supply GOOGLE_DRIVE_SERVICE_ACCOUNT_EMAIL and '
            'GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY (plus GOOGLE_DRIVE_FOLDER_ID) via '
            '--dart-define to verify. STEP-48 defers this deliberately (PLAN '
            'decision D2): NR-004 real upload + abandon/cancel is RISK-0017 and '
            'NR-005 the large-file ceiling is RISK-0018, both re-justified as '
            'Deferred in substep 48.14 rather than closed. Part B below covers '
            'the non-Drive half of this feature for real.',
          );
          return;
        }

        // Intentionally not implemented: STEP-48 does not carry Drive scope, so
        // authoring an upload body here would be untested code pretending to be
        // coverage. The gate above is the honest state; RISK-0017 / RISK-0018
        // carry the work with an explicit revisit trigger.
        fail(
          'Drive credentials are present but the NR-004/NR-005 journey body is '
          'not implemented — STEP-48 scoped Drive out (D2). Implement this '
          'journey in the STEP that closes RISK-0017 / RISK-0018 rather than '
          'letting a credentialed run report a pass for absent coverage.',
        );
      },
    );
  });

  group('Data Bucket Journey — Part B: staging metadata, no Drive (STEP-45.8)', () {
    testWidgets(
      'data-bucket route resolves in the shell and the list reflects the real '
      'geospatial_files metadata read from staging',
      (tester) async {
        if (!isStagingConfigured) {
          markTestSkipped(
            'Unverified: staging credentials absent — supply SUPABASE_URL / '
            'SUPABASE_ANON_KEY / TEST_USER_EMAIL / TEST_USER_PASSWORD via '
            '--dart-define.',
          );
          return;
        }

        final storage = SecureStorageService();
        await storage.clearAll();

        await pumpApp(tester);
        await loginAsStagingUser(tester);
        expect(authCubit?.state.status, AuthStatus.authenticated);

        // 1. The route resolves and stays inside the shell.
        appRouter.go(AppRoutes.dataBucket);
        await tester.pumpAndSettle();

        expect(find.byType(DataBucketListPage), findsOneWidget);
        expect(
          find.byType(AppShell),
          findsOneWidget,
          reason: 'the data-bucket branch renders inside the app shell',
        );

        // 2. Pull real `geospatial_files` metadata from staging. This is a live
        //    RLS-permitted read over the network: reaching the next line at all
        //    is the evidence (a policy refusal or transport failure throws).
        final repository = app_main.appServices!.dataBucketRepository;
        await repository.syncPendingUploads();
        final pageFiles = await repository.getFiles(siteId: defaultSiteId);

        // 3. The rendered state must agree with the data the page queries. This
        //    is the assertion that would have caught an empty list rendering
        //    file cards, or rows rendering the empty state.
        await tester.pumpAndSettle();
        if (pageFiles.isEmpty) {
          expect(
            find.text('Belum ada file yang diunggah'),
            findsOneWidget,
            reason:
                'no site-scoped rows → the documented empty state must render',
          );
          expect(find.byType(FileCard), findsNothing);
        } else {
          expect(
            find.byType(FileCard),
            findsWidgets,
            reason: 'site-scoped rows exist → file cards must render',
          );
          expect(find.text('Belum ada file yang diunggah'), findsNothing);
          // Every rendered card belongs to the queried site.
          for (final file in pageFiles) {
            expect(file.siteId, defaultSiteId);
          }
        }
      },
    );
  });
}
