import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:logging/logging.dart';
import 'package:mine_flow/core/data/models/models.dart';
import 'package:mine_flow/core/offline/adapters/model_adapters.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/features/equipment_check/data/adapters/equipment_check_dto_adapter.dart';
import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';

/// Central initialization service managing Hive storage boxes, TypeAdapters,
/// and box recovery for local offline persistence.
class HiveService {
  static final Logger _logger = Logger('HiveService');

  // Box Name Constants
  static const String attendanceBoxName = 'attendance_box';
  static const String equipmentChecksBoxName = 'equipment_checks_box';
  static const String dailyLogsBoxName = 'daily_logs_box';
  static const String cutFillBoxName = 'cut_fill_box';
  static const String landClearingBoxName = 'land_clearing_box';
  static const String inventoryBoxName = 'inventory_box';
  static const String geospatialFilesBoxName = 'geospatial_files_box';
  static const String userBoxName = 'user_box';
  static const String zoneBoxName = 'zone_box';
  static const String syncQueueBoxName = 'sync_queue_box';

  static bool _isInitialized = false;

  /// Returns true if Hive boxes are opened and ready.
  static bool get isInitialized => _isInitialized;

  /// Initializes Hive storage engine, registers custom TypeAdapters,
  /// and opens operational data boxes safely with error recovery.
  static Future<void> init({String? storagePath}) async {
    if (_isInitialized) {
      _logger.info('HiveService already initialized.');
      return;
    }

    if (storagePath != null) {
      Hive.init(storagePath);
    } else if (!kIsWeb) {
      await Hive.initFlutter();
    } else {
      await Hive.initFlutter();
    }

    _registerAdapters();
    await _openAllBoxes();
    _isInitialized = true;
    _logger.info('HiveService initialized successfully with all boxes opened.');
  }

  /// Registers custom Hive TypeAdapters safely avoiding duplicate registrations.
  static void _registerAdapters() {
    _registerAdapterSafely<SyncQueueItem>(10, SyncQueueItemAdapter());
    _registerAdapterSafely<SyncAction>(11, SyncActionAdapter());
    _registerAdapterSafely<SyncStatus>(12, SyncStatusAdapter());

    _registerAdapterSafely<AttendanceRecordModel>(
      1,
      AttendanceRecordModelAdapter(),
    );
    _registerAdapterSafely<EquipmentCheckModel>(
      2,
      EquipmentCheckModelAdapter(),
    );
    _registerAdapterSafely<DailyLogModel>(3, DailyLogModelAdapter());
    _registerAdapterSafely<CutFillRecordModel>(4, CutFillRecordModelAdapter());
    _registerAdapterSafely<LandClearingRecordModel>(
      5,
      LandClearingRecordModelAdapter(),
    );
    _registerAdapterSafely<InventoryItemModel>(6, InventoryItemModelAdapter());
    _registerAdapterSafely<GeospatialFileModel>(
      7,
      GeospatialFileModelAdapter(),
    );
    _registerAdapterSafely<UserModel>(8, UserModelAdapter());
    _registerAdapterSafely<ZoneModel>(9, ZoneModelAdapter());

    _registerAdapterSafely<EquipmentCheckDto>(23, EquipmentCheckDtoAdapter());
  }

  static void _registerAdapterSafely<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  /// Opens all application Hive boxes with fallback error recovery if box data is corrupted.
  static Future<void> _openAllBoxes() async {
    await openBoxSafely<AttendanceRecordModel>(attendanceBoxName);
    await openBoxSafely<EquipmentCheckModel>(equipmentChecksBoxName);
    await openBoxSafely<DailyLogModel>(dailyLogsBoxName);
    await openBoxSafely<CutFillRecordModel>(cutFillBoxName);
    await openBoxSafely<LandClearingRecordModel>(landClearingBoxName);
    await openBoxSafely<InventoryItemModel>(inventoryBoxName);
    await openBoxSafely<GeospatialFileModel>(geospatialFilesBoxName);
    await openBoxSafely<UserModel>(userBoxName);
    await openBoxSafely<ZoneModel>(zoneBoxName);
    await openBoxSafely<SyncQueueItem>(syncQueueBoxName);
  }

  /// Opens a specific Hive box safely. If corrupted, deletes box from disk and reopens clean box.
  static Future<Box<T>> openBoxSafely<T>(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<T>(boxName);
      }
      return await Hive.openBox<T>(boxName);
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to open Hive box "$boxName". Attempting recovery by deleting box.',
        error,
        stackTrace,
      );
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (deleteError) {
        _logger.warning(
          'Could not delete corrupted box disk file: $deleteError',
        );
      }
      return await Hive.openBox<T>(boxName);
    }
  }

  // --- Direct Box Accessors ---
  static Box<AttendanceRecordModel> get attendanceBox =>
      Hive.box<AttendanceRecordModel>(attendanceBoxName);

  static Box<EquipmentCheckModel> get equipmentChecksBox =>
      Hive.box<EquipmentCheckModel>(equipmentChecksBoxName);

  static Box<DailyLogModel> get dailyLogsBox =>
      Hive.box<DailyLogModel>(dailyLogsBoxName);

  static Box<CutFillRecordModel> get cutFillBox =>
      Hive.box<CutFillRecordModel>(cutFillBoxName);

  static Box<LandClearingRecordModel> get landClearingBox =>
      Hive.box<LandClearingRecordModel>(landClearingBoxName);

  static Box<InventoryItemModel> get inventoryBox =>
      Hive.box<InventoryItemModel>(inventoryBoxName);

  static Box<GeospatialFileModel> get geospatialFilesBox =>
      Hive.box<GeospatialFileModel>(geospatialFilesBoxName);

  static Box<UserModel> get userBox => Hive.box<UserModel>(userBoxName);

  static Box<ZoneModel> get zoneBox => Hive.box<ZoneModel>(zoneBoxName);

  static Box<SyncQueueItem> get syncQueueBox =>
      Hive.box<SyncQueueItem>(syncQueueBoxName);

  // --- Repository Generators ---
  static HiveCacheRepository<AttendanceRecordModel> get attendanceRepository =>
      HiveCacheRepository(attendanceBox);

  static HiveCacheRepository<EquipmentCheckModel>
  get equipmentChecksRepository => HiveCacheRepository(equipmentChecksBox);

  static HiveCacheRepository<DailyLogModel> get dailyLogsRepository =>
      HiveCacheRepository(dailyLogsBox);

  static HiveCacheRepository<CutFillRecordModel> get cutFillRepository =>
      HiveCacheRepository(cutFillBox);

  static HiveCacheRepository<LandClearingRecordModel>
  get landClearingRepository => HiveCacheRepository(landClearingBox);

  static HiveCacheRepository<InventoryItemModel> get inventoryRepository =>
      HiveCacheRepository(inventoryBox);

  static HiveCacheRepository<GeospatialFileModel>
  get geospatialFilesRepository => HiveCacheRepository(geospatialFilesBox);

  static HiveCacheRepository<UserModel> get userRepository =>
      HiveCacheRepository(userBox);

  static HiveCacheRepository<ZoneModel> get zoneRepository =>
      HiveCacheRepository(zoneBox);

  static HiveCacheRepository<SyncQueueItem> get syncQueueRepository =>
      HiveCacheRepository(syncQueueBox);

  /// Clears data from all opened boxes.
  static Future<void> clearAllBoxes() async {
    await Future.wait([
      attendanceBox.clear(),
      equipmentChecksBox.clear(),
      dailyLogsBox.clear(),
      cutFillBox.clear(),
      landClearingBox.clear(),
      inventoryBox.clear(),
      geospatialFilesBox.clear(),
      userBox.clear(),
      zoneBox.clear(),
      syncQueueBox.clear(),
    ]);
    _logger.info('Cleared all Hive boxes successfully.');
  }

  /// Closes all Hive boxes and resets initialization state.
  static Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
    _logger.info('Closed all Hive boxes.');
  }
}
