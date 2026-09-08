import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_data_point.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:mine_flow/features/timeline/presentation/bloc/timeline_state.dart';

/// Cubit managing work-timeline data — milestones and progress chart.
class TimelineCubit extends Cubit<TimelineState> {
  final TimelineRepository _repository;
  final String siteId;

  TimelineCubit({required this._repository, required this.siteId})
    : super(const TimelineInitial());

  /// Loads milestones and progress data for [startDate]..[endDate].
  Future<void> loadData({
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  }) async {
    emit(const TimelineLoading());

    try {
      final results = await Future.wait([
        _repository.getMilestones(siteId: siteId, zoneId: zoneId),
        _repository.getProgressData(
          siteId: siteId,
          zoneId: zoneId,
          startDate: startDate,
          endDate: endDate,
        ),
      ]);

      final milestones = results[0] as List<TimelineMilestone>;
      milestones.sort((a, b) => b.startDate.compareTo(a.startDate));

      emit(
        TimelineLoaded(
          milestones: milestones,
          progressData: results[1] as List<TimelineDataPoint>,
          startDate: startDate,
          endDate: endDate,
          selectedZoneId: zoneId,
        ),
      );
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('<!DOCTYPE html>') ||
          msg.contains('<html') ||
          msg.contains('PostgrestException')) {
        msg = 'Koneksi ke database server Supabase tidak tersedia.';
      }
      emit(TimelineError('Gagal memuat data timeline: $msg'));
    }
  }

  /// Refreshes with the same date range and zone from current state.
  Future<void> refresh() async {
    final s = state;
    if (s is TimelineLoaded) {
      await loadData(
        startDate: s.startDate,
        endDate: s.endDate,
        zoneId: s.selectedZoneId,
      );
    }
  }

  /// Sets the zone filter and reloads.
  Future<void> setZoneFilter({
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  }) async {
    await loadData(startDate: startDate, endDate: endDate, zoneId: zoneId);
  }
}
