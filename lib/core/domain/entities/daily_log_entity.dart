import 'package:equatable/equatable.dart';

/// Domain entity representing a foreman's structured daily progress log.
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
class DailyLogEntity extends Equatable {
  final String id;
  final String siteId;
  final String foremanId;
  final DateTime logDate;
  final String? zoneId;
  final String status; // 'draft' | 'submitted' | 'approved'
  final String? summary;
  final String? weather;
  final String? notes;
  final String? approvedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const DailyLogEntity({
    required this.id,
    required this.siteId,
    required this.foremanId,
    required this.logDate,
    this.zoneId,
    this.status = 'draft',
    this.summary,
    this.weather,
    this.notes,
    this.approvedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

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
