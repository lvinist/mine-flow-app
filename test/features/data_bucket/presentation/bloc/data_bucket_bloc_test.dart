import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_bloc.dart';

class MockDataBucketRepository extends Mock implements DataBucketRepository {}

void main() {
  late MockDataBucketRepository repository;
  late List<GeospatialFile> testFiles;

  setUp(() {
    repository = MockDataBucketRepository();
    testFiles = [
      GeospatialFile(
        id: '1',
        siteId: 'site-1',
        zoneId: 'Zona A',
        fileName: 'survey.shp',
        fileType: '.shp',
        mimeType: 'application/x-esri-shapefile',
        driveFileId: 'drive-1',
        driveLink: 'https://drive.google.com/file/d/1',
        fileSizeBytes: 1024,
        latitude: -7.123,
        longitude: 112.345,
        acquisitionDate: DateTime(2026, 7, 15),
        notes: 'Survey data',
        uploadedBy: 'Supervisor',
        createdAt: DateTime(2026, 7, 15),
        updatedAt: DateTime(2026, 7, 15),
      ),
      GeospatialFile(
        id: '2',
        siteId: 'site-1',
        zoneId: 'Zona B',
        fileName: 'topography.tiff',
        fileType: '.tiff',
        mimeType: 'image/tiff',
        driveFileId: 'drive-2',
        driveLink: 'https://drive.google.com/file/d/2',
        fileSizeBytes: 2048,
        acquisitionDate: DateTime(2026, 7, 10),
        uploadedBy: 'Surveyor',
        createdAt: DateTime(2026, 7, 10),
        updatedAt: DateTime(2026, 7, 10),
      ),
    ];
  });

  group('DataBucketBloc', () {
    blocTest<DataBucketBloc, DataBucketState>(
      'emits [DataBucketLoading, DataBucketLoaded] when LoadFiles succeeds',
      build: () {
        when(
          () => repository.getFiles(siteId: any(named: 'siteId')),
        ).thenAnswer((_) async => testFiles);
        return DataBucketBloc(repository: repository, siteId: 'site-1');
      },
      act: (bloc) => bloc.add(const LoadFiles()),
      expect: () => [
        const DataBucketLoading(),
        DataBucketLoaded(files: testFiles),
      ],
    );

    blocTest<DataBucketBloc, DataBucketState>(
      'emits [DataBucketLoading, DataBucketError] when LoadFiles fails',
      build: () {
        when(
          () => repository.getFiles(siteId: any(named: 'siteId')),
        ).thenThrow(Exception('Network error'));
        return DataBucketBloc(repository: repository, siteId: 'site-1');
      },
      act: (bloc) => bloc.add(const LoadFiles()),
      expect: () => [
        const DataBucketLoading(),
        const DataBucketError(
          'Gagal memuat daftar file: Exception: Network error',
        ),
      ],
    );

    blocTest<DataBucketBloc, DataBucketState>(
      'filters files by search query',
      build: () {
        when(
          () => repository.getFiles(siteId: any(named: 'siteId')),
        ).thenAnswer((_) async => testFiles);
        return DataBucketBloc(repository: repository, siteId: 'site-1');
      },
      seed: () => DataBucketLoaded(files: testFiles),
      act: (bloc) => bloc.add(const SearchFiles('topography')),
      expect: () => [
        DataBucketLoaded(files: testFiles, searchQuery: 'topography'),
      ],
    );

    blocTest<DataBucketBloc, DataBucketState>(
      'filters files by zone',
      build: () {
        when(
          () => repository.getFiles(siteId: any(named: 'siteId')),
        ).thenAnswer((_) async => testFiles);
        return DataBucketBloc(repository: repository, siteId: 'site-1');
      },
      seed: () => DataBucketLoaded(files: testFiles),
      act: (bloc) => bloc.add(const FilterByZone('Zona A')),
      expect: () => [
        DataBucketLoaded(files: testFiles, filterZoneId: 'Zona A'),
      ],
    );

    blocTest<DataBucketBloc, DataBucketState>(
      'filters files by file type',
      build: () {
        when(
          () => repository.getFiles(siteId: any(named: 'siteId')),
        ).thenAnswer((_) async => testFiles);
        return DataBucketBloc(repository: repository, siteId: 'site-1');
      },
      seed: () => DataBucketLoaded(files: testFiles),
      act: (bloc) => bloc.add(const FilterByType('.shp')),
      expect: () => [
        DataBucketLoaded(files: testFiles, filterFileType: '.shp'),
      ],
    );

    blocTest<DataBucketBloc, DataBucketState>(
      'handles DeleteFile and removes the file from list',
      build: () {
        when(() => repository.deleteFile(any())).thenAnswer((_) async {});
        when(
          () => repository.getFiles(siteId: any(named: 'siteId')),
        ).thenAnswer((_) async => testFiles);
        return DataBucketBloc(repository: repository, siteId: 'site-1');
      },
      seed: () => DataBucketLoaded(files: testFiles),
      act: (bloc) => bloc.add(const DeleteFile('1')),
      expect: () => [
        DataBucketLoaded(files: [testFiles[1]]),
      ],
    );

    blocTest<DataBucketBloc, DataBucketState>(
      'handles RefreshFiles and re-fetches from repository',
      build: () {
        when(
          () => repository.getFiles(siteId: any(named: 'siteId')),
        ).thenAnswer((_) async => testFiles);
        return DataBucketBloc(repository: repository, siteId: 'site-1');
      },
      act: (bloc) => bloc.add(const RefreshFiles()),
      expect: () => [
        const DataBucketLoading(),
        DataBucketLoaded(files: testFiles),
      ],
    );

    group('filteredFiles getter', () {
      test('returns all files when no filters are active', () {
        final state = DataBucketLoaded(files: testFiles);
        expect(state.filteredFiles, testFiles);
      });

      test('filters by search query', () {
        final state = DataBucketLoaded(
          files: testFiles,
          searchQuery: 'topography',
        );
        expect(state.filteredFiles.length, 1);
        expect(state.filteredFiles.first.id, '2');
      });

      test('filters by zone', () {
        final state = DataBucketLoaded(
          files: testFiles,
          filterZoneId: 'Zona A',
        );
        expect(state.filteredFiles.length, 1);
        expect(state.filteredFiles.first.id, '1');
      });

      test('filters by file type', () {
        final state = DataBucketLoaded(
          files: testFiles,
          filterFileType: '.tiff',
        );
        expect(state.filteredFiles.length, 1);
        expect(state.filteredFiles.first.id, '2');
      });

      test('combines search and zone filter', () {
        final state = DataBucketLoaded(
          files: testFiles,
          searchQuery: 'survey',
          filterZoneId: 'Zona A',
        );
        expect(state.filteredFiles.length, 1);
        expect(state.filteredFiles.first.id, '1');
      });

      test('returns empty when no files match', () {
        final state = DataBucketLoaded(
          files: testFiles,
          searchQuery: 'nonexistent',
        );
        expect(state.filteredFiles, isEmpty);
      });
    });
  });
}
