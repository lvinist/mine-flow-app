import 'package:equatable/equatable.dart';

/// Domain entity representing earthwork cut and fill volume measurements for a site/zone.
class CutFillRecord extends Equatable {
  final String id;
  final String siteId;
  final String zoneId;
  final String? dailyLogId;
  final double cutVolumeM3;
  final double fillVolumeM3;
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
    this.cutVolumeM3 = 0.0,
    this.fillVolumeM3 = 0.0,
    this.elevationChange,
    required this.measurementDate,
    this.measuredBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Net volume calculation in cubic meters (Cut - Fill).
  double get netVolumeM3 => cutVolumeM3 - fillVolumeM3;

  CutFillRecord copyWith({
    String? id,
    String? siteId,
    String? zoneId,
    String? dailyLogId,
    double? cutVolumeM3,
    double? fillVolumeM3,
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
      cutVolumeM3: cutVolumeM3 ?? this.cutVolumeM3,
      fillVolumeM3: fillVolumeM3 ?? this.fillVolumeM3,
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
        cutVolumeM3,
        fillVolumeM3,
        elevationChange,
        measurementDate,
        measuredBy,
        notes,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
