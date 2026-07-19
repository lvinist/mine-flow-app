import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';

/// Data model for [GeospatialFile] providing JSON serialization to/from Supabase.
///
/// Maps between `snake_case` (database columns) and `camelCase` (Dart conventions).
/// Also provides Hive-friendly JSON serialization for offline caching.
class GeospatialFileModel {
  final String id;
  final String siteId;
  final String? zoneId;
  final String fileName;
  final String fileType;
  final String? mimeType;
  final String driveFileId;
  final String driveLink;
  final int? fileSizeBytes;
  final double? latitude;
  final double? longitude;
  final DateTime? acquisitionDate;
  final String? notes;
  final String? uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeospatialFileModel({
    required this.id,
    required this.siteId,
    this.zoneId,
    required this.fileName,
    required this.fileType,
    this.mimeType,
    required this.driveFileId,
    required this.driveLink,
    this.fileSizeBytes,
    this.latitude,
    this.longitude,
    this.acquisitionDate,
    this.notes,
    this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to deserialize from Supabase JSON (snake_case).
  factory GeospatialFileModel.fromJson(Map<String, dynamic> json) {
    return GeospatialFileModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      zoneId: json['zone_id'] as String?,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      mimeType: json['mime_type'] as String?,
      driveFileId: json['drive_file_id'] as String,
      driveLink:
          json['drive_link'] as String? ??
          json['drive_web_view_link'] as String? ??
          '',
      fileSizeBytes: json['file_size_bytes'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      acquisitionDate: json['acquisition_date'] != null
          ? DateTime.tryParse(json['acquisition_date'] as String)
          : null,
      notes: json['notes'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Serializes to JSON map (snake_case) suitable for Supabase operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      if (zoneId != null) 'zone_id': zoneId,
      'file_name': fileName,
      'file_type': fileType,
      if (mimeType != null) 'mime_type': mimeType,
      'drive_file_id': driveFileId,
      'drive_link': driveLink,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (acquisitionDate != null)
        'acquisition_date': acquisitionDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Serializes to a JSON map suitable for Hive offline cache storage.
  /// Uses camelCase keys for consistency with Dart conventions.
  Map<String, dynamic> toHiveJson() {
    return {
      'id': id,
      'siteId': siteId,
      'zoneId': zoneId,
      'fileName': fileName,
      'fileType': fileType,
      'mimeType': mimeType,
      'driveFileId': driveFileId,
      'driveLink': driveLink,
      'fileSizeBytes': fileSizeBytes,
      'latitude': latitude,
      'longitude': longitude,
      'acquisitionDate': acquisitionDate?.toIso8601String(),
      'notes': notes,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Factory constructor to deserialize from Hive JSON (camelCase).
  factory GeospatialFileModel.fromHiveJson(Map<String, dynamic> json) {
    return GeospatialFileModel(
      id: json['id'] as String,
      siteId: json['siteId'] as String,
      zoneId: json['zoneId'] as String?,
      fileName: json['fileName'] as String,
      fileType: json['fileType'] as String,
      mimeType: json['mimeType'] as String?,
      driveFileId: json['driveFileId'] as String,
      driveLink: json['driveLink'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      acquisitionDate: json['acquisitionDate'] != null
          ? DateTime.tryParse(json['acquisitionDate'] as String)
          : null,
      notes: json['notes'] as String?,
      uploadedBy: json['uploadedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts this model to a domain [GeospatialFile].
  GeospatialFile toDomain() {
    return GeospatialFile(
      id: id,
      siteId: siteId,
      zoneId: zoneId,
      fileName: fileName,
      fileType: fileType,
      mimeType: mimeType,
      driveFileId: driveFileId,
      driveLink: driveLink,
      fileSizeBytes: fileSizeBytes,
      latitude: latitude,
      longitude: longitude,
      acquisitionDate: acquisitionDate,
      notes: notes,
      uploadedBy: uploadedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Factory constructor from a domain [GeospatialFile].
  factory GeospatialFileModel.fromDomain(GeospatialFile entity) {
    return GeospatialFileModel(
      id: entity.id,
      siteId: entity.siteId,
      zoneId: entity.zoneId,
      fileName: entity.fileName,
      fileType: entity.fileType,
      mimeType: entity.mimeType,
      driveFileId: entity.driveFileId,
      driveLink: entity.driveLink,
      fileSizeBytes: entity.fileSizeBytes,
      latitude: entity.latitude,
      longitude: entity.longitude,
      acquisitionDate: entity.acquisitionDate,
      notes: entity.notes,
      uploadedBy: entity.uploadedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
