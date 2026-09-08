import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/attendance/data/adapters/attendance_record_dto_adapter.dart';
import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

void main() {
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

  group('AttendanceStatus Enum', () {
    test('should parse string values correctly', () {
      expect(
        AttendanceStatus.fromString('present'),
        equals(AttendanceStatus.present),
      );
      expect(
        AttendanceStatus.fromString('absent'),
        equals(AttendanceStatus.absent),
      );
      expect(
        AttendanceStatus.fromString('sick'),
        equals(AttendanceStatus.sick),
      );
      expect(
        AttendanceStatus.fromString('leave'),
        equals(AttendanceStatus.leave),
      );
      expect(
        AttendanceStatus.fromString('PRESENT'),
        equals(AttendanceStatus.present),
      );
      expect(
        AttendanceStatus.fromString(null),
        equals(AttendanceStatus.present),
      );
      expect(
        AttendanceStatus.fromString('unknown'),
        equals(AttendanceStatus.present),
      );
    });

    test('should convert enum to value string', () {
      expect(AttendanceStatus.present.toValue(), equals('present'));
      expect(AttendanceStatus.absent.toValue(), equals('absent'));
      expect(AttendanceStatus.sick.toValue(), equals('sick'));
      expect(AttendanceStatus.leave.toValue(), equals('leave'));
    });
  });

  group('AttendanceRecord Domain Entity', () {
    final tRecord = AttendanceRecord(
      id: 'att-101',
      siteId: defaultSiteId,
      userId: 'user-001',
      date: DateTime(2026, 7, 18),
      status: AttendanceStatus.present,
      remarks: 'Morning shift',
      loggedBy: 'foreman-1',
    );

    test('should support copyWith method', () {
      final updated = tRecord.copyWith(
        status: AttendanceStatus.sick,
        remarks: 'Feeling unwell',
      );
      expect(updated.id, equals('att-101'));
      expect(updated.status, equals(AttendanceStatus.sick));
      expect(updated.remarks, equals('Feeling unwell'));
      expect(updated.userId, equals('user-001'));
    });

    test('should support value equality via Equatable', () {
      final tRecord2 = AttendanceRecord(
        id: 'att-101',
        siteId: defaultSiteId,
        userId: 'user-001',
        date: DateTime(2026, 7, 18),
        status: AttendanceStatus.present,
        remarks: 'Morning shift',
        loggedBy: 'foreman-1',
      );

      expect(tRecord, equals(tRecord2));
    });
  });

  group('AttendanceRecordDto & Mappers', () {
    final tJson = <String, dynamic>{
      'id': 'att-201',
      'site_id': defaultSiteId,
      'user_id': 'user-002',
      'date': '2026-07-18',
      'status': 'absent',
      'remarks': 'Unexcused',
      'logged_by': 'foreman-2',
      'created_at': '2026-07-18T08:00:00.000Z',
    };

    test('should parse JSON correctly into DTO', () {
      final dto = AttendanceRecordDto.fromJson(tJson);
      expect(dto.id, equals('att-201'));
      expect(dto.userId, equals('user-002'));
      expect(dto.status, equals('absent'));
      expect(dto.remarks, equals('Unexcused'));
    });

    test('should convert DTO to JSON map', () {
      final dto = AttendanceRecordDto.fromJson(tJson);
      final json = dto.toJson();
      expect(json['id'], equals('att-201'));
      expect(json['status'], equals('absent'));
      expect(json['date'], equals('2026-07-18'));
    });

    test('should map bidirectional between DTO and Domain Entity', () {
      final dto = AttendanceRecordDto.fromJson(tJson);
      final entity = dto.toDomain();
      expect(entity.id, equals(dto.id));
      expect(entity.status, equals(AttendanceStatus.absent));

      final convertedDto = AttendanceRecordDto.fromDomain(entity);
      expect(convertedDto.id, equals(dto.id));
      expect(convertedDto.status, equals(dto.status));
    });
  });

  group('AttendanceRecordDtoAdapter Hive Adapter', () {
    test('should write and read AttendanceRecordDto using adapter', () {
      final adapter = AttendanceRecordDtoAdapter();
      expect(adapter.typeId, equals(21));

      final originalDto = AttendanceRecordDto(
        id: 'att-301',
        siteId: defaultSiteId,
        userId: 'user-003',
        date: DateTime(2026, 7, 18),
        status: 'sick',
        remarks: 'Doctor note attached',
      );

      final jsonStr = jsonEncode(originalDto.toJson());
      final decodedJson = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restoredDto = AttendanceRecordDto.fromJson(decodedJson);

      expect(restoredDto.id, equals(originalDto.id));
      expect(restoredDto.status, equals('sick'));
      expect(restoredDto.remarks, equals('Doctor note attached'));
    });
  });
}
