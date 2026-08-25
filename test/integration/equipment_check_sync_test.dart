import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/equipment_check/data/adapters/equipment_check_dto_adapter.dart';
import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';
import 'package:mine_flow/features/equipment_check/data/repositories/equipment_check_repository_impl.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Fake implementation of [NetworkInfo] for testing offline/online transitions.
class FakeNetworkInfo implements NetworkInfo {
  bool _isConnected = false;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  void setConnected(bool value) {
    _isConnected = value;
    _controller.add(value);
  }

  @override
  Future<bool> get isConnected async => _isConnected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

void main() {
  late Directory tempDir;
  late FakeNetworkInfo fakeNetworkInfo;
  late Box<EquipmentCheckDto> equipmentBox;
  late Box<SyncQueueItem> queueBox;
  late HiveCacheRepository<EquipmentCheckDto> equipmentCache;
  late HiveCacheRepository<SyncQueueItem> queueRepo;
  late SyncQueueManager syncQueueManager;
  late EquipmentCheckRepositoryImpl equipmentCheckRepository;

  setUpAll(() {
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
    tempDir = await Directory.systemTemp.createTemp(
      'equipment_check_sync_test_',
    );
    Hive.init(tempDir.path);

    equipmentBox = await Hive.openBox<EquipmentCheckDto>(
      'test_equipment_check_box',
    );
    queueBox = await Hive.openBox<SyncQueueItem>('test_sync_queue_box');

    equipmentCache = HiveCacheRepository(equipmentBox);
    queueRepo = HiveCacheRepository(queueBox);

    fakeNetworkInfo = FakeNetworkInfo();
  });

  tearDown(() async {
    await syncQueueManager.dispose();
    fakeNetworkInfo.dispose();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Equipment Check Offline Sync Integration Tests', () {
    test(
      'Equipment check offline creation enqueues mutation and flushes when online',
      () async {
        fakeNetworkInfo.setConnected(false);

        final syncedPayloads = <Map<String, dynamic>>[];

        syncQueueManager = SyncQueueManager(
          queueRepository: queueRepo,
          networkInfo: fakeNetworkInfo,
        );

        // 1. Register entity handler for equipment_checks
        syncQueueManager.registerEntityHandler('equipment_checks', (
          item,
        ) async {
          syncedPayloads.add(item.payloadJson);
        });

        equipmentCheckRepository = EquipmentCheckRepositoryImpl(
          localCache: equipmentCache,
          syncQueueManager: syncQueueManager,
          networkInfo: fakeNetworkInfo,
        );

        final check = EquipmentCheck(
          id: 'eq-sync-101',
          siteId: '00000000-0000-0000-0000-000000000001',
          foremanId: 'foreman-bob',
          equipmentType: EquipmentType.gnss,
          serialNumber: 'SN-GNSS-999',
          checkTime: DateTime.parse('2026-07-18T08:00:00.000Z'),
          checkType: CheckType.preWork,
          status: CheckStatus.passed,
          isOperational: true,
          checklist: const [
            CheckItem(id: 'c1', label: 'Battery charged', isPassed: true),
            CheckItem(id: 'c2', label: 'Satellite lock', isPassed: true),
          ],
          remarks: 'All GNSS components functional',
          createdAt: DateTime.parse('2026-07-18T08:00:00.000Z'),
          updatedAt: DateTime.parse('2026-07-18T08:00:00.000Z'),
        );

        // Save while offline
        await equipmentCheckRepository.saveEquipmentCheck(check);

        // 2. Verify cached in local Hive storage
        final localCheck = await equipmentCheckRepository.getEquipmentCheckById(
          'eq-sync-101',
        );
        expect(localCheck, isNotNull);
        expect(localCheck!.serialNumber, equals('SN-GNSS-999'));
        expect(localCheck.status, equals(CheckStatus.passed));

        // 3. Verify enqueued in SyncQueueManager as pending
        final pendingItems = syncQueueManager.getPendingItems();
        expect(pendingItems.length, equals(1));
        expect(pendingItems.first.entityType, equals('equipment_checks'));
        expect(syncedPayloads, isEmpty);

        // 4. Verify payload JSON serialization / deserialization integrity
        final dtoFromPayload = EquipmentCheckDto.fromJson(
          pendingItems.first.payloadJson,
        );
        expect(dtoFromPayload.id, equals('eq-sync-101'));
        expect(dtoFromPayload.equipmentType, equals('gnss'));
        expect(dtoFromPayload.isOperational, isTrue);

        // 5. Transition network status to online
        fakeNetworkInfo.setConnected(true);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // 6. Verify registered entity handler processed payload
        expect(syncedPayloads.length, equals(1));
        expect(syncedPayloads.first['id'], equals('eq-sync-101'));
        expect(syncedPayloads.first['serial_number'], equals('SN-GNSS-999'));

        // 7. Verify queue status marked as completed
        expect(syncQueueManager.getPendingItems(), isEmpty);
        expect(syncQueueManager.getCompletedItems().length, equals(1));
      },
    );

    test(
      'Timestamp conflict resolution (last-write-wins) for equipment check mutations',
      () async {
        fakeNetworkInfo.setConnected(false);

        final processedItems = <SyncQueueItem>[];

        syncQueueManager = SyncQueueManager(
          queueRepository: queueRepo,
          networkInfo: fakeNetworkInfo,
          customSyncHandler: (item) async {
            processedItems.add(item);
          },
        );

        final olderTimestamp = DateTime.parse('2026-07-18T06:00:00.000Z');
        final newerTimestamp = DateTime.parse('2026-07-18T09:00:00.000Z');

        final checkOld = EquipmentCheck(
          id: 'eq-conflict-1',
          siteId: 'site-1',
          foremanId: 'foreman-1',
          equipmentType: EquipmentType.totalStation,
          checkTime: olderTimestamp,
          checkType: CheckType.preWork,
          status: CheckStatus.flagged,
          isOperational: false,
          updatedAt: olderTimestamp,
        );

        final checkNew = EquipmentCheck(
          id: 'eq-conflict-1',
          siteId: 'site-1',
          foremanId: 'foreman-1',
          equipmentType: EquipmentType.totalStation,
          checkTime: newerTimestamp,
          checkType: CheckType.postWork,
          status: CheckStatus.passed,
          isOperational: true,
          updatedAt: newerTimestamp,
        );

        // Enqueue older mutation first
        await syncQueueManager.enqueueMutation(
          id: 'eq-mut-old',
          entityType: 'equipment_checks',
          action: SyncAction.update,
          payloadJson: EquipmentCheckDto.fromDomain(checkOld).toJson(),
          timestamp: olderTimestamp,
        );

        // Enqueue newer mutation second
        await syncQueueManager.enqueueMutation(
          id: 'eq-mut-new',
          entityType: 'equipment_checks',
          action: SyncAction.update,
          payloadJson: EquipmentCheckDto.fromDomain(checkNew).toJson(),
          timestamp: newerTimestamp,
        );

        fakeNetworkInfo.setConnected(true);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(processedItems.length, equals(2));
        expect(processedItems[0].timestamp, equals(olderTimestamp));
        expect(processedItems[1].timestamp, equals(newerTimestamp));
        expect(processedItems[1].payloadJson['status'], equals('passed'));
        expect(processedItems[1].payloadJson['is_operational'], isTrue);
      },
    );

    test(
      'Equipment check offline soft delete enqueues delete action and syncs',
      () async {
        fakeNetworkInfo.setConnected(false);

        final syncedActions = <SyncAction>[];

        syncQueueManager = SyncQueueManager(
          queueRepository: queueRepo,
          networkInfo: fakeNetworkInfo,
        );

        syncQueueManager.registerEntityHandler('equipment_checks', (
          item,
        ) async {
          syncedActions.add(item.action);
        });

        equipmentCheckRepository = EquipmentCheckRepositoryImpl(
          localCache: equipmentCache,
          syncQueueManager: syncQueueManager,
          networkInfo: fakeNetworkInfo,
        );

        final check = EquipmentCheck(
          id: 'eq-delete-101',
          siteId: 'site-1',
          foremanId: 'foreman-1',
          equipmentType: EquipmentType.drone,
          checkTime: DateTime.now(),
          checkType: CheckType.preWork,
          status: CheckStatus.passed,
        );

        await equipmentCheckRepository.saveEquipmentCheck(check);
        expect(syncQueueManager.getPendingItems().length, equals(1));

        // Delete offline
        await equipmentCheckRepository.deleteEquipmentCheck('eq-delete-101');
        expect(syncQueueManager.getPendingItems().length, equals(2));

        // Check soft-deleted locally
        final deletedCheck = await equipmentCheckRepository
            .getEquipmentCheckById('eq-delete-101');
        expect(deletedCheck, isNull);

        // Trigger online sync
        fakeNetworkInfo.setConnected(true);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(syncedActions.length, equals(2));
        expect(syncedActions.last, equals(SyncAction.delete));
        expect(syncQueueManager.getPendingItems(), isEmpty);
      },
    );
  });
}
