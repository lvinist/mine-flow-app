import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/adapters/sync_queue_item_adapter.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/daily_log/data/adapters/daily_log_dto_adapter.dart';
import 'package:mine_flow/features/daily_log/data/datasources/daily_log_remote_datasource.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:mine_flow/features/daily_log/data/repositories/daily_log_repository_impl.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';

/// STEP-55.11 RESIDUAL-2 (B1): the daily-log submit write path, driven through
/// the BLoC against a REAL repository (real Hive, real sync queue) — not a
/// mock — because the defect lives in how the bloc orchestrates the two
/// repository calls, and every mock-backed widget/bloc test is blind to it.
///
/// Defect: `_onSubmitDailyLog` called
/// `autoSaveDraft(log.copyWith(status: submitted))` then `submitDailyLog(id)`.
/// On the NORMAL journey a debounced autosave has already cached a DRAFT row,
/// so the submit-time `autoSaveDraft(submitted)` hits the 48.23-re-run-5
/// monotonic guard (`max(incoming, cached)` → submitted) and PROMOTES the
/// cached row to `submitted`. `submitDailyLog` then reads a non-draft row and
/// throws "only a draft can be submitted (current status: submitted)". The
/// sequential failure-B pin in `test/unit/daily_log_repository_test.dart`
/// cannot reproduce this: it exercises the NO-CACHE path, where
/// `autoSaveDraft` force-drafts and the submit succeeds.
///
/// Fix: autosave the CURRENT (draft) log first (persisting field edits as a
/// draft), then let `submitDailyLog` perform the single promotion; the
/// submitted entity is used only for the emitted state.
class _MockNetworkInfo implements NetworkInfo {
  bool isOnline = false;
  @override
  Future<bool> get isConnected async => isOnline;
  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

class _MockRemote implements DailyLogRemoteDataSource {
  final List<DailyLogDto> data = [];
  @override
  Future<List<DailyLogDto>> fetchAllDailyLogs() async => data;
  @override
  Future<DailyLogDto?> fetchDailyLogById(String id) async {
    final m = data.where((d) => d.id == id);
    return m.isNotEmpty ? m.first : null;
  }

  @override
  Future<void> upsertDailyLog(DailyLogDto dto) async {
    data.removeWhere((d) => d.id == dto.id);
    data.add(dto);
  }

  @override
  Future<void> deleteDailyLog(String id) async =>
      data.removeWhere((d) => d.id == id);
}

void main() {
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  late Box<DailyLogDto> logBox;
  late Box<SyncQueueItem> queueBox;
  late HiveCacheRepository<DailyLogDto> localCache;
  late HiveCacheRepository<SyncQueueItem> queueRepo;
  late _MockNetworkInfo networkInfo;
  late SyncQueueManager syncQueueManager;
  late _MockRemote remote;
  late DailyLogRepositoryImpl repository;

  setUpAll(() async {
    Hive.init('./test_hive_daily_log_submit_realrepo');
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SyncActionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(DailyLogDtoAdapter());
    }
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    logBox = await Hive.openBox<DailyLogDto>('rr_log_$stamp');
    queueBox = await Hive.openBox<SyncQueueItem>('rr_queue_$stamp');
    localCache = HiveCacheRepository(logBox);
    queueRepo = HiveCacheRepository(queueBox);
    networkInfo = _MockNetworkInfo();
    syncQueueManager = SyncQueueManager(
      queueRepository: queueRepo,
      networkInfo: networkInfo,
    );
    remote = _MockRemote();
    repository = DailyLogRepositoryImpl(
      localCache: localCache,
      syncQueueManager: syncQueueManager,
      networkInfo: networkInfo,
      remoteDataSource: remote,
    );
  });

  tearDown(() async {
    await logBox.clear();
    await logBox.close();
    await queueBox.clear();
    await queueBox.close();
  });

  tearDownAll(() async => Hive.deleteFromDisk());

  DailyLog draftLog() => DailyLog(
    id: 'log-rr-1',
    siteId: defaultSiteId,
    foremanId: 'foreman-1',
    logDate: DateTime(2026, 9, 25),
    zoneId: 'zone-01',
    status: LogStatus.draft,
    summary: 'Pekerjaan tanggul selesai',
    weather: 'Cerah',
    hazard: const HazardAssessment.none(),
  );

  test(
    'submit after a cached autosaved draft succeeds and persists submitted '
    '(STEP-55.11 RESIDUAL-2 B1 — real repository, the normal journey path)',
    () async {
      final bloc = DailyLogBloc(repository: repository);
      // Open the form on the draft (the foreman is editing an existing draft).
      bloc.emit(DailyLogFormState(log: draftLog()));

      // The debounced autosave fires while typing → a DRAFT row is cached.
      // This is the precondition the sequential failure-B pin never sets up.
      bloc.add(const AutoSaveDraftEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        localCache.get('log-rr-1')?.status,
        equals('draft'),
        reason: 'debounced autosave must leave a cached draft row',
      );

      // The foreman taps Submit.
      bloc.add(const SubmitDailyLogEvent());

      // Wait for the submit to resolve.
      await bloc.stream.firstWhere(
        (s) =>
            s is DailyLogFormState && (s.isSubmitted || s.errorMessage != null),
      );

      final state = bloc.state as DailyLogFormState;
      expect(
        state.errorMessage,
        isNull,
        reason:
            'submit must not fail; pre-fix it threw "only a draft can be '
            'submitted (current status: submitted)" because the submit-time '
            'autoSaveDraft(submitted) promoted the cached draft first',
      );
      expect(state.isSubmitted, isTrue);
      expect(state.log.status, equals(LogStatus.submitted));

      // The persisted row and the final enqueued payload are submitted, so a
      // drain reaches Postgres with submitted (not the draft column default).
      expect(localCache.get('log-rr-1')!.status, equals('submitted'));
      expect(
        queueRepo.getAll().last.payloadJson['status'],
        equals('submitted'),
      );
      // The hazard assessment survived the submit transition.
      expect(localCache.get('log-rr-1')!.hazardState, equals('none'));

      await bloc.close();
    },
  );
}
