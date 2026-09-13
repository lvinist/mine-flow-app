import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Data Transfer Object (DTO) for [DailyLog] handling JSON serialization
/// to and from Supabase `public.daily_logs` table and local Hive caching.
class DailyLogDto {
  final String id;
  final String siteId;
  final String foremanId;
  final DateTime logDate;
  final String? zoneId;
  final String status;
  final String? summary;
  final String? weather;
  final String? notes;
  final String hazardState;
  final String? hazardSeverity;
  final String? hazardNotes;
  final String? hazardAction;
  final String? approvedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const DailyLogDto({
    required this.id,
    required this.siteId,
    required this.foremanId,
    required this.logDate,
    this.zoneId,
    required this.status,
    this.summary,
    this.weather,
    this.notes,
    this.hazardState = 'not_assessed',
    this.hazardSeverity,
    this.hazardNotes,
    this.hazardAction,
    this.approvedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Deserializes JSON map from Supabase or local storage.
  factory DailyLogDto.fromJson(Map<String, dynamic> json) {
    final rawLogDate = json['log_date'] as String?;
    return DailyLogDto(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      foremanId: json['foreman_id'] as String,
      logDate: rawLogDate != null
          ? DateTime.tryParse(rawLogDate) ?? DateTime.now()
          : DateTime.now(),
      zoneId: json['zone_id'] as String?,
      status: json['status'] as String? ?? 'draft',
      summary: json['summary'] as String?,
      weather: json['weather'] as String?,
      notes: json['notes'] as String?,
      hazardState: json['hazard_state'] as String? ?? 'not_assessed',
      hazardSeverity: json['hazard_severity'] as String?,
      hazardNotes: json['hazard_notes'] as String?,
      hazardAction: json['hazard_action'] as String?,
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

  /// Serializes DTO into JSON map for Supabase query or local sync payload.
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
      'hazard_state': hazardState,
      'hazard_severity': hazardSeverity,
      'hazard_notes': hazardNotes,
      'hazard_action': hazardAction,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Maps DTO into domain entity [DailyLog].
  DailyLog toDomain() {
    return DailyLog(
      id: id,
      siteId: siteId,
      foremanId: foremanId,
      logDate: logDate,
      zoneId: zoneId,
      status: LogStatus.fromString(status),
      summary: summary,
      weather: weather,
      notes: notes,
      hazard: HazardAssessment(
        state: HazardStateValue.fromString(hazardState),
        severity: HazardSeverityValue.fromString(hazardSeverity),
        notes: hazardNotes,
        correctiveAction: hazardAction,
      ).normalized(),
      approvedBy: approvedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Creates DTO from domain entity [DailyLog].
  factory DailyLogDto.fromDomain(DailyLog entity) {
    return DailyLogDto(
      id: entity.id,
      siteId: entity.siteId,
      foremanId: entity.foremanId,
      logDate: entity.logDate,
      zoneId: entity.zoneId,
      status: entity.status.toValue(),
      summary: entity.summary,
      weather: entity.weather,
      notes: entity.notes,
      hazardState: entity.hazard.state.toValue(),
      hazardSeverity: entity.hazard.severity?.toValue(),
      hazardNotes: entity.hazard.normalized().notes,
      hazardAction: entity.hazard.normalized().correctiveAction,
      approvedBy: entity.approvedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }
}
