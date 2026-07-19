import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_data_point.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';

/// States for the work-timeline feature.
sealed class TimelineState extends Equatable {
  const TimelineState();

  @override
  List<Object?> get props => [];
}

/// Initial state — nothing loaded yet.
class TimelineInitial extends TimelineState {
  const TimelineInitial();
}

/// Loading state — data is being fetched.
class TimelineLoading extends TimelineState {
  const TimelineLoading();
}

/// Loaded state — milestones and chart data are ready.
class TimelineLoaded extends TimelineState {
  final List<TimelineMilestone> milestones;
  final List<TimelineDataPoint> progressData;
  final DateTime startDate;
  final DateTime endDate;
  final String? selectedZoneId;

  const TimelineLoaded({
    required this.milestones,
    required this.progressData,
    required this.startDate,
    required this.endDate,
    this.selectedZoneId,
  });

  TimelineLoaded copyWith({
    List<TimelineMilestone>? milestones,
    List<TimelineDataPoint>? progressData,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedZoneId,
  }) {
    return TimelineLoaded(
      milestones: milestones ?? this.milestones,
      progressData: progressData ?? this.progressData,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedZoneId: selectedZoneId ?? this.selectedZoneId,
    );
  }

  @override
  List<Object?> get props => [
    milestones,
    progressData,
    startDate,
    endDate,
    selectedZoneId,
  ];
}

/// Error state — something went wrong.
class TimelineError extends TimelineState {
  final String message;

  const TimelineError(this.message);

  @override
  List<Object?> get props => [message];
}
