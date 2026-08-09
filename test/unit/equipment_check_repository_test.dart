import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/equipment_check/data/adapters/equipment_check_dto_adapter.dart';
import 'package:mine_flow/features/equipment_check/data/datasources/equipment_check_remote_datasource.dart';
import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';
import 'package:mine_flow/features/equipment_check/data/repositories/equipment_check_repository_impl.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

class MockNetworkInfo implements NetworkInfo {
  bool isOnline = false;

  @override
  Future<bool> get isConnected async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

class MockEquipmentCheckRemoteDataSource
    implements EquipmentCheckRemoteDataSource {
  final List<EquipmentCheckDto> mockRemoteData = [];

  @override
  Future<List<EquipmentCheckDto>> fetchAllEquipmentChecks() async {
    return mockRemoteData;
  }

  @override
  Future<EquipmentCheckDto?> fetchEquipmentCheckById(String id) async {
    final match = mockRemoteData.where((d) => d.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> upsertEquipmentCheck(EquipmentCheckDto dto) async {
    mockRemoteData.removeWhere((d) => d.id == dto.id);
    mockRemoteData.add(dto);
  }

  @override
  Future<void> deleteEquipmentCheck(String id) async {
    mockRemoteData.removeWhere((d) => d.id == id);
  }
}

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';
  late Box<EquipmentCheckDto> equipmentBox;
  late Box<SyncQueueItem> queueBox;
  late HiveCacheRepository<EquipmentCheckDto> localCache;
  late HiveCacheRepository<SyncQueueItem> queueRepo;
  late MockNetworkInfo mockNetworkInfo;
  late SyncQueueManager syncQueueManager;
  late MockEquipmentCheckRemoteDataSource mockRemoteDataSource;
  late EquipmentCheckRepositoryImpl repository;

  setUpAll(() async {
    Hive.init('./test_hive_equipment_check');
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SyncActionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(EquipmentCheckDtoAdapter());
    }
  });

  setUp(() async {
    equipmentBox = await Hive.openBox<EquipmentCheckDto>(
      'test_equipment_box_${DateTime.now().millisecondsSinceEpoch}',
    );
    queueBox = await Hive.openBox<SyncQueueItem>(
      'test_eq_queue_box_${DateTime.now().millisecondsSinceEpoch}',
    );

    localCache = HiveCacheRepository(equipmentBox);
    queueRepo = HiveCacheRepository(queueBox);
    mockNetworkInfo = MockNetworkInfo();
    syncQueueManager = SyncQueueManager(
      queueRepository: queueRepo,
      networkInfo: mockNetworkInfo,
    );
    mockRemoteDataSource = MockEquipmentCheckRemoteDataSource();

    repository = EquipmentCheckRepositoryImpl(
      localCache: localCache,
      syncQueueManager: syncQueueManager,
      networkInfo: mockNetworkInfo,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  tearDown(() async {
    await equipmentBox.clear();
    await equipmentBox.close();
    await queueBox.clear();
    await queueBox.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('EquipmentCheckRepositoryImpl - Offline First Operations', () {
    final tCheck1 = EquipmentCheck(
      id: 'eq-001',
      siteId: defaultSiteId,
      foremanId: 'foreman-001',
      equipmentType: EquipmentType.gnss,
      serialNumber: 'GNSS-100',
      checkTime: DateTime(2026, 7, 18, 8, 0),
      checkType: CheckType.preWork,
      status: CheckStatus.passed,
      isOperational: true,
      checklist: const [
        CheckItem(id: 'battery_ok', label: 'Battery Level OK', isPassed: true),
      ],
      remarks: 'All good',
    );

    final tCheck2 = EquipmentCheck(
      id: 'eq-002',
      siteId: defaultSiteId,
      foremanId: 'foreman-001',
      equipmentType: EquipmentType.drone,
      serialNumber: 'DRONE-200',
      checkTime: DateTime(2026, 7, 18, 9, 0),
      checkType: CheckType.preWork,
      status: CheckStatus.failed,
      isOperational: false,
      checklist: const [
        CheckItem(
          id: 'prop_damaged',
          label: 'Propeller Check',
          isPassed: false,
        ),
      ],
      remarks: 'Damaged propeller blade',
    );

    test(
      'saveEquipmentCheck should write to local cache and enqueue sync mutation item',
      () async {
        await repository.saveEquipmentCheck(tCheck1);

        // Verify cached in Hive
        final cached = localCache.get('eq-001');
        expect(cached, isNotNull);
        expect(cached!.equipmentType, equals('gnss'));
        expect(cached.status, equals('passed'));
        expect(cached.isOperational, isTrue);

        // Verify enqueued in SyncQueueManager
        final pendingQueue = queueRepo.getAll();
        expect(pendingQueue.length, equals(1));
        expect(pendingQueue.first.entityType, equals('equipment_checks'));
        expect(pendingQueue.first.action, equals(SyncAction.update));
        expect(pendingQueue.first.payloadJson['id'], equals('eq-001'));
      },
    );

    test(
      'saveEquipmentCheckBatch should save multiple checks to local cache',
      () async {
        await repository.saveEquipmentCheckBatch([tCheck1, tCheck2]);

        final allCached = localCache.getAll();
        expect(allCached.length, equals(2));

        final pendingQueue = queueRepo.getAll();
        expect(pendingQueue.length, equals(2));
      },
    );

    test(
      'getEquipmentChecks should filter local cache by equipmentType and siteId',
      () async {
        await repository.saveEquipmentCheckBatch([tCheck1, tCheck2]);

        final gnssChecks = await repository.getEquipmentChecks(
          equipmentType: EquipmentType.gnss,
          siteId: defaultSiteId,
        );
        expect(gnssChecks.length, equals(1));
        expect(gnssChecks.first.id, equals('eq-001'));

        final droneChecks = await repository.getEquipmentChecks(
          equipmentType: EquipmentType.drone,
        );
        expect(droneChecks.length, equals(1));
        expect(droneChecks.first.id, equals('eq-002'));
      },
    );

    test(
      'getEquipmentCheckById should return specific equipment check',
      () async {
        await repository.saveEquipmentCheck(tCheck1);

        final check = await repository.getEquipmentCheckById('eq-001');
        expect(check, isNotNull);
        expect(check!.id, equals('eq-001'));
        expect(check.serialNumber, equals('GNSS-100'));
      },
    );

    test(
      'deleteEquipmentCheck should mark soft delete in local cache and enqueue delete mutation',
      () async {
        await repository.saveEquipmentCheck(tCheck1);
        await repository.deleteEquipmentCheck('eq-001');

        final cachedAfterDelete = localCache.get('eq-001');
        expect(cachedAfterDelete?.deletedAt, isNotNull);

        final activeChecks = await repository.getEquipmentChecks();
        expect(activeChecks.isEmpty, isTrue);

        final queueItems = queueRepo.getAll();
        final hasDeleteMutation = queueItems.any(
          (item) => item.action == SyncAction.delete,
        );
        expect(hasDeleteMutation, isTrue);
      },
    );

    test(
      'syncRemote should fetch remote records and update local cache when online',
      () async {
        mockNetworkInfo.isOnline = true;
        mockRemoteDataSource.mockRemoteData.add(
          EquipmentCheckDto(
            id: 'remote-eq-001',
            siteId: defaultSiteId,
            foremanId: 'foreman-009',
            equipmentType: 'total_station',
            checkTime: DateTime(2026, 7, 18, 10, 0),
            checkType: 'pre_work',
            status: 'passed',
          ),
        );

        final syncedChecks = await repository.syncRemote();
        expect(syncedChecks.length, equals(1));
        expect(syncedChecks.first.id, equals('remote-eq-001'));
        expect(
          syncedChecks.first.equipmentType,
          equals(EquipmentType.totalStation),
        );

        final cachedItem = localCache.get('remote-eq-001');
        expect(cachedItem, isNotNull);
      },
    );
  });
}
