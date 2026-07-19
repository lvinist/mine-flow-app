import 'package:equatable/equatable.dart';
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
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

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
        approvedBy,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
