import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Domain entity representing a foreman's structured daily progress log entry.
///
/// Refers to Doc 04 — Data Model, Ownership & Retention.
class DailyLog extends Equatable {
  final String id;
  final String siteId;
  final String foremanId;
  final DateTime logDate;
  final String? zoneId;
  final LogStatus status;
  final String? summary;
  final String? weather;
  final String? notes;
  final HazardAssessment hazard;
  final String? approvedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const DailyLog({
    required this.id,
    required this.siteId,
    required this.foremanId,
    required this.logDate,
    this.zoneId,
    this.status = LogStatus.draft,
    this.summary,
    this.weather,
    this.notes,
    this.hazard = const HazardAssessment.notAssessed(),
    this.approvedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  DailyLog copyWith({
    String? id,
    String? siteId,
    String? foremanId,
    DateTime? logDate,
    String? zoneId,
    LogStatus? status,
    String? summary,
    String? weather,
    String? notes,
    HazardAssessment? hazard,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return DailyLog(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      foremanId: foremanId ?? this.foremanId,
      logDate: logDate ?? this.logDate,
      zoneId: zoneId ?? this.zoneId,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      weather: weather ?? this.weather,
      notes: notes ?? this.notes,
      hazard: hazard ?? this.hazard,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Whether the log may be submitted (STEP-55.6, spec §4.5 items 4/7).
  ///
  /// A foreman must answer the hazard question before submitting, so
  /// `not_assessed` blocks submission; a `present` assessment additionally
  /// requires a severity (`HazardAssessment.isValid`). This is the domain
  /// twin of the UI's disabled submit action and of the server-side
  /// coherence constraint.
  bool get canSubmit =>
      status == LogStatus.draft && hazard.state != HazardState.notAssessed;

  /// Whether a supervisor may approve this log (spec §4.5 item 4):
  /// exactly `submitted`, never already approved.
  bool get canApprove => status == LogStatus.submitted;

  /// Whether a foreman may still edit content: drafts only.
  bool get isEditable => status == LogStatus.draft;

  /// Whether the record is frozen after approval.
  bool get isImmutable => status == LogStatus.approved;

  @override
  List<Object?> get props => [
    id,
    siteId,
    foremanId,
    logDate,
    zoneId,
    status,
    summary,
    weather,
    notes,
    hazard,
    approvedBy,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
