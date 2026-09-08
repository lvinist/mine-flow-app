import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/data/models/models.dart';
import 'package:mine_flow/core/domain/entities/entities.dart';

void main() {
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

  group('UserModel & UserEntity', () {
    final tUserJson = <String, dynamic>{
      'id': 'user-uuid-1',
      'email': 'foreman@mineflow.com',
      'name': 'Budi Santoso',
      'role': 'foreman',
      'site_id': defaultSiteId,
      'phone': '08123456789',
      'national_id': '3171000000000001',
      'birthdate': '1990-05-15',
      'gender': 'Male',
      'emergency_contact_name': 'Siti',
      'emergency_contact_phone': '08199999999',
      'is_active': true,
      'created_at': '2026-07-18T10:00:00.000Z',
      'updated_at': '2026-07-18T10:00:00.000Z',
    };

    final tUserEntity = UserEntity(
      id: 'user-uuid-1',
      email: 'foreman@mineflow.com',
      name: 'Budi Santoso',
      role: 'foreman',
      siteId: defaultSiteId,
      phone: '08123456789',
      nationalId: '3171000000000001',
      birthdate: DateTime(1990, 5, 15),
      gender: 'Male',
      emergencyContactName: 'Siti',
      emergencyContactPhone: '08199999999',
      isActive: true,
      createdAt: DateTime.parse('2026-07-18T10:00:00.000Z'),
      updatedAt: DateTime.parse('2026-07-18T10:00:00.000Z'),
    );

    test('should parse JSON correctly into UserModel', () {
      final model = UserModel.fromJson(tUserJson);
      expect(model.id, equals('user-uuid-1'));
      expect(model.role, equals('foreman'));
      expect(model.isForeman, isTrue);
      expect(model.isSupervisor, isFalse);
    });

    test('should convert UserModel to JSON map', () {
      final model = UserModel.fromJson(tUserJson);
      final json = model.toJson();
      expect(json['id'], equals('user-uuid-1'));
      expect(json['email'], equals('foreman@mineflow.com'));
      expect(json['role'], equals('foreman'));
      expect(json['national_id'], equals('3171000000000001'));
    });

    test('should convert to and from UserEntity cleanly', () {
      final model = UserModel.fromDomain(tUserEntity);
      expect(model.toDomain(), equals(tUserEntity));
    });
  });

  group('ZoneModel & ZoneEntity', () {
    final tZoneJson = <String, dynamic>{
      'id': 'zone-uuid-1',
      'site_id': defaultSiteId,
      'name': 'PIT Rusia',
      'category': 'Mining Pit',
      'description': 'Main active extraction area',
      'created_at': '2026-07-18T10:00:00.000Z',
    };

    test('should parse JSON and convert to domain', () {
      final model = ZoneModel.fromJson(tZoneJson);
      expect(model.name, equals('PIT Rusia'));
      expect(model.category, equals('Mining Pit'));
      expect(model.siteId, equals(defaultSiteId));

      final entity = model.toDomain();
      expect(entity, isA<ZoneEntity>());
      expect(ZoneModel.fromDomain(entity), equals(model));
    });
  });

  group('AttendanceRecordModel & AttendanceRecordEntity', () {
    final tAttendanceJson = <String, dynamic>{
      'id': 'att-uuid-1',
      'site_id': defaultSiteId,
      'user_id': 'user-uuid-1',
      'date': '2026-07-18',
      'status': 'present',
      'remarks': 'On time',
      'logged_by': 'supervisor-uuid-1',
      'created_at': '2026-07-18T06:00:00.000Z',
    };

    test('should parse JSON and serialize back', () {
      final model = AttendanceRecordModel.fromJson(tAttendanceJson);
      expect(model.userId, equals('user-uuid-1'));
      expect(model.status, equals('present'));

      final json = model.toJson();
      expect(json['date'], equals('2026-07-18'));
      expect(json['status'], equals('present'));

      final entity = model.toDomain();
      expect(AttendanceRecordModel.fromDomain(entity), equals(model));
    });
  });

  group('EquipmentCheckModel & EquipmentCheckEntity', () {
    final tCheckJson = <String, dynamic>{
      'id': 'check-uuid-1',
      'site_id': defaultSiteId,
      'foreman_id': 'foreman-uuid-1',
      'equipment_type': 'gnss',
      'serial_number': 'GNSS-99201',
      'check_time': '2026-07-18T07:00:00.000Z',
      'check_type': 'pre_work',
      'is_operational': true,
      'checklist_data': {'satellite_lock': true, 'battery_pct': 95},
      'remarks': 'Good condition',
    };

    test('should parse JSON and handle checklist map', () {
      final model = EquipmentCheckModel.fromJson(tCheckJson);
      expect(model.equipmentType, equals('gnss'));
      expect(model.isOperational, isTrue);
      expect(model.checklistData['satellite_lock'], isTrue);

      final json = model.toJson();
      expect(json['equipment_type'], equals('gnss'));
      expect(json['checklist_data'], isA<Map>());

      final entity = model.toDomain();
      expect(EquipmentCheckModel.fromDomain(entity), equals(model));
    });
  });

  group('DailyLogModel & DailyLogEntity', () {
    final tLogJson = <String, dynamic>{
      'id': 'log-uuid-1',
      'site_id': defaultSiteId,
      'foreman_id': 'foreman-uuid-1',
      'log_date': '2026-07-18',
      'zone_id': 'zone-uuid-1',
      'status': 'submitted',
      'summary': 'Completed 500m3 excavation',
      'weather': 'Sunny',
      'notes': 'No delays reported',
    };

    test('should parse JSON and support status enums', () {
      final model = DailyLogModel.fromJson(tLogJson);
      expect(model.foremanId, equals('foreman-uuid-1'));
      expect(model.status, equals('submitted'));
      expect(model.weather, equals('Sunny'));

      final json = model.toJson();
      expect(json['status'], equals('submitted'));

      final entity = model.toDomain();
      expect(DailyLogModel.fromDomain(entity), equals(model));
    });
  });

  group('CutFillRecordModel & CutFillRecordEntity', () {
    final tCutFillJson = <String, dynamic>{
      'id': 'cf-uuid-1',
      'site_id': defaultSiteId,
      'daily_log_id': 'log-uuid-1',
      'zone_id': 'zone-uuid-1',
      'bcm_volume': 450.50,
      'lcm_volume': 120.25,
      'elevation_change': -0.85,
      'measured_at': '2026-07-18T12:00:00.000Z',
      'measured_by': 'surveyor-uuid-1',
    };

    test('should parse volume double values and serialize cleanly', () {
      final model = CutFillRecordModel.fromJson(tCutFillJson);
      expect(model.bcmVolume, equals(450.50));
      expect(model.lcmVolume, equals(120.25));
      expect(model.elevationChange, equals(-0.85));

      final json = model.toJson();
      expect(json['bcm_volume'], equals(450.50));

      final entity = model.toDomain();
      expect(CutFillRecordModel.fromDomain(entity), equals(model));
    });
  });

  group('LandClearingRecordModel & LandClearingRecordEntity', () {
    final tLandClearingJson = <String, dynamic>{
      'id': 'lc-uuid-1',
      'site_id': defaultSiteId,
      'daily_log_id': 'log-uuid-1',
      'zone_id': 'zone-uuid-1',
      'plan_area': 27500.0,
      'actual_area': 0.0,
      'method': 'Secondary Forest',
      'cleared_at': '2026-07-18T14:00:00.000Z',
      'cleared_by': 'foreman-uuid-1',
    };

    test('should parse area cleared and vegetation type', () {
      final model = LandClearingRecordModel.fromJson(tLandClearingJson);
      expect(model.planArea, equals(27500.0));
      expect(model.method, equals('Secondary Forest'));

      final json = model.toJson();
      expect(json['plan_area'], equals(27500.0));

      final entity = model.toDomain();
      expect(LandClearingRecordModel.fromDomain(entity), equals(model));
    });
  });

  group('InventoryItemModel & InventoryItemEntity', () {
    final tInventoryJson = <String, dynamic>{
      'id': 'inv-uuid-1',
      'site_id': defaultSiteId,
      'name': 'Diesel Fuel',
      'sku': 'DSL-001',
      'category': 'Fuel & Oil',
      'quantity': 5000.00,
      'unit': 'liters',
      'min_threshold': 1000.00,
    };

    test('should parse inventory item quantities and units', () {
      final model = InventoryItemModel.fromJson(tInventoryJson);
      expect(model.name, equals('Diesel Fuel'));
      expect(model.quantity, equals(5000.00));
      expect(model.unit, equals('liters'));

      final json = model.toJson();
      expect(json['quantity'], equals(5000.00));

      final entity = model.toDomain();
      expect(InventoryItemModel.fromDomain(entity), equals(model));
    });
  });

  group('GeospatialFileModel & GeospatialFileEntity', () {
    final tGeoFileJson = <String, dynamic>{
      'id': 'geo-uuid-1',
      'site_id': defaultSiteId,
      'zone_id': 'zone-uuid-1',
      'file_name': 'pit_rusia_topography_20260718.tiff',
      'file_type': '.tiff',
      'drive_file_id': 'google-drive-file-id-9981',
      'drive_web_view_link': 'https://drive.google.com/file/d/9981/view',
      'acquisition_date': '2026-07-18T08:00:00.000Z',
      'uploaded_by': 'surveyor-uuid-1',
      'metadata': {'resolution_cm': 5, 'sensor': 'Phantom 4 RTK'},
    };

    test('should parse geospatial file metadata and drive links', () {
      final model = GeospatialFileModel.fromJson(tGeoFileJson);
      expect(model.fileName, equals('pit_rusia_topography_20260718.tiff'));
      expect(model.driveFileId, equals('google-drive-file-id-9981'));
      expect(model.metadata['resolution_cm'], equals(5));

      final json = model.toJson();
      expect(json['drive_file_id'], equals('google-drive-file-id-9981'));

      final entity = model.toDomain();
      expect(GeospatialFileModel.fromDomain(entity), equals(model));
    });
  });
}
