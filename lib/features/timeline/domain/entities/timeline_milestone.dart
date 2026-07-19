import 'package:equatable/equatable.dart';

/// Category of timeline milestone — which tracked domain it belongs to.
enum TimelineCategory { cutFill, landClearing, general }

/// Current progress status of a milestone.
enum MilestoneStatus { planned, inProgress, completed, overdue }

/// A milestone on the work timeline — a planned vs. actual goal.
///
/// Each milestone belongs to a site (and optionally a zone) and tracks
/// progress toward a target value (e.g. cut 50 000 m³ by 15 April).
class TimelineMilestone extends Equatable {
  final String id;
  final String siteId;
  final String? zoneId;
  final String title;
  final String? description;
  final TimelineCategory category;
  final double? targetValue;
  final double? actualValue;
  final DateTime? targetDate;
  final DateTime startDate;
  final DateTime? endDate;
  final MilestoneStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const TimelineMilestone({
    required this.id,
    required this.siteId,
    this.zoneId,
    required this.title,
    this.description,
    this.category = TimelineCategory.general,
    this.targetValue,
    this.actualValue,
    this.targetDate,
    required this.startDate,
    this.endDate,
    this.status = MilestoneStatus.planned,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  TimelineMilestone copyWith({
    String? id,
    String? siteId,
    String? zoneId,
    String? title,
    String? description,
    TimelineCategory? category,
    double? targetValue,
    double? actualValue,
    DateTime? targetDate,
    DateTime? startDate,
    DateTime? endDate,
    MilestoneStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TimelineMilestone(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      zoneId: zoneId ?? this.zoneId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      actualValue: actualValue ?? this.actualValue,
      targetDate: targetDate ?? this.targetDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    siteId,
    zoneId,
    title,
    description,
    category,
    targetValue,
    actualValue,
    targetDate,
    startDate,
    endDate,
    status,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
