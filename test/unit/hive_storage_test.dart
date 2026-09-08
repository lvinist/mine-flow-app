import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/data/models/models.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/hive_service.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    await HiveService.init(storagePath: tempDir.path);
  });

  tearDown(() async {
    await HiveService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveService Initialization & Lifecycle', () {
    test('should initialize Hive, register adapters, and open all boxes', () {
      expect(HiveService.isInitialized, isTrue);
      expect(HiveService.attendanceBox.isOpen, isTrue);
      expect(HiveService.equipmentChecksBox.isOpen, isTrue);
      expect(HiveService.dailyLogsBox.isOpen, isTrue);
      expect(HiveService.cutFillBox.isOpen, isTrue);
      expect(HiveService.landClearingBox.isOpen, isTrue);
      expect(HiveService.inventoryBox.isOpen, isTrue);
      expect(HiveService.syncQueueBox.isOpen, isTrue);
    });

    test('should clear all boxes when clearAllBoxes() is called', () async {
      final syncItem = SyncQueueItem(
        id: 'sync-1',
        entityType: 'attendance',
        action: SyncAction.create,
        payloadJson: const {'user_id': 'user-1'},
        timestamp: DateTime.now(),
      );
      await HiveService.syncQueueRepository.put(syncItem.id, syncItem);
      expect(HiveService.syncQueueRepository.length, equals(1));

      await HiveService.clearAllBoxes();
      expect(HiveService.syncQueueRepository.length, equals(0));
    });

    test('should recover gracefully when opening a corrupted box file', () async {
      // Close existing service
      await HiveService.close();

      // Corrupt a box file manually on disk
      final boxFile = File(
        '${tempDir.path}/${HiveService.attendanceBoxName}.hive',
      );
      await boxFile.writeAsString('CORRUPTED_NON_HIVE_BINARY_DATA');

      // Re-initialize HiveService - should recover by deleting corrupted file and opening a fresh box
      await HiveService.init(storagePath: tempDir.path);
      expect(HiveService.attendanceBox.isOpen, isTrue);
      expect(HiveService.attendanceBox.length, equals(0));
    });
  });

  group('SyncQueueItem & SyncQueueRepository', () {
    final tItem = SyncQueueItem(
      id: 'queue-uuid-101',
      entityType: 'equipment_checks',
      action: SyncAction.create,
      payloadJson: const {
        'id': 'check-uuid-1',
        'equipment_type': 'gnss',
        'is_operational': true,
      },
      timestamp: DateTime.parse('2026-07-18T12:00:00.000Z'),
      syncStatus: SyncStatus.pending,
      retryCount: 0,
    );

    test('should serialize to JSON and deserialize back correctly', () {
      final json = tItem.toJson();
      expect(json['id'], equals('queue-uuid-101'));
      expect(json['action'], equals('create'));
      expect(json['sync_status'], equals('pending'));

      final restored = SyncQueueItem.fromJson(json);
      expect(restored, equals(tItem));
    });

    test('should update fields using copyWith', () {
      final updated = tItem.copyWith(
        syncStatus: SyncStatus.failed,
        retryCount: 1,
        errorMessage: 'Network timeout',
      );
      expect(updated.syncStatus, equals(SyncStatus.failed));
      expect(updated.retryCount, equals(1));
      expect(updated.errorMessage, equals('Network timeout'));
      expect(updated.id, equals(tItem.id));
    });

    test('should store and retrieve SyncQueueItem from Hive', () async {
      final repo = HiveService.syncQueueRepository;
      await repo.put(tItem.id, tItem);

      expect(repo.containsKey(tItem.id), isTrue);
      final retrieved = repo.get(tItem.id);
      expect(retrieved, equals(tItem));
      expect(retrieved?.action, equals(SyncAction.create));
    });
  });

  group('HiveCacheRepository Generic Operations', () {
    late HiveCacheRepository<AttendanceRecordModel> repo;

    final tAttendance = AttendanceRecordModel(
      id: 'att-101',
      siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      userId: 'user-77',
      date: DateTime.parse('2026-07-18'),
      status: 'present',
      remarks: 'Morning shift',
    );

    setUp(() {
      repo = HiveService.attendanceRepository;
    });

    test('should perform CRUD operations on cached models', () async {
      expect(repo.isEmpty, isTrue);

      // Put
      await repo.put(tAttendance.id, tAttendance);
      expect(repo.length, equals(1));

      // Get
      final fetched = repo.get(tAttendance.id);
      expect(fetched?.id, equals(tAttendance.id));
      expect(fetched?.status, equals('present'));

      // Get all
      final all = repo.getAll();
      expect(all.length, equals(1));
      expect(all.first, equals(tAttendance));

      // Delete
      await repo.delete(tAttendance.id);
      expect(repo.get(tAttendance.id), isNull);
      expect(repo.isEmpty, isTrue);
    });

    test('should support bulk putAll and clear operations', () async {
      final item2 = AttendanceRecordModel(
        id: 'att-102',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        userId: 'user-78',
        date: DateTime.parse('2026-07-18'),
        status: 'absent',
      );

      await repo.putAll({tAttendance.id: tAttendance, item2.id: item2});

      expect(repo.length, equals(2));
      expect(repo.getAll().length, equals(2));

      await repo.clear();
      expect(repo.length, equals(0));
    });
  });

  group('Operational Models Hive Round-Trip', () {
    test('should cache and retrieve EquipmentCheckModel', () async {
      final repo = HiveService.equipmentChecksRepository;
      final model = EquipmentCheckModel(
        id: 'check-201',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        foremanId: 'foreman-1',
        equipmentType: 'drone',
        serialNumber: 'DJI-MAVIC-3',
        checkTime: DateTime.parse('2026-07-18T08:30:00.000Z'),
        isOperational: true,
        checklistData: const {'battery_pct': 98, 'propellers_intact': true},
      );

      await repo.put(model.id, model);
      final retrieved = repo.get(model.id);

      expect(retrieved, equals(model));
      expect(retrieved?.checklistData['battery_pct'], equals(98));
    });

    test('should cache and retrieve DailyLogModel', () async {
      final repo = HiveService.dailyLogsRepository;
      final model = DailyLogModel(
        id: 'log-301',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        foremanId: 'foreman-1',
        logDate: DateTime.parse('2026-07-18'),
        zoneId: 'zone-alpha',
        status: 'draft',
        summary: 'Site clearing ongoing',
        weather: 'Rainy',
      );

      await repo.put(model.id, model);
      final retrieved = repo.get(model.id);

      expect(retrieved, equals(model));
      expect(retrieved?.weather, equals('Rainy'));
    });

    test('should cache and retrieve CutFillRecordModel', () async {
      final repo = HiveService.cutFillRepository;
      final model = CutFillRecordModel(
        id: 'cf-401',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        dailyLogId: 'log-301',
        zoneId: 'zone-alpha',
        bcmVolume: 600.0,
        lcmVolume: 150.0,
        elevationChange: -1.2,
        measuredAt: DateTime.parse('2026-07-18T10:00:00.000Z'),
      );

      await repo.put(model.id, model);
      final retrieved = repo.get(model.id);

      expect(retrieved, equals(model));
      expect(retrieved?.bcmVolume, equals(600.0));
    });

    test('should cache and retrieve InventoryItemModel', () async {
      final repo = HiveService.inventoryRepository;
      const model = InventoryItemModel(
        id: 'inv-501',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        name: 'Explosive Charges',
        sku: 'EXP-88',
        category: 'Blasting',
        quantity: 120.0,
        unit: 'kg',
        minThreshold: 20.0,
      );

      await repo.put(model.id, model);
      final retrieved = repo.get(model.id);

      expect(retrieved, equals(model));
      expect(retrieved?.quantity, equals(120.0));
    });
  });
}
