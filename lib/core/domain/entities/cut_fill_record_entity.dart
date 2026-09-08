import 'package:equatable/equatable.dart';

/// Domain entity representing earthwork cut/fill volume measurements.
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
/// v2: Replaced generic cutVolume/fillVolume with explicit BCM/LCM volumetric
/// states and added materialType for operational precision.
class CutFillRecordEntity extends Equatable {
  final String id;
  final String siteId;
  final String? dailyLogId;
  final String zoneId;
  final double bcmVolume;
  final double lcmVolume;
  final String? materialType;
  final double? elevationChange;
  final DateTime measuredAt;
  final String? measuredBy;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const CutFillRecordEntity({
    required this.id,
    required this.siteId,
    this.dailyLogId,
    required this.zoneId,
    this.bcmVolume = 0.0,
    this.lcmVolume = 0.0,
    this.materialType,
    this.elevationChange,
    required this.measuredAt,
    this.measuredBy,
    this.notes,
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
    bcmVolume,
    lcmVolume,
    materialType,
    elevationChange,
    measuredAt,
    measuredBy,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
