import 'package:mine_flow/core/domain/entities/cut_fill_record_entity.dart';

/// Data Transfer Object (DTO) for [CutFillRecordEntity] handling JSON serialization
/// to and from Supabase `public.cut_fill_records` table.
///
/// v2: Maps bcm_volume and lcm_volume columns instead of cut_volume/fill_volume,
/// and maps material_type string.
class CutFillRecordModel extends CutFillRecordEntity {
  const CutFillRecordModel({
    required super.id,
    required super.siteId,
    super.dailyLogId,
    required super.zoneId,
    super.bcmVolume = 0.0,
    super.lcmVolume = 0.0,
    super.materialType,
    super.elevationChange,
    required super.measuredAt,
    super.measuredBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB.
  factory CutFillRecordModel.fromJson(Map<String, dynamic> json) {
    return CutFillRecordModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      dailyLogId: json['daily_log_id'] as String?,
      zoneId: json['zone_id'] as String,
      bcmVolume: (json['bcm_volume'] as num?)?.toDouble() ?? 0.0,
      lcmVolume: (json['lcm_volume'] as num?)?.toDouble() ?? 0.0,
      materialType: json['material_type'] as String?,
      elevationChange: (json['elevation_change'] as num?)?.toDouble(),
      measuredAt: json['measured_at'] != null
          ? DateTime.parse(json['measured_at'] as String)
          : DateTime.now(),
      measuredBy: json['measured_by'] as String?,
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
      if (dailyLogId != null) 'daily_log_id': dailyLogId,
      'zone_id': zoneId,
      'bcm_volume': bcmVolume,
      'lcm_volume': lcmVolume,
      if (materialType != null) 'material_type': materialType,
      if (elevationChange != null) 'elevation_change': elevationChange,
      'measured_at': measuredAt.toIso8601String(),
      if (measuredBy != null) 'measured_by': measuredBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  CutFillRecordEntity toDomain() {
    return CutFillRecordEntity(
      id: id,
      siteId: siteId,
      dailyLogId: dailyLogId,
      zoneId: zoneId,
      bcmVolume: bcmVolume,
      lcmVolume: lcmVolume,
      materialType: materialType,
      elevationChange: elevationChange,
      measuredAt: measuredAt,
      measuredBy: measuredBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  CutFillRecordEntity toEntity() => toDomain();

  /// Factory constructor from a domain entity.
  factory CutFillRecordModel.fromDomain(CutFillRecordEntity entity) {
    return CutFillRecordModel(
      id: entity.id,
      siteId: entity.siteId,
      dailyLogId: entity.dailyLogId,
      zoneId: entity.zoneId,
      bcmVolume: entity.bcmVolume,
      lcmVolume: entity.lcmVolume,
      materialType: entity.materialType,
      elevationChange: entity.elevationChange,
      measuredAt: entity.measuredAt,
      measuredBy: entity.measuredBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory CutFillRecordModel.fromEntity(CutFillRecordEntity entity) =>
      CutFillRecordModel.fromDomain(entity);
}
