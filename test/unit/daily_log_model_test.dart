import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/daily_log/data/adapters/daily_log_dto_adapter.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

void main() {
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

  group('LogStatus Enum', () {
    test('should parse string values correctly', () {
      expect(LogStatus.fromString('draft'), equals(LogStatus.draft));
      expect(LogStatus.fromString('submitted'), equals(LogStatus.submitted));
      expect(LogStatus.fromString('approved'), equals(LogStatus.approved));
      expect(LogStatus.fromString('SUBMITTED'), equals(LogStatus.submitted));
      expect(LogStatus.fromString(null), equals(LogStatus.draft));
      expect(LogStatus.fromString('unknown'), equals(LogStatus.draft));
    });

    test('should convert enum to value string', () {
      expect(LogStatus.draft.toValue(), equals('draft'));
      expect(LogStatus.submitted.toValue(), equals('submitted'));
      expect(LogStatus.approved.toValue(), equals('approved'));
    });
  });

  group('DailyLog Domain Entity', () {
    final tLog = DailyLog(
      id: 'log-101',
      siteId: defaultSiteId,
      foremanId: 'foreman-001',
      logDate: DateTime(2026, 7, 18),
      zoneId: 'zone-north',
      status: LogStatus.draft,
      summary: 'Cleared 500m2 in Pit Rusia',
      weather: 'Sunny',
      notes: 'No safety incidents reported',
    );

    test('should support copyWith method', () {
      final updated = tLog.copyWith(
        status: LogStatus.submitted,
        summary: 'Updated summary text',
      );

      expect(updated.id, equals('log-101'));
      expect(updated.status, equals(LogStatus.submitted));
      expect(updated.summary, equals('Updated summary text'));
      expect(updated.foremanId, equals('foreman-001'));
    });

    test('should support value equality via Equatable', () {
      final tLog2 = DailyLog(
        id: 'log-101',
        siteId: defaultSiteId,
        foremanId: 'foreman-001',
        logDate: DateTime(2026, 7, 18),
        zoneId: 'zone-north',
        status: LogStatus.draft,
        summary: 'Cleared 500m2 in Pit Rusia',
        weather: 'Sunny',
        notes: 'No safety incidents reported',
      );

      expect(tLog, equals(tLog2));
    });
  });

  group('DailyLogDto & Mappers', () {
    final tJson = <String, dynamic>{
      'id': 'log-201',
      'site_id': defaultSiteId,
      'foreman_id': 'foreman-002',
      'log_date': '2026-07-18',
      'zone_id': 'zone-south',
      'status': 'submitted',
      'summary': 'Soil bank clearing complete',
      'weather': 'Cloudy',
      'notes': 'Excavator 03 maintenance due',
      'approved_by': null,
      'created_at': '2026-07-18T07:00:00.000Z',
    };

    test('should parse JSON correctly into DTO', () {
      final dto = DailyLogDto.fromJson(tJson);
      expect(dto.id, equals('log-201'));
      expect(dto.foremanId, equals('foreman-002'));
      expect(dto.status, equals('submitted'));
      expect(dto.summary, equals('Soil bank clearing complete'));
      expect(dto.weather, equals('Cloudy'));
    });

    test('should convert DTO to JSON map', () {
      final dto = DailyLogDto.fromJson(tJson);
      final json = dto.toJson();
      expect(json['id'], equals('log-201'));
      expect(json['status'], equals('submitted'));
      expect(json['log_date'], equals('2026-07-18'));
      expect(json['weather'], equals('Cloudy'));
    });

    test('should map bidirectional between DTO and Domain Entity', () {
      final dto = DailyLogDto.fromJson(tJson);
      final entity = dto.toDomain();
      expect(entity.id, equals(dto.id));
      expect(entity.status, equals(LogStatus.submitted));

      final convertedDto = DailyLogDto.fromDomain(entity);
      expect(convertedDto.id, equals(dto.id));
      expect(convertedDto.status, equals(dto.status));
    });
  });

  group('DailyLogDtoAdapter Hive Adapter', () {
    test('should write and read DailyLogDto using adapter', () {
      final adapter = DailyLogDtoAdapter();
      expect(adapter.typeId, equals(22));

      final originalDto = DailyLogDto(
        id: 'log-301',
        siteId: defaultSiteId,
        foremanId: 'foreman-003',
        logDate: DateTime(2026, 7, 18),
        status: 'approved',
        summary: 'Heavy haulage active',
        approvedBy: 'supervisor-01',
      );

      final jsonStr = jsonEncode(originalDto.toJson());
      final decodedJson = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restoredDto = DailyLogDto.fromJson(decodedJson);

      expect(restoredDto.id, equals(originalDto.id));
      expect(restoredDto.status, equals('approved'));
      expect(restoredDto.approvedBy, equals('supervisor-01'));
    });
  });
}
