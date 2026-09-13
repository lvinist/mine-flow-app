import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/file_detail_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/file_detail_route.dart';
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
        home: FToaster(
          child: FileDetailPage(file: tFile, repository: mockRepository),
        ),
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

        // Verify the ForUI dialog is displayed
        expect(find.byType(FDialog), findsOneWidget);
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

    testWidgets(
      'renders as AppResponsiveSheet inspector with explicit Buka di Google Drive and Hapus Berkas footer actions',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Verify inspector mode and structure
        final sheetFinder = find.byType(AppResponsiveSheet);
        expect(sheetFinder, findsOneWidget);
        final sheetWidget = tester.widget<AppResponsiveSheet>(sheetFinder);
        expect(sheetWidget.mode, AppResponsiveSheetMode.readOnlyInspector);
        expect(sheetWidget.title, 'Detail File');
        expect(sheetWidget.subtitle, tFile.fileName);

        // Verify explicit footer actions
        expect(
          find.widgetWithText(FButton, 'Buka di Google Drive'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FButton, 'Hapus Berkas'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping footer Hapus Berkas triggers ForUI delete confirmation dialog directly',
      (tester) async {
        when(() => mockRepository.deleteFile(tFile.id)).thenAnswer((_) async {});

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap the footer Hapus Berkas button directly (without opening popup menu)
        await tester.tap(find.widgetWithText(FButton, 'Hapus Berkas'));
        await tester.pumpAndSettle();

        // Verify FDialog confirmation appears
        expect(find.byType(FDialog), findsOneWidget);
        expect(find.text('Hapus File'), findsOneWidget);

        // Cancel first
        await tester.tap(find.widgetWithText(FButton, 'Batal'));
        await tester.pumpAndSettle();
        verifyNever(() => mockRepository.deleteFile(any()));

        // Tap footer delete again, then confirm
        await tester.tap(find.widgetWithText(FButton, 'Hapus Berkas'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FButton, 'Hapus'));
        await tester.pumpAndSettle();

        verify(() => mockRepository.deleteFile(tFile.id)).called(1);
      },
    );

    testWidgets(
      'FileDetailRoute cold load fetches file by ID from repository when extra is null',
      (tester) async {
        when(() => mockRepository.getFile('file-1')).thenAnswer(
          (_) async => tFile,
        );

        await tester.pumpWidget(
          FTheme(
            data: FTheme.neutral.light.touch,
            child: MaterialApp(
              home: FToaster(
                child: FileDetailRoute(
                  file: null,
                  fileId: 'file-1',
                  repository: mockRepository,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Detail File'), findsOneWidget);
        expect(find.text(tFile.fileName), findsWidgets);
        expect(find.widgetWithText(FButton, 'Hapus Berkas'), findsOneWidget);
        verify(() => mockRepository.getFile('file-1')).called(1);
      },
    );

    testWidgets(
      'FileDetailRoute cold load displays not-found state when file does not exist',
      (tester) async {
        when(() => mockRepository.getFile('file-missing')).thenAnswer(
          (_) async => null,
        );

        await tester.pumpWidget(
          FTheme(
            data: FTheme.neutral.light.touch,
            child: MaterialApp(
              home: FToaster(
                child: FileDetailRoute(
                  file: null,
                  fileId: 'file-missing',
                  repository: mockRepository,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('File Tidak Ditemukan'), findsOneWidget);
        expect(find.widgetWithText(FButton, 'Kembali'), findsOneWidget);
      },
    );

    testWidgets(
      'FileDetailRoute cold load displays error state when repository throws',
      (tester) async {
        when(() => mockRepository.getFile('file-error')).thenThrow(
          Exception('Unauthorized: access denied to geospatial files'),
        );

        await tester.pumpWidget(
          FTheme(
            data: FTheme.neutral.light.touch,
            child: MaterialApp(
              home: FToaster(
                child: FileDetailRoute(
                  file: null,
                  fileId: 'file-error',
                  repository: mockRepository,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gagal Memuat File'), findsOneWidget);
        expect(find.textContaining('Unauthorized: access denied'), findsOneWidget);
        expect(find.widgetWithText(FButton, 'Kembali'), findsOneWidget);
      },
    );

    testWidgets(
      'FileDetailPage sets isBusy true on AppResponsiveSheet while deletion is in-flight',
      (tester) async {
        final completer = Completer<void>();
        when(() => mockRepository.deleteFile(tFile.id)).thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap Hapus Berkas footer button
        await tester.tap(find.widgetWithText(FButton, 'Hapus Berkas'));
        await tester.pumpAndSettle();

        // Confirm delete in dialog
        await tester.tap(find.widgetWithText(FButton, 'Hapus'));
        await tester.pump(); // Advance past dialog pop

        // Verify sheet is now busy
        final sheetFinder = find.byType(AppResponsiveSheet);
        expect(sheetFinder, findsOneWidget);
        final sheetWidget = tester.widget<AppResponsiveSheet>(sheetFinder);
        expect(sheetWidget.isBusy, isTrue);

        // Complete deletion
        completer.complete();
        await tester.pumpAndSettle();
      },
    );
  });
}
