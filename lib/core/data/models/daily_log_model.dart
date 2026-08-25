import 'package:mine_flow/core/domain/entities/daily_log_entity.dart';

/// Data Transfer Object (DTO) for [DailyLogEntity] handling JSON serialization
/// to and from Supabase `public.daily_logs` table.
class DailyLogModel extends DailyLogEntity {
  const DailyLogModel({
    required super.id,
    required super.siteId,
    required super.foremanId,
    required super.logDate,
    super.zoneId,
    super.status = 'draft',
    super.summary,
    super.weather,
    super.notes,
    super.approvedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB.
  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      foremanId: json['foreman_id'] as String,
      logDate: json['log_date'] != null
          ? DateTime.parse(json['log_date'] as String)
          : DateTime.now(),
      zoneId: json['zone_id'] as String?,
      status: json['status'] as String? ?? 'draft',
      summary: json['summary'] as String?,
      weather: json['weather'] as String?,
      notes: json['notes'] as String?,
      approvedBy: json['approved_by'] as String?,
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
      'foreman_id': foremanId,
      'log_date': logDate.toIso8601String().split('T').first,
      if (zoneId != null) 'zone_id': zoneId,
      'status': status,
      if (summary != null) 'summary': summary,
      if (weather != null) 'weather': weather,
      if (notes != null) 'notes': notes,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  DailyLogEntity toDomain() {
    return DailyLogEntity(
      id: id,
      siteId: siteId,
      foremanId: foremanId,
      logDate: logDate,
      zoneId: zoneId,
      status: status,
      summary: summary,
      weather: weather,
      notes: notes,
      approvedBy: approvedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  DailyLogEntity toEntity() => toDomain();

  /// Factory constructor from a domain entity.
  factory DailyLogModel.fromDomain(DailyLogEntity entity) {
    return DailyLogModel(
      id: entity.id,
      siteId: entity.siteId,
      foremanId: entity.foremanId,
      logDate: entity.logDate,
      zoneId: entity.zoneId,
      status: entity.status,
      summary: entity.summary,
      weather: entity.weather,
      notes: entity.notes,
      approvedBy: entity.approvedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory DailyLogModel.fromEntity(DailyLogEntity entity) =>
      DailyLogModel.fromDomain(entity);
}
