import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/data/models/models.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/base_offline_repository.dart';
import 'package:mine_flow/core/offline/hive_service.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/core/offline/battery_state_provider.dart';

/// Fake implementation of [NetworkInfo] for testing connection state changes.
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

/// Fake implementation of [BatteryStateProvider] for testing battery states.
class FakeBatteryStateProvider implements BatteryStateProvider {
  int _batteryLevel = 100;
  bool _isInBatterySaveMode = false;
  bool _isCharging = false;

  void setBatteryState({
    int level = 100,
    bool saverMode = false,
    bool charging = false,
  }) {
    _batteryLevel = level;
    _isInBatterySaveMode = saverMode;
    _isCharging = charging;
  }

  @override
  Future<int> get batteryLevel async => _batteryLevel;

  @override
  Future<bool> get isInBatterySaveMode async => _isInBatterySaveMode;

  @override
  Future<bool> get isCharging async => _isCharging;
}

/// Simple model for testing [BaseOfflineRepository].
class TestItem {
  final String id;
  final String title;
  final DateTime updatedAt;

  TestItem({required this.id, required this.title, required this.updatedAt});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory TestItem.fromJson(Map<String, dynamic> json) => TestItem(
    id: json['id'] as String,
    title: json['title'] as String,
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ updatedAt.hashCode;
}

class TestOfflineRepository
    extends BaseOfflineRepository<AttendanceRecordModel> {
  final List<AttendanceRecordModel> remoteDatabase = [];

  TestOfflineRepository({
    required super.localCache,
    required super.syncQueueManager,
    required super.networkInfo,
  });

  @override
  String get entityType => 'attendance_records';

  @override
  String getId(AttendanceRecordModel item) => item.id;

  @override
  Map<String, dynamic> toJson(AttendanceRecordModel item) => item.toJson();

  @override
  AttendanceRecordModel fromJson(Map<String, dynamic> json) =>
      AttendanceRecordModel.fromJson(json);

  @override
  DateTime getUpdatedAt(AttendanceRecordModel item) =>
      item.createdAt ?? DateTime.now();

  @override
  Future<List<AttendanceRecordModel>> fetchRemote() async {
    return List.from(remoteDatabase);
  }
}

Future<void> pumpUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    if (condition()) return;
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late Directory tempDir;
  late FakeNetworkInfo fakeNetworkInfo;
  late FakeBatteryStateProvider fakeBatteryProvider;
  late SyncQueueManager syncQueueManager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_test_');
    await HiveService.init(storagePath: tempDir.path);
    fakeNetworkInfo = FakeNetworkInfo();
    fakeBatteryProvider = FakeBatteryStateProvider();
  });

  tearDown(() async {
    await syncQueueManager.dispose();
    fakeNetworkInfo.dispose();
    await HiveService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SyncQueueManager Integration Tests', () {
    test('enqueues items while offline and defer execution', () async {
      fakeNetworkInfo.setConnected(false);

      syncQueueManager = SyncQueueManager(
        queueRepository: HiveService.syncQueueRepository,
        networkInfo: fakeNetworkInfo,
        batteryProvider: fakeBatteryProvider,
      );

      final item = await syncQueueManager.enqueueMutation(
        id: 'sync-item-1',
        entityType: 'daily_logs',
        action: SyncAction.create,
        payloadJson: {'id': 'log-1', 'summary': 'Logged offline'},
        timestamp: DateTime.parse('2026-07-18T10:00:00.000Z'),
      );

      expect(item.syncStatus, equals(SyncStatus.pending));

      final pending = syncQueueManager.getPendingItems();
      expect(pending.length, equals(1));
      expect(pending.first.id, equals('sync-item-1'));
    });

    test(
      'replays pending items in FIFO sequence when network turns online',
      () async {
        fakeNetworkInfo.setConnected(false);

        final syncedItems = <String>[];

        syncQueueManager = SyncQueueManager(
          queueRepository: HiveService.syncQueueRepository,
          networkInfo: fakeNetworkInfo,
          batteryProvider: fakeBatteryProvider,
          customSyncHandler: (item) async {
            syncedItems.add(item.id);
          },
        );

        // Enqueue 3 items out of order timestamps
        await syncQueueManager.enqueueMutation(
          id: 'item-2',
          entityType: 'attendance',
          action: SyncAction.create,
          payloadJson: {'id': 'att-2'},
          timestamp: DateTime.parse('2026-07-18T12:00:00.000Z'),
        );

        await syncQueueManager.enqueueMutation(
          id: 'item-1',
          entityType: 'attendance',
          action: SyncAction.create,
          payloadJson: {'id': 'att-1'},
          timestamp: DateTime.parse('2026-07-18T10:00:00.000Z'),
        );

        expect(syncedItems, isEmpty);

        // Trigger online transition
        fakeNetworkInfo.setConnected(true);

        // Allow async queue processing to execute using polling
        await pumpUntil(() => syncQueueManager.getCompletedItems().length == 2);

        // Check items synced in FIFO (chronological timestamp) order: item-1 then item-2
        expect(syncedItems, equals(['item-1', 'item-2']));

        final completed = syncQueueManager.getCompletedItems();
        expect(completed.length, equals(2));
        expect(syncQueueManager.getPendingItems(), isEmpty);
      },
    );

    test(
      'handles retries and marks failed items after exceeding max retries',
      () async {
        fakeNetworkInfo.setConnected(true);

        var attemptCounter = 0;

        syncQueueManager = SyncQueueManager(
          queueRepository: HiveService.syncQueueRepository,
          networkInfo: fakeNetworkInfo,
          batteryProvider: fakeBatteryProvider,
          maxRetries: 2,
          customSyncHandler: (item) async {
            attemptCounter++;
            throw Exception('Remote server error 500');
          },
        );

        await syncQueueManager.enqueueMutation(
          id: 'item-failing',
          entityType: 'equipment_checks',
          action: SyncAction.update,
          payloadJson: {'id': 'check-99'},
          timestamp: DateTime.now(),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(attemptCounter, equals(1));

        // Trigger second attempt
        await syncQueueManager.processQueue();
        expect(attemptCounter, equals(2));

        // Item should now be in permanently failed list after reaching maxRetries (2)
        final failed = syncQueueManager.getFailedItems();
        expect(failed.length, equals(1));
        expect(failed.first.retryCount, equals(2));
        expect(failed.first.errorMessage, contains('Remote server error 500'));
      },
    );

    test('purges completed items from local queue box', () async {
      fakeNetworkInfo.setConnected(true);

      syncQueueManager = SyncQueueManager(
        queueRepository: HiveService.syncQueueRepository,
        networkInfo: fakeNetworkInfo,
        batteryProvider: fakeBatteryProvider,
        customSyncHandler: (_) async {},
      );

      await syncQueueManager.enqueueMutation(
        id: 'item-to-purge',
        entityType: 'zones',
        action: SyncAction.create,
        payloadJson: {'id': 'z-1'},
        timestamp: DateTime.now(),
      );

      await pumpUntil(() => syncQueueManager.getCompletedItems().length == 1);
      expect(syncQueueManager.getCompletedItems().length, equals(1));

      await syncQueueManager.purgeCompletedItems();
      expect(syncQueueManager.getCompletedItems(), isEmpty);
    });

    test('pauses automatic sync if battery is <= 20%', () async {
      fakeNetworkInfo.setConnected(true);
      fakeBatteryProvider.setBatteryState(
        level: 20,
        saverMode: false,
        charging: false,
      );

      var attemptCounter = 0;
      syncQueueManager = SyncQueueManager(
        queueRepository: HiveService.syncQueueRepository,
        networkInfo: fakeNetworkInfo,
        batteryProvider: fakeBatteryProvider,
        customSyncHandler: (item) async {
          attemptCounter++;
        },
      );

      await syncQueueManager.enqueueMutation(
        id: 'item-low-battery',
        entityType: 'zones',
        action: SyncAction.create,
        payloadJson: {'id': 'z-1'},
        timestamp: DateTime.now(),
      );

      await pumpUntil(
        () => attemptCounter > 0,
        timeout: const Duration(milliseconds: 100),
      );
      expect(attemptCounter, equals(0)); // Paused

      // Test manual bypass
      await syncQueueManager.processQueue(isManual: true);
      expect(attemptCounter, equals(1));
    });

    test('pauses automatic sync if battery saver is ON', () async {
      fakeNetworkInfo.setConnected(true);
      fakeBatteryProvider.setBatteryState(
        level: 50,
        saverMode: true,
        charging: false,
      );

      var attemptCounter = 0;
      syncQueueManager = SyncQueueManager(
        queueRepository: HiveService.syncQueueRepository,
        networkInfo: fakeNetworkInfo,
        batteryProvider: fakeBatteryProvider,
        customSyncHandler: (item) async {
          attemptCounter++;
        },
      );

      await syncQueueManager.enqueueMutation(
        id: 'item-saver-on',
        entityType: 'zones',
        action: SyncAction.create,
        payloadJson: {'id': 'z-1'},
        timestamp: DateTime.now(),
      );

      await pumpUntil(
        () => attemptCounter > 0,
        timeout: const Duration(milliseconds: 100),
      );
      expect(attemptCounter, equals(0)); // Paused
    });

    test(
      'bypasses pause if device is charging despite low battery and saver mode',
      () async {
        fakeNetworkInfo.setConnected(true);
        fakeBatteryProvider.setBatteryState(
          level: 10,
          saverMode: true,
          charging: true,
        );

        var attemptCounter = 0;
        syncQueueManager = SyncQueueManager(
          queueRepository: HiveService.syncQueueRepository,
          networkInfo: fakeNetworkInfo,
          batteryProvider: fakeBatteryProvider,
          customSyncHandler: (item) async {
            attemptCounter++;
          },
        );

        await syncQueueManager.enqueueMutation(
          id: 'item-charging',
          entityType: 'zones',
          action: SyncAction.create,
          payloadJson: {'id': 'z-1'},
          timestamp: DateTime.now(),
        );

        await pumpUntil(() => attemptCounter == 1);
        expect(attemptCounter, equals(1)); // Proceeded
      },
    );
  });

  group('BaseOfflineRepository Integration Tests', () {
    test(
      'write operations persist locally and enqueue sync mutation',
      () async {
        fakeNetworkInfo.setConnected(false);

        syncQueueManager = SyncQueueManager(
          queueRepository: HiveService.syncQueueRepository,
          networkInfo: fakeNetworkInfo,
          batteryProvider: fakeBatteryProvider,
        );

        final repo = TestOfflineRepository(
          localCache: HiveService.attendanceRepository,
          syncQueueManager: syncQueueManager,
          networkInfo: fakeNetworkInfo,
        );

        final record = AttendanceRecordModel(
          id: 'att-offline-1',
          siteId: '00000000-0000-0000-0000-000000000001',
          userId: 'user-123',
          date: DateTime.parse('2026-07-18'),
          status: 'present',
        );

        // Save offline
        await repo.save(record);

        // 1. Verify local cache updated immediately
        final cached = repo.getById('att-offline-1');
        expect(cached, equals(record));

        // 2. Verify mutation enqueued in sync manager
        final pending = syncQueueManager.getPendingItems();
        expect(pending.length, equals(1));
        expect(pending.first.entityType, equals('attendance_records'));
        expect(pending.first.payloadJson['id'], equals('att-offline-1'));

        // Delete offline
        await repo.delete('att-offline-1');
        expect(repo.getById('att-offline-1'), isNull);
        expect(syncQueueManager.getPendingItems().length, equals(2));
      },
    );
  });
}
