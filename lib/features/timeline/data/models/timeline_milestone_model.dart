import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';

/// Hive-compatible model for [TimelineMilestone].
///
/// Uses a manual TypeAdapter (typeId: 14) instead of build_runner.
/// All fields are stored as their serializable equivalents (enums as strings).
class TimelineMilestoneModel {
  final String id;
  final String siteId;
  final String? zoneId;
  final String title;
  final String? description;
  final String category;
  final double? targetValue;
  final double? actualValue;
  final DateTime? targetDate;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  TimelineMilestoneModel({
    required this.id,
    required this.siteId,
    this.zoneId,
    required this.title,
    this.description,
    required this.category,
    this.targetValue,
    this.actualValue,
    this.targetDate,
    required this.startDate,
    this.endDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory TimelineMilestoneModel.fromEntity(TimelineMilestone entity) {
    return TimelineMilestoneModel(
      id: entity.id,
      siteId: entity.siteId,
      zoneId: entity.zoneId,
      title: entity.title,
      description: entity.description,
      category: entity.category.name,
      targetValue: entity.targetValue,
      actualValue: entity.actualValue,
      targetDate: entity.targetDate,
      startDate: entity.startDate,
      endDate: entity.endDate,
      status: entity.status.name,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  TimelineMilestone toEntity() {
    return TimelineMilestone(
      id: id,
      siteId: siteId,
      zoneId: zoneId,
      title: title,
      description: description,
      category: TimelineCategory.values.firstWhere(
        (e) => e.name == category,
        orElse: () => TimelineCategory.general,
      ),
      targetValue: targetValue,
      actualValue: actualValue,
      targetDate: targetDate,
      startDate: startDate,
      endDate: endDate,
      status: MilestoneStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => MilestoneStatus.planned,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  factory TimelineMilestoneModel.fromJson(Map<String, dynamic> json) {
    return TimelineMilestoneModel(
      id: json['id'] as String,
      siteId: json['site_id'] as String,
      zoneId: json['zone_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: (json['category'] as String?) ?? 'general',
      targetValue: (json['target_value'] as num?)?.toDouble(),
      actualValue: (json['actual_value'] as num?)?.toDouble(),
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      status: (json['status'] as String?) ?? 'planned',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'zone_id': zoneId,
      'title': title,
      'description': description,
      'category': category,
      'target_value': targetValue,
      'actual_value': actualValue,
      'target_date': targetDate?.toIso8601String(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
