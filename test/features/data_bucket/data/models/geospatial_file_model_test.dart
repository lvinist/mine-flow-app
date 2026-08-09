import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/data_bucket/data/models/geospatial_file_model.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';

void main() {
  const defaultSiteId = '00000000-0000-0000-0000-000000000001';
  final fixedDate = DateTime(2026, 7, 18, 8, 0, 0);
  final fixedDateStr = fixedDate.toIso8601String();

  group('GeospatialFileModel Serialization', () {
    final tEntity = GeospatialFile(
      id: 'gf-001',
      siteId: defaultSiteId,
      zoneId: 'zone-north',
      fileName: 'survey_area_42.shp',
      fileType: '.shp',
      mimeType: 'application/octet-stream',
      driveFileId: 'drive-file-abc123',
      driveLink: 'https://drive.google.com/file/d/abc123/view',
      fileSizeBytes: 1048576,
      acquisitionDate: DateTime(2026, 7, 15),
      notes: 'Northern zone boundary survey',
      uploadedBy: 'user-001',
      createdAt: fixedDate,
      updatedAt: fixedDate,
    );

    test('fromDomain and toDomain should round-trip correctly', () {
      final model = GeospatialFileModel.fromDomain(tEntity);
      final domain = model.toDomain();

      expect(domain.id, equals(tEntity.id));
      expect(domain.fileName, equals('survey_area_42.shp'));
      expect(domain.fileType, equals('.shp'));
      expect(domain.fileSizeBytes, equals(1048576));
    });

    test('toJson and fromJson should round-trip correctly (snake_case)', () {
      final model = GeospatialFileModel.fromDomain(tEntity);
      final json = model.toJson();
      final restored = GeospatialFileModel.fromJson(json);

      expect(restored.id, equals('gf-001'));
      expect(restored.fileName, equals('survey_area_42.shp'));
      expect(restored.fileType, equals('.shp'));
      expect(restored.driveFileId, equals('drive-file-abc123'));
      expect(
        restored.driveLink,
        equals('https://drive.google.com/file/d/abc123/view'),
      );
      expect(restored.fileSizeBytes, equals(1048576));
    });

    test(
      'toHiveJson and fromHiveJson should round-trip correctly (camelCase)',
      () {
        final model = GeospatialFileModel.fromDomain(tEntity);
        final hiveJson = model.toHiveJson();
        final restored = GeospatialFileModel.fromHiveJson(hiveJson);

        expect(restored.id, equals('gf-001'));
        expect(restored.fileName, equals('survey_area_42.shp'));
        expect(restored.fileType, equals('.shp'));
        expect(restored.driveFileId, equals('drive-file-abc123'));
        expect(restored.fileSizeBytes, equals(1048576));
      },
    );

    test(
      'JSON serialization should preserve snake_case field name mapping',
      () {
        final model = GeospatialFileModel.fromDomain(tEntity);
        final json = model.toJson();

        expect(json['id'], equals('gf-001'));
        expect(json['site_id'], equals(defaultSiteId));
        expect(json['zone_id'], equals('zone-north'));
        expect(json['file_name'], equals('survey_area_42.shp'));
        expect(json['file_type'], equals('.shp'));
        expect(json['mime_type'], equals('application/octet-stream'));
        expect(json['drive_file_id'], equals('drive-file-abc123'));
        expect(
          json['drive_link'],
          equals('https://drive.google.com/file/d/abc123/view'),
        );
        expect(json['file_size_bytes'], equals(1048576));
        expect(json['acquisition_date'], equals('2026-07-15T00:00:00.000'));
        expect(json['notes'], equals('Northern zone boundary survey'));
        expect(json['uploaded_by'], equals('user-001'));
        expect(json['created_at'], equals(fixedDateStr));
        expect(json['updated_at'], equals(fixedDateStr));
      },
    );

    test('Hive JSON serialization should preserve camelCase field names', () {
      final model = GeospatialFileModel.fromDomain(tEntity);
      final hiveJson = model.toHiveJson();

      expect(hiveJson['id'], equals('gf-001'));
      expect(hiveJson['siteId'], equals(defaultSiteId));
      expect(hiveJson['zoneId'], equals('zone-north'));
      expect(hiveJson['fileName'], equals('survey_area_42.shp'));
      expect(hiveJson['fileType'], equals('.shp'));
      expect(hiveJson['mimeType'], equals('application/octet-stream'));
      expect(hiveJson['driveFileId'], equals('drive-file-abc123'));
      expect(
        hiveJson['driveLink'],
        equals('https://drive.google.com/file/d/abc123/view'),
      );
      expect(hiveJson['fileSizeBytes'], equals(1048576));
      expect(hiveJson['acquisitionDate'], equals('2026-07-15T00:00:00.000'));
      expect(hiveJson['notes'], equals('Northern zone boundary survey'));
      expect(hiveJson['uploadedBy'], equals('user-001'));
      expect(hiveJson['createdAt'], equals(fixedDateStr));
      expect(hiveJson['updatedAt'], equals(fixedDateStr));
    });

    test('should handle minimal record with only required fields', () {
      final minimal = GeospatialFileModel(
        id: 'gf-minimal',
        siteId: defaultSiteId,
        fileName: 'basic.tiff',
        fileType: '.tiff',
        driveFileId: 'drive-minimal',
        driveLink: 'https://drive.google.com/file/d/minimal/view',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );

      final json = minimal.toJson();
      expect(json['file_name'], equals('basic.tiff'));
      expect(json['file_size_bytes'], isNull);

      final restored = GeospatialFileModel.fromJson(json);
      expect(restored.id, equals('gf-minimal'));
      expect(restored.fileName, equals('basic.tiff'));
      expect(restored.fileSizeBytes, isNull);
    });

    test('fromJson should handle null optional fields gracefully', () {
      final model = GeospatialFileModel.fromJson({
        'id': 'gf-null-fields',
        'site_id': defaultSiteId,
        'file_name': 'test.dxf',
        'file_type': '.dxf',
        'drive_file_id': 'drive-null',
        'drive_link': 'https://drive.google.com/file/d/null/view',
        'created_at': fixedDateStr,
        'updated_at': fixedDateStr,
      });

      expect(model.zoneId, isNull);
      expect(model.mimeType, isNull);
      expect(model.fileSizeBytes, isNull);
      expect(model.acquisitionDate, isNull);
      expect(model.notes, isNull);
      expect(model.uploadedBy, isNull);
    });

    test('Hive round-trip preserves null optional fields', () {
      final model = GeospatialFileModel(
        id: 'gf-null-hive',
        siteId: defaultSiteId,
        fileName: 'test.csv',
        fileType: '.csv',
        driveFileId: 'drive-null-hive',
        driveLink: 'https://drive.google.com/file/d/nul-hive/view',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );

      final hiveJson = model.toHiveJson();
      final restored = GeospatialFileModel.fromHiveJson(hiveJson);

      expect(restored.zoneId, isNull);
      expect(restored.fileSizeBytes, isNull);
      expect(restored.acquisitionDate, isNull);
      expect(restored.notes, isNull);
    });
  });
}
