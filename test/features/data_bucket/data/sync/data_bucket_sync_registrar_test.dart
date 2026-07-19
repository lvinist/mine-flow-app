import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/data_bucket/data/sync/data_bucket_sync_registrar.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockDataBucketRepository extends Mock implements DataBucketRepository {}

/// Fake [GeospatialFile] used by mocktail for fallback value registration.
/// Without this, `any()` on `GeospatialFile` parameters throws.
class FakeGeospatialFile extends Fake implements GeospatialFile {}

void main() {
  late MockSyncQueueManager mockSyncQueueManager;
  late MockDataBucketRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeGeospatialFile());
  });

  setUp(() {
    mockSyncQueueManager = MockSyncQueueManager();
    mockRepository = MockDataBucketRepository();
  });

  group('DataBucketSyncRegistrar', () {
    test('registerSyncHandlers should register the data_bucket handler', () {
      DataBucketSyncRegistrar.registerSyncHandlers(
        mockSyncQueueManager,
        mockRepository,
      );

      verify(
        () => mockSyncQueueManager.registerEntityHandler(
          'data_bucket_metadata_sync',
          any(),
        ),
      ).called(1);
    });

    test(
      'unregisterSyncHandlers should unregister the data_bucket handler',
      () {
        DataBucketSyncRegistrar.unregisterSyncHandlers(mockSyncQueueManager);

        verify(
          () => mockSyncQueueManager.unregisterEntityHandler(
            'data_bucket_metadata_sync',
          ),
        ).called(1);
      },
    );
  });

  group('DataBucketSyncRegistrar handler execution', () {
    test('should process update action via repository.saveFile', () async {
      // Capture the registered handler
      RemoteSyncHandler? capturedHandler;
      when(
        () => mockSyncQueueManager.registerEntityHandler(any(), any()),
      ).thenAnswer((invocation) {
        capturedHandler =
            invocation.positionalArguments[1] as RemoteSyncHandler;
      });

      DataBucketSyncRegistrar.registerSyncHandlers(
        mockSyncQueueManager,
        mockRepository,
      );

      // Ensure handler was captured
      expect(capturedHandler, isNotNull);

      // Arrange a SyncQueueItem with a valid payload
      const testId = 'test-file-id';
      final item = SyncQueueItem(
        id: 'queue-item-1',
        entityType: 'data_bucket_metadata_sync',
        action: SyncAction.update,
        payloadJson: <String, dynamic>{
          'id': testId,
          'site_id': '00000000-0000-0000-0000-000000000001',
          'file_name': 'test.shp',
          'file_type': '.shp',
          'drive_file_id': 'drive-abc',
          'drive_link': 'https://drive.google.com/file/d/abc/view',
          'created_at': '2026-07-18T08:00:00.000',
          'updated_at': '2026-07-18T08:00:00.000',
        },
        timestamp: DateTime(2026, 7, 18, 8, 0, 0),
      );

      when(() => mockRepository.saveFile(any())).thenAnswer(
        (_) async => GeospatialFile(
          id: testId,
          siteId: '00000000-0000-0000-0000-000000000001',
          fileName: 'test.shp',
          fileType: '.shp',
          driveFileId: 'drive-abc',
          driveLink: 'https://drive.google.com/file/d/abc/view',
          createdAt: DateTime(2026, 7, 18),
          updatedAt: DateTime(2026, 7, 18),
        ),
      );

      // Act
      await capturedHandler!(item);

      // Assert
      verify(() => mockRepository.saveFile(any())).called(1);
    });

    test(
      'should process create action same as update via repository.saveFile',
      () async {
        RemoteSyncHandler? capturedHandler;
        when(
          () => mockSyncQueueManager.registerEntityHandler(any(), any()),
        ).thenAnswer((invocation) {
          capturedHandler =
              invocation.positionalArguments[1] as RemoteSyncHandler;
        });

        DataBucketSyncRegistrar.registerSyncHandlers(
          mockSyncQueueManager,
          mockRepository,
        );

        expect(capturedHandler, isNotNull);

        final item = SyncQueueItem(
          id: 'queue-item-2',
          entityType: 'data_bucket_metadata_sync',
          action: SyncAction.create,
          payloadJson: <String, dynamic>{
            'id': 'new-file-id',
            'site_id': '00000000-0000-0000-0000-000000000001',
            'file_name': 'new_file.tiff',
            'file_type': '.tiff',
            'drive_file_id': 'drive-new',
            'drive_link': 'https://drive.google.com/file/d/new/view',
            'created_at': '2026-07-18T10:00:00.000',
            'updated_at': '2026-07-18T10:00:00.000',
          },
          timestamp: DateTime(2026, 7, 18, 10, 0, 0),
        );

        when(() => mockRepository.saveFile(any())).thenAnswer(
          (_) async => GeospatialFile(
            id: 'new-file-id',
            siteId: '00000000-0000-0000-0000-000000000001',
            fileName: 'new_file.tiff',
            fileType: '.tiff',
            driveFileId: 'drive-new',
            driveLink: 'https://drive.google.com/file/d/new/view',
            createdAt: DateTime(2026, 7, 18),
            updatedAt: DateTime(2026, 7, 18),
          ),
        );

        await capturedHandler!(item);

        verify(() => mockRepository.saveFile(any())).called(1);
      },
    );

    test('should process delete action via repository.deleteFile', () async {
      RemoteSyncHandler? capturedHandler;
      when(
        () => mockSyncQueueManager.registerEntityHandler(any(), any()),
      ).thenAnswer((invocation) {
        capturedHandler =
            invocation.positionalArguments[1] as RemoteSyncHandler;
      });

      DataBucketSyncRegistrar.registerSyncHandlers(
        mockSyncQueueManager,
        mockRepository,
      );

      expect(capturedHandler, isNotNull);

      final item = SyncQueueItem(
        id: 'queue-item-3',
        entityType: 'data_bucket_metadata_sync',
        action: SyncAction.delete,
        payloadJson: <String, dynamic>{'id': 'file-to-delete'},
        timestamp: DateTime(2026, 7, 18, 12, 0, 0),
      );

      when(() => mockRepository.deleteFile(any())).thenAnswer((_) async {});

      await capturedHandler!(item);

      verify(() => mockRepository.deleteFile('file-to-delete')).called(1);
    });
  });
}
