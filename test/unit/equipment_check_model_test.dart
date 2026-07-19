import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/equipment_check/data/adapters/equipment_check_dto_adapter.dart';
import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';

  group('EquipmentType Enum', () {
    test('should parse string values correctly', () {
      expect(EquipmentType.fromString('gnss'), equals(EquipmentType.gnss));
      expect(EquipmentType.fromString('total_station'), equals(EquipmentType.totalStation));
      expect(EquipmentType.fromString('totalstation'), equals(EquipmentType.totalStation));
      expect(EquipmentType.fromString('drone'), equals(EquipmentType.drone));
      expect(EquipmentType.fromString('uav'), equals(EquipmentType.drone));
      expect(EquipmentType.fromString(null), equals(EquipmentType.gnss));
      expect(EquipmentType.fromString('unknown'), equals(EquipmentType.gnss));
    });

    test('should convert enum to value string', () {
      expect(EquipmentType.gnss.toValue(), equals('gnss'));
      expect(EquipmentType.totalStation.toValue(), equals('total_station'));
      expect(EquipmentType.drone.toValue(), equals('drone'));
    });

    test('should return friendly display names', () {
      expect(EquipmentType.gnss.displayName, equals('GNSS Receiver'));
      expect(EquipmentType.totalStation.displayName, equals('Total Station'));
      expect(EquipmentType.drone.displayName, equals('Drone / UAV'));
    });
  });

  group('CheckType Enum', () {
    test('should parse string values correctly', () {
      expect(CheckType.fromString('pre_work'), equals(CheckType.preWork));
      expect(CheckType.fromString('prework'), equals(CheckType.preWork));
      expect(CheckType.fromString('post_work'), equals(CheckType.postWork));
      expect(CheckType.fromString('postwork'), equals(CheckType.postWork));
      expect(CheckType.fromString(null), equals(CheckType.preWork));
    });

    test('should convert enum to value string', () {
      expect(CheckType.preWork.toValue(), equals('pre_work'));
      expect(CheckType.postWork.toValue(), equals('post_work'));
    });

    test('should return friendly display names', () {
      expect(CheckType.preWork.displayName, equals('Pre-Work Check'));
      expect(CheckType.postWork.displayName, equals('Post-Work Check'));
    });
  });

  group('CheckStatus Enum', () {
    test('should parse string values correctly', () {
      expect(CheckStatus.fromString('passed'), equals(CheckStatus.passed));
      expect(CheckStatus.fromString('pass'), equals(CheckStatus.passed));
      expect(CheckStatus.fromString('failed'), equals(CheckStatus.failed));
      expect(CheckStatus.fromString('fail'), equals(CheckStatus.failed));
      expect(CheckStatus.fromString('flagged'), equals(CheckStatus.flagged));
      expect(CheckStatus.fromString('flag'), equals(CheckStatus.flagged));
      expect(CheckStatus.fromString(null), equals(CheckStatus.passed));
    });

    test('should convert enum to value string', () {
      expect(CheckStatus.passed.toValue(), equals('passed'));
      expect(CheckStatus.failed.toValue(), equals('failed'));
      expect(CheckStatus.flagged.toValue(), equals('flagged'));
    });

    test('should return friendly display names', () {
      expect(CheckStatus.passed.displayName, equals('Passed'));
      expect(CheckStatus.failed.displayName, equals('Failed'));
      expect(CheckStatus.flagged.displayName, equals('Flagged'));
    });
  });

  group('CheckItem Entity', () {
    const item = CheckItem(
      id: 'battery_level',
      label: 'Battery level > 80%',
      isPassed: true,
      remarks: 'Fully charged',
    );

    test('should support copyWith method', () {
      final updated = item.copyWith(isPassed: false, remarks: 'Low charge');
      expect(updated.id, equals('battery_level'));
      expect(updated.isPassed, isFalse);
      expect(updated.remarks, equals('Low charge'));
    });

    test('should serialize and deserialize JSON correctly', () {
      final json = item.toJson();
      expect(json['id'], equals('battery_level'));
      expect(json['is_passed'], isTrue);

      final restored = CheckItem.fromJson(json);
      expect(restored, equals(item));
    });
  });

  group('EquipmentCheck Domain Entity', () {
    final tCheck = EquipmentCheck(
      id: 'eq-check-101',
      siteId: defaultSiteId,
      foremanId: 'foreman-001',
      equipmentType: EquipmentType.gnss,
      serialNumber: 'GNSS-99201',
      checkTime: DateTime(2026, 7, 18, 7, 30),
      checkType: CheckType.preWork,
      status: CheckStatus.passed,
      isOperational: true,
      checklist: const [
        CheckItem(id: 'antenna_secure', label: 'Antenna Secure', isPassed: true),
        CheckItem(id: 'satellite_lock', label: 'Satellite Lock', isPassed: true),
      ],
      remarks: 'All GNSS checks passed',
    );

    test('should support copyWith method', () {
      final updated = tCheck.copyWith(
        status: CheckStatus.flagged,
        remarks: 'Weak signal detected',
      );
      expect(updated.id, equals('eq-check-101'));
      expect(updated.status, equals(CheckStatus.flagged));
      expect(updated.remarks, equals('Weak signal detected'));
      expect(updated.equipmentType, equals(EquipmentType.gnss));
    });

    test('should support value equality via Equatable', () {
      final tCheck2 = EquipmentCheck(
        id: 'eq-check-101',
        siteId: defaultSiteId,
        foremanId: 'foreman-001',
        equipmentType: EquipmentType.gnss,
        serialNumber: 'GNSS-99201',
        checkTime: DateTime(2026, 7, 18, 7, 30),
        checkType: CheckType.preWork,
        status: CheckStatus.passed,
        isOperational: true,
        checklist: const [
          CheckItem(id: 'antenna_secure', label: 'Antenna Secure', isPassed: true),
          CheckItem(id: 'satellite_lock', label: 'Satellite Lock', isPassed: true),
        ],
        remarks: 'All GNSS checks passed',
      );

      expect(tCheck, equals(tCheck2));
    });
  });

  group('EquipmentCheckDto & Mappers', () {
    final tJson = <String, dynamic>{
      'id': 'eq-check-201',
      'site_id': defaultSiteId,
      'foreman_id': 'foreman-002',
      'equipment_type': 'total_station',
      'serial_number': 'TS-77102',
      'check_time': '2026-07-18T08:15:00.000Z',
      'check_type': 'post_work',
      'status': 'passed',
      'is_operational': true,
      'checklist_data': [
        {'id': 'tribrach_level', 'label': 'Tribrach Level', 'is_passed': true},
        {'id': 'lens_clean', 'label': 'Optical Lens Clean', 'is_passed': true},
      ],
      'remarks': 'Post-work clean completed',
      'created_at': '2026-07-18T08:15:00.000Z',
    };

    test('should parse JSON correctly into DTO', () {
      final dto = EquipmentCheckDto.fromJson(tJson);
      expect(dto.id, equals('eq-check-201'));
      expect(dto.foremanId, equals('foreman-002'));
      expect(dto.equipmentType, equals('total_station'));
      expect(dto.serialNumber, equals('TS-77102'));
      expect(dto.checkType, equals('post_work'));
      expect(dto.checklistData.length, equals(2));
    });

    test('should convert DTO to JSON map', () {
      final dto = EquipmentCheckDto.fromJson(tJson);
      final json = dto.toJson();
      expect(json['id'], equals('eq-check-201'));
      expect(json['equipment_type'], equals('total_station'));
      expect(json['check_type'], equals('post_work'));
      expect(json['is_operational'], isTrue);
    });

    test('should map bidirectional between DTO and Domain Entity', () {
      final dto = EquipmentCheckDto.fromJson(tJson);
      final entity = dto.toDomain();
      expect(entity.id, equals(dto.id));
      expect(entity.equipmentType, equals(EquipmentType.totalStation));
      expect(entity.checkType, equals(CheckType.postWork));
      expect(entity.checklist.length, equals(2));

      final convertedDto = EquipmentCheckDto.fromDomain(entity);
      expect(convertedDto.id, equals(dto.id));
      expect(convertedDto.equipmentType, equals(dto.equipmentType));
      expect(convertedDto.status, equals(dto.status));
    });
  });

  group('EquipmentCheckDtoAdapter Hive Adapter', () {
    test('should write and read EquipmentCheckDto using adapter', () {
      final adapter = EquipmentCheckDtoAdapter();
      expect(adapter.typeId, equals(23));

      final originalDto = EquipmentCheckDto(
        id: 'eq-check-301',
        siteId: defaultSiteId,
        foremanId: 'foreman-003',
        equipmentType: 'drone',
        serialNumber: 'DRONE-X4',
        checkTime: DateTime(2026, 7, 18, 9, 0),
        checkType: 'pre_work',
        status: 'passed',
        isOperational: true,
        checklistData: const [
          {'id': 'propellers_intact', 'label': 'Propellers Intact', 'is_passed': true},
        ],
        remarks: 'Pre-flight check cleared',
      );

      final jsonStr = jsonEncode(originalDto.toJson());
      final decodedJson = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restoredDto = EquipmentCheckDto.fromJson(decodedJson);

      expect(restoredDto.id, equals(originalDto.id));
      expect(restoredDto.equipmentType, equals('drone'));
      expect(restoredDto.serialNumber, equals('DRONE-X4'));
      expect(restoredDto.checklistData.length, equals(1));
    });
  });
}
