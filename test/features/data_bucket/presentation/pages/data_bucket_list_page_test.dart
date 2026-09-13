import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/data_bucket_list_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/file_card.dart';
import 'package:mocktail/mocktail.dart';

class MockDataBucketRepository extends Mock implements DataBucketRepository {}

void main() {
  late MockDataBucketRepository mockRepository;

  final testFile = GeospatialFile(
    id: 'file-101',
    siteId: 'site-1',
    fileName: 'pit_survey.dxf',
    fileType: '.dxf',
    driveFileId: 'drive-pit-101',
    driveLink: 'https://drive.google.com/file/d/drive-pit-101',
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  setUp(() {
    mockRepository = MockDataBucketRepository();
    when(
      () => mockRepository.getFiles(
        siteId: any(named: 'siteId'),
        zoneId: any(named: 'zoneId'),
        fileType: any(named: 'fileType'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getFiles(
        siteId: any(named: 'siteId'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.watchFiles(
        siteId: any(named: 'siteId'),
        zoneId: any(named: 'zoneId'),
        fileType: any(named: 'fileType'),
      ),
    ).thenAnswer((_) => const Stream<List<GeospatialFile>>.empty());
  });

  Widget buildTestWidget({GoRouter? router}) {
    if (router != null) {
      return FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        home: DataBucketListPage(repository: mockRepository, siteId: 'site-1'),
      ),
    );
  }

  group('DataBucketListPage Widget Tests', () {
    testWidgets('renders Upload File FButton (report action removed in CF-029)', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Upload File FButton (FAB replaced per FC-54.9-009)
      expect(
        find.widgetWithText(FButton, 'Upload File'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);

      // CF-029: the "Data Bucket report" was removed.
      expect(find.bySemanticsLabel('Buat Laporan Data Bucket'), findsNothing);
    });

    testWidgets('tapping Upload File navigates to AppRoutes.dataBucketUpload via GoRouter and refreshes on return', (
      tester,
    ) async {
      var uploadRoutePushed = false;
      final router = GoRouter(
        initialLocation: AppRoutes.dataBucket,
        routes: [
          GoRoute(
            path: AppRoutes.dataBucket,
            builder: (context, state) => DataBucketListPage(
              repository: mockRepository,
              siteId: 'site-1',
            ),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (context, state) {
                  uploadRoutePushed = true;
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Tutup Upload'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(router: router));
      await tester.pumpAndSettle();

      // Initial load was called once
      verify(() => mockRepository.getFiles(siteId: 'site-1')).called(1);

      // Tap Upload File button
      await tester.tap(find.widgetWithText(FButton, 'Upload File'));
      await tester.pumpAndSettle();

      expect(uploadRoutePushed, isTrue);
      expect(find.text('Tutup Upload'), findsOneWidget);

      // Pop back to list
      await tester.tap(find.text('Tutup Upload'));
      await tester.pumpAndSettle();

      // Returning triggers RefreshFiles which re-invokes getFiles
      verify(() => mockRepository.getFiles(siteId: 'site-1')).called(1);
    });

    testWidgets('tapping file card navigates to AppRoutes.dataBucketFileDetail via GoRouter', (
      tester,
    ) async {
      when(
        () => mockRepository.getFiles(
          siteId: any(named: 'siteId'),
        ),
      ).thenAnswer((_) async => [testFile]);

      var detailRoutePushedWithId = '';
      final router = GoRouter(
        initialLocation: AppRoutes.dataBucket,
        routes: [
          GoRoute(
            path: AppRoutes.dataBucket,
            builder: (context, state) => DataBucketListPage(
              repository: mockRepository,
              siteId: 'site-1',
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  detailRoutePushedWithId = state.pathParameters['id'] ?? '';
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Tutup Detail'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(router: router));
      await tester.pumpAndSettle();

      // Verify card rendered
      expect(find.byType(FileCard), findsOneWidget);
      expect(find.text('pit_survey.dxf'), findsOneWidget);

      // Tap card to navigate
      await tester.tap(find.byType(FileCard));
      await tester.pumpAndSettle();

      expect(detailRoutePushedWithId, 'file-101');
      expect(find.text('Tutup Detail'), findsOneWidget);

      // Pop back to list
      await tester.tap(find.text('Tutup Detail'));
      await tester.pumpAndSettle();

      // Returning triggers RefreshFiles
      verify(() => mockRepository.getFiles(siteId: 'site-1')).called(2);
    });
  });
}
