import 'package:mine_flow/core/domain/entities/geospatial_file_entity.dart';

/// Data Transfer Object (DTO) for [GeospatialFileEntity] handling JSON serialization
/// to and from Supabase `public.geospatial_files` table.
class GeospatialFileModel extends GeospatialFileEntity {
  const GeospatialFileModel({
    required super.id,
    required super.siteId,
    super.zoneId,
    required super.fileName,
    required super.fileType,
    required super.driveFileId,
    super.driveWebViewLink,
    super.acquisitionDate,
    super.uploadedBy,
    super.metadata = const {},
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB.
  factory GeospatialFileModel.fromJson(Map<String, dynamic> json) {
    return GeospatialFileModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      zoneId: json['zone_id'] as String?,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      driveFileId: json['drive_file_id'] as String,
      driveWebViewLink: json['drive_web_view_link'] as String?,
      acquisitionDate: json['acquisition_date'] != null
          ? DateTime.tryParse(json['acquisition_date'] as String)
          : null,
      uploadedBy: json['uploaded_by'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Converts model into JSON map suitable for Supabase queries.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      if (zoneId != null) 'zone_id': zoneId,
      'file_name': fileName,
      'file_type': fileType,
      'drive_file_id': driveFileId,
      if (driveWebViewLink != null) 'drive_web_view_link': driveWebViewLink,
      if (acquisitionDate != null)
        'acquisition_date': acquisitionDate!.toIso8601String(),
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
      'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  GeospatialFileEntity toDomain() {
    return GeospatialFileEntity(
      id: id,
      siteId: siteId,
      zoneId: zoneId,
      fileName: fileName,
      fileType: fileType,
      driveFileId: driveFileId,
      driveWebViewLink: driveWebViewLink,
      acquisitionDate: acquisitionDate,
      uploadedBy: uploadedBy,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  GeospatialFileEntity toEntity() => toDomain();

  /// Factory constructor from a domain entity.
  factory GeospatialFileModel.fromDomain(GeospatialFileEntity entity) {
    return GeospatialFileModel(
      id: entity.id,
      siteId: entity.siteId,
      zoneId: entity.zoneId,
      fileName: entity.fileName,
      fileType: entity.fileType,
      driveFileId: entity.driveFileId,
      driveWebViewLink: entity.driveWebViewLink,
      acquisitionDate: entity.acquisitionDate,
      uploadedBy: entity.uploadedBy,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory GeospatialFileModel.fromEntity(GeospatialFileEntity entity) =>
      GeospatialFileModel.fromDomain(entity);
}
