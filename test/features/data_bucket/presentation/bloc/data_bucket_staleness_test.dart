// R-4 regression coverage: rows that arrive AFTER the list mounts must render.
//
// STEP-48.26: the data-bucket journey's Part B asserted
// "site-scoped rows exist → file cards must render" and found 0 `FileCard`s
// while staging held the re-sited seed row. Cause: `DataBucketBloc` loaded once
// from the local Hive cache and had no subscription to the repository, while
// `getFiles` refreshes the cache via an `unawaited` background call. Anything the
// refresh brought in was invisible until a manual `RefreshFiles`.
//
// At baseline both sides were empty, so the journey's if/else passed for the
// wrong reason — 48.20's fixture fix is what made the defect visible. These tests
// pin the fix at both layers:
//   * the repository's `watchFiles` emits from the LOCAL cache (so it covers the
//     background refresh and the offline path), seeded with the current contents;
//   * the bloc folds those emissions into `DataBucketLoaded` without dropping the
//     active search/filter selections.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/data_bucket/data/datasources/data_bucket_local_datasource.dart';
import 'package:mine_flow/features/data_bucket/data/datasources/data_bucket_remote_datasource.dart';
import 'package:mine_flow/features/data_bucket/data/models/geospatial_file_model.dart';
import 'package:mine_flow/features/data_bucket/data/repositories/data_bucket_repository_impl.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_bloc.dart';

class _StubNetworkInfo implements NetworkInfo {
  bool isOnline = true;

  @override
  Future<bool> get isConnected async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

/// Remote source whose row set the test controls, standing in for staging.
class _StubRemoteDataSource implements DataBucketRemoteDataSource {
  final List<GeospatialFileModel> db = [];

  @override
  Future<List<GeospatialFileModel>> fetchFiles() async => List.from(db);

  @override
  Future<GeospatialFileModel> saveFile(GeospatialFileModel file) async {
    db.removeWhere((r) => r.id == file.id);
    db.add(file);
    return file;
  }

  @override
  Future<void> deleteFile(String id) async => db.removeWhere((r) => r.id == id);

  @override
  Stream<List<GeospatialFileModel>> watchFiles() => Stream.value(List.from(db));
}

void main() {
  const siteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  final fixedDate = DateTime(2026, 9);

  late Directory tempDir;
  late Box<Map> localBox;
  late Box<SyncQueueItem> queueBox;
  late _StubNetworkInfo network;
  late _StubRemoteDataSource remote;
  late DataBucketLocalDataSource local;
  late DataBucketRepositoryImpl repository;

  GeospatialFileModel model(String id, {String site = siteId}) =>
      GeospatialFileModel(
        id: id,
        siteId: site,
        zoneId: 'zone-north',
        fileName: '$id.shp',
        fileType: '.shp',
        driveFileId: 'drive-$id',
        driveLink: 'https://drive.google.com/file/d/$id/view',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('data_bucket_stale_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SyncActionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    localBox = await Hive.openBox<Map>('stale_db_$stamp');
    queueBox = await Hive.openBox<SyncQueueItem>('stale_q_$stamp');

    network = _StubNetworkInfo();
    remote = _StubRemoteDataSource();
    local = DataBucketLocalDataSourceImpl(hiveBox: localBox);
    repository = DataBucketRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      syncQueueManager: SyncQueueManager(
        queueRepository: HiveCacheRepository(queueBox),
        networkInfo: network,
      ),
      networkInfo: network,
    );
  });

  tearDown(() async {
    await localBox.clear();
    await localBox.close();
    await queueBox.clear();
    await queueBox.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('DataBucketRepositoryImpl.watchFiles (R-4)', () {
    test('emits the current cache immediately, then every change', () async {
      await local.saveFile(model('gf-001'));

      final emissions = <List<GeospatialFile>>[];
      final subscription = repository
          .watchFiles(siteId: siteId)
          .listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      expect(emissions.single.map((f) => f.id), [
        'gf-001',
      ], reason: 'a subscriber must not start blank');

      // Simulates the background refresh writing a row that arrived from
      // staging after the page mounted.
      await local.saveFileBatch([model('gf-002')]);
      await Future<void>.delayed(Duration.zero);

      expect(emissions.length, greaterThan(1));
      expect(emissions.last.map((f) => f.id).toSet(), {'gf-001', 'gf-002'});

      await subscription.cancel();
    });

    test('applies the site filter to streamed rows', () async {
      final emissions = <List<GeospatialFile>>[];
      final subscription = repository
          .watchFiles(siteId: siteId)
          .listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      await local.saveFile(model('gf-mine'));
      await local.saveFile(model('gf-other', site: 'another-site'));
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.map((f) => f.id), ['gf-mine']);

      await subscription.cancel();
    });
  });

  group('DataBucketBloc staleness (R-4)', () {
    test(
      'renders rows the background refresh brings in after LoadFiles',
      () async {
        // Cache empty, staging holds the (re-sited) seed row — exactly the state
        // 48.20 produced and the journey then failed on.
        remote.db.add(model('gf-seed'));

        final bloc = DataBucketBloc(repository: repository, siteId: siteId);
        addTearDown(bloc.close);

        bloc.add(const LoadFiles(siteId: siteId));

        final loaded = await bloc.stream.firstWhere(
          (s) => s is DataBucketLoaded && s.files.isNotEmpty,
        );

        expect(
          (loaded as DataBucketLoaded).files.map((f) => f.id),
          ['gf-seed'],
          reason:
              'the row arrived via the unawaited refresh; without a repository '
              'subscription the list would stay empty (R-4)',
        );
      },
    );

    test('a cache update preserves the active search filter', () async {
      await local.saveFile(model('alpha'));

      final bloc = DataBucketBloc(repository: repository, siteId: siteId);
      addTearDown(bloc.close);

      // bloc.stream is a broadcast stream, so subscribe BEFORE mutating the
      // cache — a listener attached afterwards misses the emission.
      final states = <DataBucketState>[];
      final subscription = bloc.stream.listen(states.add);
      addTearDown(subscription.cancel);

      bloc.add(const LoadFiles(siteId: siteId));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      bloc.add(const SearchFiles('beta'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await local.saveFile(model('beta'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final updated = states.whereType<DataBucketLoaded>().last;
      expect(updated.files.length, 2);
      expect(updated.searchQuery, 'beta');
      expect(updated.filteredFiles.map((f) => f.id), [
        'beta',
      ], reason: 'a streamed update must not clear the user\'s search');
    });
  });
}
