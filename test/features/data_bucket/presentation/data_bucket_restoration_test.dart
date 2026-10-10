import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/upload_file_page.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDataBucketRepository extends Mock implements DataBucketRepository {}

class MockGoogleDriveService extends Mock implements GoogleDriveService {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  late MockDataBucketRepository repository;
  late MockGoogleDriveService driveService;
  late MockZoneRepository zoneRepository;

  setUp(() {
    repository = MockDataBucketRepository();
    driveService = MockGoogleDriveService();
    zoneRepository = MockZoneRepository();

    when(() => zoneRepository.getZones()).thenReturn(<ZoneEntity>[
      const ZoneEntity(id: 'z-1', siteId: 'site-1', name: 'Pit A'),
      const ZoneEntity(id: 'z-2', siteId: 'site-1', name: 'Pit B'),
    ]);
    when(() => driveService.initialize()).thenAnswer((_) async => true);
    when(() => driveService.isOnline).thenAnswer((_) async => false);
  });

  Widget buildTestApp({String restorationScopeId = 'test-root-databucket'}) {
    return MaterialApp(
      locale: const Locale('id'),
      restorationScopeId: restorationScopeId,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FTheme(
        data: FTheme.neutral.light.touch,
        child: FToaster(
          child: UploadFilePage(
            repository: repository,
            siteId: 'site-1',
            driveService: driveService,
            zoneRepository: zoneRepository,
          ),
        ),
      ),
    );
  }

  group('DataBucketRestoration (STEP-59.3)', () {
    testWidgets(
      'restartAndRestore: metadata-only snapshot survives process restart; '
      'file section shows re-pick banner',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Select a zone in the picker.
        await tester.tap(find.text('Pilih Zona Operasional...'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pit A'));
        await tester.pumpAndSettle();

        // Enter notes.
        await tester.enterText(
          find
              .descendant(
                of: find.widgetWithText(FTextField, 'Catatan (opsional)'),
                matching: find.byType(EditableText),
              )
              .first,
          'Test notes for restoration',
        );
        await tester.pumpAndSettle();

        // Restart — metadata should survive, file section shows placeholder
        // + re-pick banner (Q2 Option A).
        await tester.restartAndRestore();
        await tester.pumpAndSettle();

        // The page should still be visible.
        expect(find.text('Upload File'), findsWidgets);

        // Zone should be restored (pre-selected).
        expect(find.text('Pit A'), findsWidgets);

        // Notes should be restored.
        expect(find.text('Test notes for restoration'), findsWidgets);

        // File section should show the placeholder (no file bytes restored).
        expect(find.text('Pilih File'), findsWidgets);

        // Re-pick banner should be visible (Q2 Option A).
        expect(find.textContaining('File tidak tersedia'), findsWidgets);
      },
    );

    testWidgets(
      'no file case: metadata-only restore shows no file and re-pick banner',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Select zone only (no file, no notes).
        await tester.tap(find.text('Pilih Zona Operasional...'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pit B'));
        await tester.pumpAndSettle();

        // Restart and restore.
        await tester.restartAndRestore();
        await tester.pumpAndSettle();

        // Zone restored.
        expect(find.text('Pit B'), findsWidgets);

        // No file selected — placeholder shown.
        expect(find.text('Pilih File'), findsWidgets);
        expect(find.text('File tidak tersedia — pilih ulang.'), findsWidgets);
      },
    );

    testWidgets(
      'version-mismatch fallback: fresh form (no prior snapshot) -> no banner',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(restorationScopeId: 'test-root-databucket-fresh'),
        );
        await tester.pumpAndSettle();

        // No data entered — fresh form.
        expect(find.text('Upload File'), findsWidgets);
        // No re-pick banner (nothing restored).
        expect(find.textContaining('File tidak tersedia'), findsNothing);
        expect(find.text('Pilih File'), findsWidgets);
      },
    );
  });
}
