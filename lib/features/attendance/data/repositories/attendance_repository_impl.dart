import 'dart:async';

import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';

/// Implementation of [AttendanceRepository] enforcing local-first write and read pattern
/// with fallback to local Hive cache, and background sync enqueuing.
class AttendanceRepositoryImpl implements AttendanceRepository {
  final HiveCacheRepository<AttendanceRecordDto> localCache;
  final SyncQueueManager syncQueueManager;
  final NetworkInfo networkInfo;
  final AttendanceRemoteDataSource? remoteDataSource;

  AttendanceRepositoryImpl({
    required this.localCache,
    required this.syncQueueManager,
    required this.networkInfo,
    this.remoteDataSource,
  });

  @override
  Future<List<AttendanceRecord>> getAttendanceForDate(
    DateTime date, {
    String? siteId,
  }) async {
    final allDtos = localCache.getAll();
    final targetDateStr = date.toIso8601String().split('T').first;

    final filtered = allDtos.where((dto) {
      if (dto.deletedAt != null) return false;
      final dtoDateStr = dto.date.toIso8601String().split('T').first;
      final matchesDate = dtoDateStr == targetDateStr;
      final matchesSite = siteId == null || dto.siteId == siteId;
      return matchesDate && matchesSite;
    }).map((dto) => dto.toDomain()).toList();

    unawaited(_refreshIfOnline());

    return filtered;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allDtos = localCache.getAll();

    final filtered = allDtos.where((dto) {
      if (dto.deletedAt != null) return false;
      if (dto.userId != userId) return false;
      if (startDate != null && dto.date.isBefore(startDate)) return false;
      if (endDate != null && dto.date.isAfter(endDate)) return false;
      return true;
    }).map((dto) => dto.toDomain()).toList();

    unawaited(_refreshIfOnline());

    return filtered;
  }

  @override
  Future<AttendanceRecord?> getAttendanceById(String id) async {
    final dto = localCache.get(id);
    if (dto == null || dto.deletedAt != null) return null;
    return dto.toDomain();
  }

  @override
  Future<void> saveAttendance(AttendanceRecord record) async {
    final updatedRecord = record.updatedAt == null
        ? record.copyWith(updatedAt: DateTime.now())
        : record;
    final dto = AttendanceRecordDto.fromDomain(updatedRecord);

    await localCache.put(dto.id, dto);

    await syncQueueManager.enqueueMutation(
      entityType: 'attendance_records',
      action: SyncAction.update,
      payloadJson: dto.toJson(),
      timestamp: dto.updatedAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> saveAttendanceBatch(List<AttendanceRecord> records) async {
    for (final record in records) {
      await saveAttendance(record);
    }
  }

  @override
  Future<void> deleteAttendance(String id) async {
    final existing = localCache.get(id);
    if (existing != null) {
      final softDeletedDto = AttendanceRecordDto(
        id: existing.id,
        siteId: existing.siteId,
        userId: existing.userId,
        date: existing.date,
        status: existing.status,
        remarks: existing.remarks,
        loggedBy: existing.loggedBy,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
      await localCache.put(id, softDeletedDto);
    } else {
      await localCache.delete(id);
    }

    await syncQueueManager.enqueueMutation(
      entityType: 'attendance_records',
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<AttendanceRecord>> syncRemote() async {
    if (remoteDataSource == null) {
      return localCache.getAll().map((d) => d.toDomain()).toList();
    }

    final isOnline = await networkInfo.isConnected;
    if (!isOnline) {
      return localCache.getAll().map((d) => d.toDomain()).toList();
    }

    try {
      final remoteDtos = await remoteDataSource!.fetchAllAttendance();
      final map = <String, AttendanceRecordDto>{
        for (final dto in remoteDtos) dto.id: dto
      };
      await localCache.putAll(map);
      return remoteDtos.map((dto) => dto.toDomain()).toList();
    } catch (_) {
      return localCache.getAll().map((d) => d.toDomain()).toList();
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
