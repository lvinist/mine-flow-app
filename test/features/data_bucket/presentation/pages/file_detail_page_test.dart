import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/file_detail_page.dart';
import 'package:mocktail/mocktail.dart';

class MockDataBucketRepository extends Mock implements DataBucketRepository {}

void main() {
  late MockDataBucketRepository mockRepository;

  final tFile = GeospatialFile(
    id: 'file-1',
    siteId: 'site-1',
    fileName: 'test_contour.shp',
    fileType: '.shp',
    driveFileId: 'drive-123',
    driveLink: 'https://drive.google.com/file/d/drive-123',
    createdAt: DateTime(2026, 7, 25),
    updatedAt: DateTime(2026, 7, 25),
  );

  setUp(() {
    mockRepository = MockDataBucketRepository();
  });

  Widget buildTestWidget() {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        home: FileDetailPage(file: tFile, repository: mockRepository),
      ),
    );
  }

  group('FileDetailPage Widget Tests', () {
    testWidgets(
      'renders delete confirmation dialog with FButton and zero TextButton',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Open popup menu
        final popupMenuFinder = find.byIcon(LucideIcons.moreVertical);
        expect(popupMenuFinder, findsOneWidget);
        await tester.tap(popupMenuFinder);
        await tester.pumpAndSettle();

        // Tap 'Hapus' popup menu item
        final deleteMenuItemFinder = find.widgetWithText(
          PopupMenuItem<String>,
          'Hapus',
        );
        expect(deleteMenuItemFinder, findsOneWidget);
        await tester.tap(deleteMenuItemFinder);
        await tester.pumpAndSettle();

        // Verify AlertDialog is displayed
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Hapus File'), findsOneWidget);

        // Verify zero TextButton inside dialog actions
        expect(find.widgetWithText(TextButton, 'Batal'), findsNothing);
        expect(find.widgetWithText(TextButton, 'Hapus'), findsNothing);
        expect(find.byType(TextButton), findsNothing);

        // Verify FButton is used for dialog actions
        expect(find.widgetWithText(FButton, 'Batal'), findsOneWidget);
        expect(find.widgetWithText(FButton, 'Hapus'), findsOneWidget);
      },
    );

    testWidgets(
      'cancelling delete dialog closes dialog without calling deleteFile',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LucideIcons.moreVertical));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Hapus'));
        await tester.pumpAndSettle();

        // Tap 'Batal' FButton
        await tester.tap(find.widgetWithText(FButton, 'Batal'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        verifyNever(() => mockRepository.deleteFile(any()));
      },
    );

    testWidgets('confirming delete dialog calls deleteFile and pops screen', (
      tester,
    ) async {
      when(() => mockRepository.deleteFile(tFile.id)).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.moreVertical));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Hapus'));
      await tester.pumpAndSettle();

      // Tap 'Hapus' FButton in dialog
      await tester.tap(find.widgetWithText(FButton, 'Hapus'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.deleteFile(tFile.id)).called(1);
    });
  });
}
