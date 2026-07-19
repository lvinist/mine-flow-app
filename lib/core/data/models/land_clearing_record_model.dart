import 'package:mine_flow/core/domain/entities/land_clearing_record_entity.dart';

/// Data Transfer Object (DTO) for [LandClearingRecordEntity] handling JSON serialization
/// to and from Supabase `public.land_clearing_records` table.
class LandClearingRecordModel extends LandClearingRecordEntity {
  const LandClearingRecordModel({
    required super.id,
    required super.siteId,
    super.dailyLogId,
    required super.zoneId,
    super.areaClearedHa = 0.0,
    super.vegetationType,
    required super.clearedAt,
    super.clearedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB.
  factory LandClearingRecordModel.fromJson(Map<String, dynamic> json) {
    return LandClearingRecordModel(
      id: json['id'] as String,
      siteId: json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      dailyLogId: json['daily_log_id'] as String?,
      zoneId: json['zone_id'] as String,
      areaClearedHa: (json['area_cleared_ha'] as num?)?.toDouble() ?? 0.0,
      vegetationType: json['vegetation_type'] as String?,
      clearedAt: json['cleared_at'] != null
          ? DateTime.parse(json['cleared_at'] as String)
          : DateTime.now(),
      clearedBy: json['cleared_by'] as String?,
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
      'area_cleared_ha': areaClearedHa,
      if (vegetationType != null) 'vegetation_type': vegetationType,
      'cleared_at': clearedAt.toIso8601String(),
      if (clearedBy != null) 'cleared_by': clearedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  LandClearingRecordEntity toDomain() {
    return LandClearingRecordEntity(
      id: id,
      siteId: siteId,
      dailyLogId: dailyLogId,
      zoneId: zoneId,
      areaClearedHa: areaClearedHa,
      vegetationType: vegetationType,
      clearedAt: clearedAt,
      clearedBy: clearedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  LandClearingRecordEntity toEntity() => toDomain();

  /// Factory constructor from a domain entity.
  factory LandClearingRecordModel.fromDomain(LandClearingRecordEntity entity) {
    return LandClearingRecordModel(
      id: entity.id,
      siteId: entity.siteId,
      dailyLogId: entity.dailyLogId,
      zoneId: entity.zoneId,
      areaClearedHa: entity.areaClearedHa,
      vegetationType: entity.vegetationType,
      clearedAt: entity.clearedAt,
      clearedBy: entity.clearedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory LandClearingRecordModel.fromEntity(LandClearingRecordEntity entity) =>
      LandClearingRecordModel.fromDomain(entity);
}
