import 'package:equatable/equatable.dart';

/// Domain entity representing earthwork cut/fill volume measurements.
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
class CutFillRecordEntity extends Equatable {
  final String id;
  final String siteId;
  final String? dailyLogId;
  final String zoneId;
  final double cutVolume;
  final double fillVolume;
  final double? elevationChange;
  final DateTime measuredAt;
  final String? measuredBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const CutFillRecordEntity({
    required this.id,
    required this.siteId,
    this.dailyLogId,
    required this.zoneId,
    this.cutVolume = 0.0,
    this.fillVolume = 0.0,
    this.elevationChange,
    required this.measuredAt,
    this.measuredBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        siteId,
        dailyLogId,
        zoneId,
        cutVolume,
        fillVolume,
        elevationChange,
        measuredAt,
        measuredBy,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
