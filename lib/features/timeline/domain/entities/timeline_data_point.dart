import 'package:equatable/equatable.dart';

/// A single data-point on the work-timeline chart.
///
/// Carries both daily and cumulative values for cut volume, fill volume,
/// and land clearing area, all keyed on [date].
class TimelineDataPoint extends Equatable {
  final DateTime date;
  final double cumulativeCutVolume;
  final double cumulativeFillVolume;
  final double cumulativeLandClearing;
  final double dailyCutVolume;
  final double dailyFillVolume;
  final double dailyLandClearing;

  const TimelineDataPoint({
    required this.date,
    this.cumulativeCutVolume = 0.0,
    this.cumulativeFillVolume = 0.0,
    this.cumulativeLandClearing = 0.0,
    this.dailyCutVolume = 0.0,
    this.dailyFillVolume = 0.0,
    this.dailyLandClearing = 0.0,
  });

  @override
  List<Object?> get props => [
    date,
    cumulativeCutVolume,
    cumulativeFillVolume,
    cumulativeLandClearing,
    dailyCutVolume,
    dailyFillVolume,
    dailyLandClearing,
  ];
}
