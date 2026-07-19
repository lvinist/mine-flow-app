/// Centralised application initialisation module.
///
/// Creates and wires core services (Hive, Supabase, SyncQueueManager) and
/// registers feature-level sync handlers. Called once from `main.dart`.
///
/// This is a temporary bootstrap that will be replaced by a proper DI
/// container (e.g. GetIt) in STEP-10. For now it keeps the init sequence
/// explicit and testable.
///
/// == Usage ==
///
///   final initializer = AppInitializer();
///   await initializer.initialize();
///   runApp(const MineFlowApp());
///
/// == What it wires ==
///
/// 1. Hive boxes (local cache, sync queue)
/// 2. SyncQueueManager with network connectivity listener
/// 3. Feature sync registrars (tracking, data_bucket, …)
/// 4. Exposes services via getters so they can be passed into route extras
///    in `router.dart` until a real DI container lands.
library;

import 'package:hive/hive.dart';
import 'package:mine_flow/core/network/connectivity_service.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/adapters/timeline_milestone_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/services/pdf_service.dart';
import 'package:mine_flow/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';
import 'package:mine_flow/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:mine_flow/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:mine_flow/features/notifications/data/models/app_notification_model_adapter.dart';
import 'package:mine_flow/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:mine_flow/features/notifications/data/services/notification_rule_engine.dart';
import 'package:mine_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:mine_flow/features/reporting/data/datasources/reporting_remote_datasource.dart';
import 'package:mine_flow/features/reporting/data/repositories/reporting_repository_impl.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/timeline/data/datasources/timeline_remote_datasource.dart';
import 'package:mine_flow/features/timeline/data/repositories/timeline_repository_impl.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/data_bucket/data/datasources/data_bucket_local_datasource.dart';
import 'package:mine_flow/features/data_bucket/data/datasources/data_bucket_remote_datasource.dart';
import 'package:mine_flow/features/data_bucket/data/repositories/data_bucket_repository_impl.dart';
import 'package:mine_flow/features/data_bucket/data/sync/data_bucket_sync_registrar.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/tracking/data/datasources/tracking_local_datasource.dart';
import 'package:mine_flow/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:mine_flow/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mine_flow/core/data/models/inventory_item_model.dart'
    as core_inventory;
import 'package:mine_flow/core/data/models/cut_fill_record_model.dart';
import 'package:mine_flow/core/data/models/land_clearing_record_model.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/daily_log/data/adapters/daily_log_dto_adapter.dart';
import 'package:mine_flow/features/daily_log/data/datasources/daily_log_remote_datasource.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:mine_flow/features/daily_log/data/repositories/daily_log_repository_impl.dart';
import 'package:mine_flow/features/daily_log/data/sync/daily_log_sync_registrar.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/equipment_check/data/adapters/equipment_check_dto_adapter.dart';
import 'package:mine_flow/features/equipment_check/data/sync/equipment_check_sync_registrar.dart';
import 'package:mine_flow/features/equipment_check/data/datasources/equipment_check_remote_datasource.dart';
import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';
import 'package:mine_flow/features/equipment_check/data/repositories/equipment_check_repository_impl.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/attendance/data/sync/attendance_sync_registrar.dart';
import 'package:mine_flow/features/tracking/data/sync/tracking_sync_registrar.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';

/// Holds initialised core services so they can be injected into route
/// builders and feature modules.
class AppServices {
  final SyncQueueManager syncQueueManager;
  final DataBucketRepository dataBucketRepository;
  final TimelineRepository timelineRepository;
  final ReportingRepository reportingRepository;
  final NotificationRepository notificationRepository;
  final TrackingRepository trackingRepository;
  final AttendanceRepository attendanceRepository;
  final DailyLogRepository dailyLogRepository;
  final EquipmentCheckRepository equipmentCheckRepository;
  final PdfService pdfService;

  const AppServices({
    required this.syncQueueManager,
    required this.dataBucketRepository,
    required this.timelineRepository,
    required this.reportingRepository,
    required this.notificationRepository,
    required this.trackingRepository,
    required this.attendanceRepository,
    required this.dailyLogRepository,
    required this.equipmentCheckRepository,
    required this.pdfService,
  });
}

/// Performs application-level initialisation of core services.
class AppInitializer {
  AppServices? _services;

  /// Returns the initialised services (throws if called before [initialize]).
  AppServices get services {
    if (_services == null) {
      throw StateError(
        'AppInitializer.initialize() must be called before accessing services.',
      );
    }
    return _services!;
  }

  /// Runs the full initialisation sequence.
  ///
  /// Must be called **after** `Hive.initFlutter()` and `Supabase.initialize()`
  /// have completed (those are done in `main.dart`).
  Future<AppServices> initialize() async {
    // --- 1. Register Hive adapters ---
    _registerHiveAdapters();

    // --- 2. Open boxes ---
    final dataBucketBox = await Hive.openBox<Map<String, dynamic>>(
      'data_bucket_files',
    );
    final syncQueueBox = await Hive.openBox<SyncQueueItem>('sync_queue');

    // --- 3. Create core services ---
    final connectivityService = ConnectivityService();
    final networkInfo = NetworkInfoImpl(connectivityService);
    final queueRepository = HiveCacheRepository<SyncQueueItem>(syncQueueBox);
    final supabaseClient = Supabase.instance.client;
    final pdfService = PdfService();

    final syncQueueManager = SyncQueueManager(
      queueRepository: queueRepository,
      networkInfo: networkInfo,
      supabaseClient: supabaseClient,
    );

    // --- 4. Create feature data sources & repositories ---

    // Data Bucket
    final dataBucketLocalDataSource = DataBucketLocalDataSourceImpl(
      hiveBox: dataBucketBox,
    );
    final dataBucketRemoteDataSource = DataBucketRemoteDataSourceImpl(
      supabaseClient: supabaseClient,
    );
    final dataBucketRepository = DataBucketRepositoryImpl(
      localDataSource: dataBucketLocalDataSource,
      remoteDataSource: dataBucketRemoteDataSource,
      syncQueueManager: syncQueueManager,
      networkInfo: networkInfo,
    );

    // Timeline
    final timelineRemoteDataSource = TimelineRemoteDataSource(
      supabaseClient: supabaseClient,
    );
    final timelineRepository = TimelineRepositoryImpl(
      remoteDataSource: timelineRemoteDataSource,
    );

    // Reporting
    final reportingRemoteDataSource = ReportingRemoteDataSource(
      supabaseClient: supabaseClient,
    );
    final reportingRepository = ReportingRepositoryImpl(
      remoteDataSource: reportingRemoteDataSource,
      pdfService: pdfService,
    );

    // Tracking (needed by NotificationRuleEngine)
    final cutFillBox = await Hive.openBox<CutFillRecordModel>('cut_fill');
    final landClearingBox = await Hive.openBox<LandClearingRecordModel>(
      'land_clearing',
    );
    final inventoryBox = await Hive.openBox<core_inventory.InventoryItemModel>(
      'inventory',
    );

    final trackingLocalDataSource = TrackingLocalDataSourceImpl(
      cutFillCache: HiveCacheRepository<CutFillRecordModel>(cutFillBox),
      landClearingCache: HiveCacheRepository<LandClearingRecordModel>(
        landClearingBox,
      ),
      inventoryCache: HiveCacheRepository<core_inventory.InventoryItemModel>(
        inventoryBox,
      ),
    );
    final trackingRemoteDataSource = TrackingRemoteDataSourceImpl(
      supabaseClient: supabaseClient,
    );
    final trackingRepository = TrackingRepositoryImpl(
      localDataSource: trackingLocalDataSource,
      syncQueueManager: syncQueueManager,
      networkInfo: networkInfo,
      remoteDataSource: trackingRemoteDataSource,
    );

    // Attendance (needed by NotificationRuleEngine)
    final attendanceBox = await Hive.openBox<AttendanceRecordDto>(
      'attendance_records',
    );
    final attendanceRepository = AttendanceRepositoryImpl(
      localCache: HiveCacheRepository<AttendanceRecordDto>(attendanceBox),
      syncQueueManager: syncQueueManager,
      networkInfo: networkInfo,
      remoteDataSource: SupabaseAttendanceRemoteDataSource(supabaseClient),
    );

    // Notifications
    final notificationLocalDataSource = NotificationLocalDataSource();
    // The local datasource auto-opens the 'notifications' box on first access.
    final notificationRuleEngine = NotificationRuleEngine(
      trackingRepository: trackingRepository,
      attendanceRepository: attendanceRepository,
      timelineRepository: timelineRepository,
    );
    final notificationRepository = NotificationRepositoryImpl(
      ruleEngine: notificationRuleEngine,
      localDataSource: notificationLocalDataSource,
    );

    // Daily Log
    final dailyLogBox = await Hive.openBox<DailyLogDto>('daily_logs');
    final dailyLogRemoteDataSource = SupabaseDailyLogRemoteDataSource(
      supabaseClient,
    );
    final dailyLogRepository = DailyLogRepositoryImpl(
      localCache: HiveCacheRepository<DailyLogDto>(dailyLogBox),
      syncQueueManager: syncQueueManager,
      networkInfo: networkInfo,
      remoteDataSource: dailyLogRemoteDataSource,
    );

    // Equipment Check
    final equipmentCheckBox = await Hive.openBox<EquipmentCheckDto>(
      'equipment_checks',
    );
    final equipmentCheckRemoteDataSource = EquipmentCheckRemoteDataSourceImpl(
      supabaseClient: supabaseClient,
    );
    final equipmentCheckRepository = EquipmentCheckRepositoryImpl(
      localCache: HiveCacheRepository<EquipmentCheckDto>(equipmentCheckBox),
      syncQueueManager: syncQueueManager,
      networkInfo: networkInfo,
      remoteDataSource: equipmentCheckRemoteDataSource,
    );

    // --- 5. Register feature sync handlers ---
    DataBucketSyncRegistrar.registerSyncHandlers(
      syncQueueManager,
      dataBucketRepository,
    );

    TrackingSyncRegistrar.registerSyncHandlers(
      syncQueueManager,
      trackingRemoteDataSource,
    );

    AttendanceSyncRegistrar.registerSyncHandlers(
      syncQueueManager,
      attendanceRepository,
    );

    DailyLogSyncRegistrar.registerSyncHandlers(
      syncQueueManager,
      dailyLogRepository,
    );

    EquipmentCheckSyncRegistrar.registerSyncHandlers(
      syncQueueManager,
      equipmentCheckRepository,
    );

    // --- 6. Store for later access ---
    _services = AppServices(
      syncQueueManager: syncQueueManager,
      dataBucketRepository: dataBucketRepository,
      timelineRepository: timelineRepository,
      reportingRepository: reportingRepository,
      notificationRepository: notificationRepository,
      trackingRepository: trackingRepository,
      attendanceRepository: attendanceRepository,
      dailyLogRepository: dailyLogRepository,
      equipmentCheckRepository: equipmentCheckRepository,
      pdfService: pdfService,
    );

    return _services!;
  }

  void _registerHiveAdapters() {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SyncActionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    // Type ID 14 — TimelineMilestoneModel
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(TimelineMilestoneModelAdapter());
    }
    // Type IDs 15–17 — Notifications (AppNotificationModel + enums)
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(AppNotificationModelAdapter());
    }
    // Type ID 22 — DailyLogDto
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(DailyLogDtoAdapter());
    }
    // Type ID 23 — EquipmentCheckDto
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(EquipmentCheckDtoAdapter());
    }
  }
}
