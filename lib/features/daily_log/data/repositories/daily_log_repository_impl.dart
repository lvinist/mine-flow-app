import 'dart:async';

import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/daily_log/data/datasources/daily_log_remote_datasource.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';

/// Implementation of [DailyLogRepository] enforcing local-first write/read patterns
/// with Hive caching and SyncQueueManager mutation enqueuing.
class DailyLogRepositoryImpl implements DailyLogRepository {
  final HiveCacheRepository<DailyLogDto> localCache;
  final SyncQueueManager syncQueueManager;
  final NetworkInfo networkInfo;
  final DailyLogRemoteDataSource? remoteDataSource;

  DailyLogRepositoryImpl({
    required this.localCache,
    required this.syncQueueManager,
    required this.networkInfo,
    this.remoteDataSource,
  });

  @override
  Future<List<DailyLog>> getDailyLogs({
    DateTime? date,
    String? siteId,
    String? foremanId,
    String? zoneId,
    LogStatus? status,
  }) async {
    final allDtos = localCache.getAll();
    final targetDateStr = date?.toIso8601String().split('T').first;

    final filtered = allDtos
        .where((dto) {
          if (dto.deletedAt != null) return false;

          if (targetDateStr != null) {
            final dtoDateStr = dto.logDate.toIso8601String().split('T').first;
            if (dtoDateStr != targetDateStr) return false;
          }

          if (siteId != null && dto.siteId != siteId) return false;
          if (foremanId != null && dto.foremanId != foremanId) return false;
          if (zoneId != null && dto.zoneId != zoneId) return false;

          if (status != null) {
            if (dto.status != status.toValue()) return false;
          }

          return true;
        })
        .map((dto) => dto.toDomain())
        .toList();

    unawaited(_refreshIfOnline());

    return filtered;
  }

  @override
  Future<DailyLog?> getDailyLogById(String id) async {
    final dto = localCache.get(id);
    if (dto == null || dto.deletedAt != null) return null;
    return dto.toDomain();
  }

  @override
  Future<DailyLog?> getDraftLogForForeman({
    required String foremanId,
    required DateTime date,
    String? siteId,
  }) async {
    final logs = await getDailyLogs(
      date: date,
      siteId: siteId,
      foremanId: foremanId,
      status: LogStatus.draft,
    );

    return logs.isNotEmpty ? logs.first : null;
  }

  @override
  Future<void> autoSaveDraft(DailyLog log) async {
    final now = DateTime.now().toUtc();
    final draftLog = log.copyWith(
      status: LogStatus.draft,
      updatedAt: now,
      createdAt: log.createdAt ?? now,
    );

    final dto = DailyLogDto.fromDomain(draftLog);

    await localCache.put(dto.id, dto);

    await syncQueueManager.enqueueMutation(
      entityType: 'daily_logs',
      action: SyncAction.update,
      payloadJson: dto.toJson(),
      timestamp: dto.updatedAt ?? now,
    );
  }

  @override
  Future<void> submitDailyLog(String id) async {
    final existing = localCache.get(id);
    if (existing == null || existing.deletedAt != null) {
      throw StateError('Cannot submit daily log: Log not found with ID $id');
    }

    final now = DateTime.now().toUtc();
    final updatedDto = DailyLogDto(
      id: existing.id,
      siteId: existing.siteId,
      foremanId: existing.foremanId,
      logDate: existing.logDate,
      zoneId: existing.zoneId,
      status: LogStatus.submitted.toValue(),
      summary: existing.summary,
      weather: existing.weather,
      notes: existing.notes,
      approvedBy: existing.approvedBy,
      createdAt: existing.createdAt ?? now,
      updatedAt: now,
      deletedAt: null,
    );

    await localCache.put(id, updatedDto);

    await syncQueueManager.enqueueMutation(
      entityType: 'daily_logs',
      action: SyncAction.update,
      payloadJson: updatedDto.toJson(),
      timestamp: now,
    );
  }

  @override
  Future<void> approveDailyLog(String id, {required String approvedBy}) async {
    final existing = localCache.get(id);
    if (existing == null || existing.deletedAt != null) {
      throw StateError('Cannot approve daily log: Log not found with ID $id');
    }

    final now = DateTime.now().toUtc();
    final updatedDto = DailyLogDto(
      id: existing.id,
      siteId: existing.siteId,
      foremanId: existing.foremanId,
      logDate: existing.logDate,
      zoneId: existing.zoneId,
      status: LogStatus.approved.toValue(),
      summary: existing.summary,
      weather: existing.weather,
      notes: existing.notes,
      approvedBy: approvedBy,
      createdAt: existing.createdAt ?? now,
      updatedAt: now,
      deletedAt: null,
    );

    await localCache.put(id, updatedDto);

    await syncQueueManager.enqueueMutation(
      entityType: 'daily_logs',
      action: SyncAction.update,
      payloadJson: updatedDto.toJson(),
      timestamp: now,
    );
  }

  @override
  Future<void> deleteDailyLog(String id) async {
    final existing = localCache.get(id);
    final now = DateTime.now().toUtc();

    if (existing != null) {
      final softDeletedDto = DailyLogDto(
        id: existing.id,
        siteId: existing.siteId,
        foremanId: existing.foremanId,
        logDate: existing.logDate,
        zoneId: existing.zoneId,
        status: existing.status,
        summary: existing.summary,
        weather: existing.weather,
        notes: existing.notes,
        approvedBy: existing.approvedBy,
        createdAt: existing.createdAt,
        updatedAt: now,
        deletedAt: now,
      );
      await localCache.put(id, softDeletedDto);
    } else {
      await localCache.delete(id);
    }

    await syncQueueManager.enqueueMutation(
      entityType: 'daily_logs',
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: now,
    );
  }

  @override
  Future<List<DailyLog>> syncRemote() async {
    if (remoteDataSource == null) {
      return localCache
          .getAll()
          .where((d) => d.deletedAt == null)
          .map((d) => d.toDomain())
          .toList();
    }

    final isOnline = await networkInfo.isConnected;
    if (!isOnline) {
      return localCache
          .getAll()
          .where((d) => d.deletedAt == null)
          .map((d) => d.toDomain())
          .toList();
    }

    try {
      final remoteDtos = await remoteDataSource!.fetchAllDailyLogs();
      // Last-write-wins merge, mirroring AttendanceRepositoryImpl.syncRemote
      // (STEP-48.20 re-run): a fetch snapshot that started before a local
      // save completed must not clobber the newer local row — 48.23's
      // failure-B refresh-clobber hypothesis named this exact race. A fetched
      // row that is equal-or-newer than the cached one still wins, so
      // genuine server-side corrections converge.
      final map = <String, DailyLogDto>{};
      for (final dto in remoteDtos) {
        final local = localCache.get(dto.id);
        if (local == null ||
            local.updatedAt == null ||
            dto.updatedAt == null ||
            !dto.updatedAt!.isBefore(local.updatedAt!)) {
          map[dto.id] = dto;
        }
      }
      await localCache.putAll(map);
      return remoteDtos.map((dto) => dto.toDomain()).toList();
    } catch (_) {
      return localCache
          .getAll()
          .where((d) => d.deletedAt == null)
          .map((d) => d.toDomain())
          .toList();
    }
  }

  Future<void> _refreshIfOnline() async {
    final isOnline = await networkInfo.isConnected;
    if (isOnline && remoteDataSource != null) {
      try {
        await syncRemote();
      } catch (_) {}
    }
  }
}
