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
  });
}
