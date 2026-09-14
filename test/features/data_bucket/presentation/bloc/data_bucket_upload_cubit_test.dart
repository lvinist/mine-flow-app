import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_upload_cubit.dart';

class MockGoogleDriveService extends Mock implements GoogleDriveService {}

class MockDataBucketRepository extends Mock implements DataBucketRepository {}

void main() {
  late MockGoogleDriveService driveService;
  late MockDataBucketRepository repository;

  setUpAll(() {
    registerFallbackValue(
      GeospatialFile(
        id: '',
        siteId: '',
        fileName: '',
        fileType: '',
        driveFileId: '',
        driveLink: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    driveService = MockGoogleDriveService();
    repository = MockDataBucketRepository();
  });

  group('DataBucketUploadCubit', () {
    blocTest<DataBucketUploadCubit, UploadState>(
      'starts in UploadIdle state',
      build: () => DataBucketUploadCubit(
        driveService: driveService,
        repository: repository,
        siteId: 'site-1',
      ),
      expect: () => [],
    );

    blocTest<DataBucketUploadCubit, UploadState>(
      'emits [UploadUploading, UploadSuccess] on successful upload',
      build: () {
        when(() => driveService.initialize()).thenAnswer((_) async => true);
        when(() => driveService.isOnline).thenAnswer((_) async => true);
        when(
          () => driveService.uploadFile(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeType: any(named: 'mimeType'),
            onProgress: any(named: 'onProgress'),
            isCancelled: any(named: 'isCancelled'),
          ),
        ).thenAnswer(
          (_) async => DriveFileResult(
            fileId: 'drive-123',
            name: 'test.shp',
            webViewLink: 'https://drive.google.com/file/d/123',
            sizeBytes: 1024,
            mimeType: 'application/x-esri-shapefile',
            createdTime: DateTime.now(),
          ),
        );
        when(() => repository.saveFile(any())).thenAnswer(
          (_) async => GeospatialFile(
            id: 'local-1',
            siteId: 'site-1',
            zoneId: 'Zona A',
            fileName: 'test.shp',
            fileType: '.shp',
            mimeType: 'application/x-esri-shapefile',
            driveFileId: 'drive-123',
            driveLink: 'https://drive.google.com/file/d/123',
            fileSizeBytes: 1024,
            acquisitionDate: DateTime(2026, 7, 15),
            notes: 'Test file',
            uploadedBy: 'Test User',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return DataBucketUploadCubit(
          driveService: driveService,
          repository: repository,
          siteId: 'site-1',
        );
      },
      act: (cubit) => cubit.uploadFile(
        bytes: [1, 2, 3],
        fileName: 'test.shp',
        mimeType: 'application/x-esri-shapefile',
        zoneId: 'Zona A',
        acquisitionDate: DateTime(2026, 7, 15),
        notes: 'Test file',
        uploadedBy: 'Test User',
      ),
      expect: () => [
        isA<UploadUploading>().having(
          (s) => s.fileName,
          'fileName',
          'test.shp',
        ),
        isA<UploadUploading>().having(
          (s) => s.fileName,
          'fileName',
          'test.shp',
        ),
        isA<UploadSuccess>().having(
          (s) => s.file.fileName,
          'fileName',
          'test.shp',
        ),
      ],
    );

    blocTest<DataBucketUploadCubit, UploadState>(
      'falls back to offline when Drive is unreachable',
      build: () {
        when(() => driveService.initialize()).thenAnswer((_) async => true);
        when(() => driveService.isOnline).thenAnswer((_) async => false);
        when(() => repository.saveFile(any())).thenAnswer(
          (_) async => GeospatialFile(
            id: 'local-offline-1',
            siteId: 'site-1',
            fileName: 'test.shp',
            fileType: '.shp',
            driveFileId: '',
            driveLink: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return DataBucketUploadCubit(
          driveService: driveService,
          repository: repository,
          siteId: 'site-1',
        );
      },
      act: (cubit) => cubit.uploadFile(
        bytes: [1, 2, 3],
        fileName: 'test.shp',
        mimeType: 'application/x-esri-shapefile',
      ),
      expect: () => [
        isA<UploadUploading>().having(
          (s) => s.fileName,
          'fileName',
          'test.shp',
        ),
        isA<UploadSuccess>(),
      ],
      verify: (_) {
        verify(() => repository.saveFile(any())).called(1);
        verifyNever(
          () => driveService.uploadFile(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeType: any(named: 'mimeType'),
          ),
        );
      },
    );

    blocTest<DataBucketUploadCubit, UploadState>(
      'emits UploadError on Drive upload exception',
      build: () {
        when(() => driveService.initialize()).thenAnswer((_) async => true);
        when(() => driveService.isOnline).thenAnswer((_) async => true);
        when(
          () => driveService.uploadFile(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeType: any(named: 'mimeType'),
            onProgress: any(named: 'onProgress'),
            isCancelled: any(named: 'isCancelled'),
          ),
        ).thenThrow(const DriveUploadException(message: 'Upload gagal'));
        return DataBucketUploadCubit(
          driveService: driveService,
          repository: repository,
          siteId: 'site-1',
        );
      },
      act: (cubit) => cubit.uploadFile(
        bytes: [1, 2, 3],
        fileName: 'test.shp',
        mimeType: 'application/x-esri-shapefile',
      ),
      expect: () => [isA<UploadUploading>(), const UploadError('Upload gagal')],
    );

    blocTest<DataBucketUploadCubit, UploadState>(
      'reset() returns to UploadIdle',
      build: () => DataBucketUploadCubit(
        driveService: driveService,
        repository: repository,
        siteId: 'site-1',
      ),
      act: (cubit) => cubit.reset(),
      expect: () => [const UploadIdle()],
    );

    blocTest<DataBucketUploadCubit, UploadState>(
      'cancel before partial transfer emits UploadCancelled',
      build: () {
        when(() => driveService.initialize()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return true;
        });
        return DataBucketUploadCubit(
          driveService: driveService,
          repository: repository,
          siteId: 'site-1',
        );
      },
      act: (cubit) async {
        final future = cubit.uploadFile(
          bytes: [1, 2, 3],
          fileName: 'cancel_before.shp',
          mimeType: 'application/x-esri-shapefile',
        );
        await cubit.cancelUpload();
        await future;
      },
      expect: () => [
        isA<UploadUploading>(),
        const UploadCancelled(fileName: 'cancel_before.shp'),
      ],
    );

    blocTest<DataBucketUploadCubit, UploadState>(
      'cancel during partial transfer aborts stream and emits UploadCancelled',
      build: () {
        when(() => driveService.initialize()).thenAnswer((_) async => true);
        when(() => driveService.isOnline).thenAnswer((_) async => true);
        when(
          () => driveService.uploadFile(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeType: any(named: 'mimeType'),
            onProgress: any(named: 'onProgress'),
            isCancelled: any(named: 'isCancelled'),
          ),
        ).thenAnswer((invocation) async {
          final onProgress =
              invocation.namedArguments[#onProgress]
                  as void Function(int, int)?;
          final isCancelled =
              invocation.namedArguments[#isCancelled] as bool Function()?;

          onProgress?.call(512, 1024);
          await Future.delayed(const Duration(milliseconds: 30));

          if (isCancelled?.call() == true) {
            throw const DriveUploadCancelledException();
          }
          return const DriveFileResult(
            fileId: 'not-cancelled',
            name: 'test.shp',
            webViewLink: '',
            sizeBytes: 1024,
            mimeType: 'application/x-esri-shapefile',
          );
        });
        return DataBucketUploadCubit(
          driveService: driveService,
          repository: repository,
          siteId: 'site-1',
        );
      },
      act: (cubit) async {
        final future = cubit.uploadFile(
          bytes: [1, 2, 3],
          fileName: 'cancel_during.shp',
          mimeType: 'application/x-esri-shapefile',
        );
        await Future.delayed(const Duration(milliseconds: 10));
        await cubit.cancelUpload();
        await future;
      },
      expect: () => [
        isA<UploadUploading>(),
        isA<UploadUploading>(),
        const UploadCancelled(fileName: 'cancel_during.shp'),
      ],
    );

    blocTest<DataBucketUploadCubit, UploadState>(
      'cancel after partial transfer cleans up Drive file and emits UploadCancelled',
      build: () {
        when(() => driveService.initialize()).thenAnswer((_) async => true);
        when(() => driveService.isOnline).thenAnswer((_) async => true);
        when(
          () => driveService.uploadFile(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeType: any(named: 'mimeType'),
            onProgress: any(named: 'onProgress'),
            isCancelled: any(named: 'isCancelled'),
          ),
        ).thenAnswer((_) async {
          return const DriveFileResult(
            fileId: 'partial-drive-id',
            name: 'cancel_after.shp',
            webViewLink: 'https://drive.google.com/file/d/partial',
            sizeBytes: 1024,
            mimeType: 'application/x-esri-shapefile',
          );
        });
        when(
          () => driveService.deleteFile('partial-drive-id'),
        ).thenAnswer((_) async => true);
        return DataBucketUploadCubit(
          driveService: driveService,
          repository: repository,
          siteId: 'site-1',
        );
      },
      act: (cubit) async {
        when(() => repository.saveFile(any())).thenAnswer((_) async {
          // Simulate user cancelling right before or during repository save
          await cubit.cancelUpload();
          return GeospatialFile(
            id: 'saved-id',
            siteId: 'site-1',
            fileName: 'cancel_after.shp',
            fileType: '.shp',
            driveFileId: 'partial-drive-id',
            driveLink: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });

        await cubit.uploadFile(
          bytes: [1, 2, 3],
          fileName: 'cancel_after.shp',
          mimeType: 'application/x-esri-shapefile',
        );
      },
      expect: () => [
        isA<UploadUploading>(),
        isA<UploadUploading>(),
        const UploadCancelled(
          fileName: 'cancel_after.shp',
          cleanupFailed: false,
        ),
      ],
      verify: (_) {
        verify(() => driveService.deleteFile('partial-drive-id')).called(1);
      },
    );

    blocTest<DataBucketUploadCubit, UploadState>(
      'cleanup failure truthfully reports failure in UploadCancelled',
      build: () {
        when(() => driveService.initialize()).thenAnswer((_) async => true);
        when(() => driveService.isOnline).thenAnswer((_) async => true);
        when(
          () => driveService.uploadFile(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeType: any(named: 'mimeType'),
            onProgress: any(named: 'onProgress'),
            isCancelled: any(named: 'isCancelled'),
          ),
        ).thenThrow(
          const DriveUploadCancelledException(
            driveFileId: 'drive-cleanup-fail-id',
          ),
        );
        when(
          () => driveService.deleteFile('drive-cleanup-fail-id'),
        ).thenThrow(Exception('Drive network error during deletion'));
        return DataBucketUploadCubit(
          driveService: driveService,
          repository: repository,
          siteId: 'site-1',
        );
      },
      act: (cubit) => cubit.uploadFile(
        bytes: [1, 2, 3],
        fileName: 'cleanup_fail.shp',
        mimeType: 'application/x-esri-shapefile',
      ),
      expect: () => [
        isA<UploadUploading>(),
        const UploadCancelled(
          fileName: 'cleanup_fail.shp',
          cleanupFailed: true,
          cleanupError: 'Exception: Drive network error during deletion',
        ),
      ],
    );

    test('ignores double submit when already uploading', () async {
      when(() => driveService.initialize()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return true;
      });
      when(() => driveService.isOnline).thenAnswer((_) async => true);
      when(
        () => driveService.uploadFile(
          bytes: any(named: 'bytes'),
          fileName: any(named: 'fileName'),
          mimeType: any(named: 'mimeType'),
          onProgress: any(named: 'onProgress'),
          isCancelled: any(named: 'isCancelled'),
        ),
      ).thenAnswer(
        (_) async => DriveFileResult(
          fileId: 'drive-first',
          name: 'first.shp',
          webViewLink: 'https://drive.google.com/first',
          sizeBytes: 3,
          mimeType: 'application/x-esri-shapefile',
          createdTime: DateTime.now(),
        ),
      );
      when(() => repository.saveFile(any())).thenAnswer(
        (_) async => GeospatialFile(
          id: 'file-first',
          siteId: 'site-1',
          fileName: 'first.shp',
          fileType: '.shp',
          driveFileId: 'drive-first',
          driveLink: 'https://drive.google.com/first',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final cubit = DataBucketUploadCubit(
        driveService: driveService,
        repository: repository,
        siteId: 'site-1',
      );

      final first = cubit.uploadFile(
        bytes: [1, 2, 3],
        fileName: 'first.shp',
        mimeType: 'application/x-esri-shapefile',
      );

      // Try second upload while first is in progress
      final second = cubit.uploadFile(
        bytes: [4, 5, 6],
        fileName: 'second.shp',
        mimeType: 'application/x-esri-shapefile',
      );

      await Future.wait([first, second]);
      expect(
        cubit.state,
        isA<UploadSuccess>().having(
          (s) => s.file.fileName,
          'fileName',
          'first.shp',
        ),
      );
      verify(
        () => driveService.uploadFile(
          bytes: any(named: 'bytes'),
          fileName: 'first.shp',
          mimeType: any(named: 'mimeType'),
          onProgress: any(named: 'onProgress'),
          isCancelled: any(named: 'isCancelled'),
        ),
      ).called(1);
      verifyNever(
        () => driveService.uploadFile(
          bytes: any(named: 'bytes'),
          fileName: 'second.shp',
          mimeType: any(named: 'mimeType'),
          onProgress: any(named: 'onProgress'),
          isCancelled: any(named: 'isCancelled'),
        ),
      );
    });

    test(
      'cancelUpload called while files.create in flight cleans up Drive file when exception returns driveFileId',
      () async {
        when(() => driveService.initialize()).thenAnswer((_) async => true);
        when(() => driveService.isOnline).thenAnswer((_) async => true);
        when(
          () => driveService.deleteFile('orphan-id-123'),
        ).thenAnswer((_) async => true);

        when(
          () => driveService.uploadFile(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeType: any(named: 'mimeType'),
            onProgress: any(named: 'onProgress'),
            isCancelled: any(named: 'isCancelled'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 30));
          throw const DriveUploadCancelledException(
            driveFileId: 'orphan-id-123',
          );
        });

        final cubit = DataBucketUploadCubit(
          driveService: driveService,
          repository: repository,
          siteId: 'site-1',
        );

        final uploadFuture = cubit.uploadFile(
          bytes: [1, 2, 3],
          fileName: 'race_test.shp',
          mimeType: 'application/x-esri-shapefile',
        );

        await Future.delayed(const Duration(milliseconds: 10));
        // cancelUpload called while upload is in flight:
        await cubit.cancelUpload();
        await uploadFuture;

        expect(
          cubit.state,
          isA<UploadCancelled>().having(
            (s) => s.cleanupFailed,
            'cleanupFailed',
            false,
          ),
        );
        verify(() => driveService.deleteFile('orphan-id-123')).called(1);
      },
    );

    test(
      'cancellation after saveFile cleans up both Drive file and repository record',
      () async {
        when(() => driveService.initialize()).thenAnswer((_) async => true);
        when(() => driveService.isOnline).thenAnswer((_) async => true);
        when(
          () => driveService.deleteFile('drive-to-delete'),
        ).thenAnswer((_) async => true);
        when(
          () => repository.deleteFile('repo-to-delete'),
        ).thenAnswer((_) async {});

        when(
          () => driveService.uploadFile(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeType: any(named: 'mimeType'),
            onProgress: any(named: 'onProgress'),
            isCancelled: any(named: 'isCancelled'),
          ),
        ).thenAnswer(
          (_) async => DriveFileResult(
            fileId: 'drive-to-delete',
            name: 'save_cancel.shp',
            webViewLink: 'https://drive.google.com/save_cancel',
            sizeBytes: 3,
            mimeType: 'application/x-esri-shapefile',
            createdTime: DateTime.now(),
          ),
        );

        final cubit = DataBucketUploadCubit(
          driveService: driveService,
          repository: repository,
          siteId: 'site-1',
        );

        when(() => repository.saveFile(any())).thenAnswer((_) async {
          // User cancels while repository.saveFile is executing
          await cubit.cancelUpload();
          return GeospatialFile(
            id: 'repo-to-delete',
            siteId: 'site-1',
            fileName: 'save_cancel.shp',
            fileType: '.shp',
            driveFileId: 'drive-to-delete',
            driveLink: 'https://drive.google.com/save_cancel',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });

        await cubit.uploadFile(
          bytes: [1, 2, 3],
          fileName: 'save_cancel.shp',
          mimeType: 'application/x-esri-shapefile',
        );

        expect(cubit.state, isA<UploadCancelled>());
        verify(() => driveService.deleteFile('drive-to-delete')).called(1);
        verify(() => repository.deleteFile('repo-to-delete')).called(1);
      },
    );
  });
}
