import 'package:mine_flow/core/domain/entities/cut_fill_record_entity.dart';

/// Data Transfer Object (DTO) for [CutFillRecordEntity] handling JSON serialization
/// to and from Supabase `public.cut_fill_records` table.
class CutFillRecordModel extends CutFillRecordEntity {
  const CutFillRecordModel({
    required super.id,
    required super.siteId,
    super.dailyLogId,
    required super.zoneId,
    super.cutVolume = 0.0,
    super.fillVolume = 0.0,
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
      siteId: json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      dailyLogId: json['daily_log_id'] as String?,
      zoneId: json['zone_id'] as String,
      cutVolume: (json['cut_volume'] as num?)?.toDouble() ?? 0.0,
      fillVolume: (json['fill_volume'] as num?)?.toDouble() ?? 0.0,
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
      'cut_volume': cutVolume,
      'fill_volume': fillVolume,
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
      cutVolume: cutVolume,
      fillVolume: fillVolume,
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
      cutVolume: entity.cutVolume,
      fillVolume: entity.fillVolume,
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
