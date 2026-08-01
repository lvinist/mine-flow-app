import 'package:equatable/equatable.dart';

/// Domain entity representing earthwork cut and fill volume measurements for a site/zone.
///
/// v2: Replaced generic cutVolumeM3/fillVolumeM3 with explicit bcmVolume/lcmVolume
/// (Bank Cubic Meters / Loose Cubic Meters) and added materialType.
class CutFillRecord extends Equatable {
  final String id;
  final String siteId;
  final String zoneId;
  final String? dailyLogId;
  final double bcmVolume;
  final double lcmVolume;
  final String? materialType;
  final double? elevationChange;
  final DateTime measurementDate;
  final String? measuredBy;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const CutFillRecord({
    required this.id,
    required this.siteId,
    required this.zoneId,
    this.dailyLogId,
    this.bcmVolume = 0.0,
    this.lcmVolume = 0.0,
    this.materialType,
    this.elevationChange,
    required this.measurementDate,
    this.measuredBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Net volume calculation (BCM - LCM).
  double get netVolume => bcmVolume - lcmVolume;

  CutFillRecord copyWith({
    String? id,
    String? siteId,
    String? zoneId,
    String? dailyLogId,
    double? bcmVolume,
    double? lcmVolume,
    String? materialType,
    double? elevationChange,
    DateTime? measurementDate,
    String? measuredBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CutFillRecord(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      zoneId: zoneId ?? this.zoneId,
      dailyLogId: dailyLogId ?? this.dailyLogId,
      bcmVolume: bcmVolume ?? this.bcmVolume,
      lcmVolume: lcmVolume ?? this.lcmVolume,
      materialType: materialType ?? this.materialType,
      elevationChange: elevationChange ?? this.elevationChange,
      measurementDate: measurementDate ?? this.measurementDate,
      measuredBy: measuredBy ?? this.measuredBy,
      notes: notes ?? this.notes,
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
    dailyLogId,
    bcmVolume,
    lcmVolume,
    materialType,
    elevationChange,
    measurementDate,
    measuredBy,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
