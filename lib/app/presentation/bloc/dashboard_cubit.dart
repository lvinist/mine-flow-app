/// Dashboard Cubit — fetches real dashboard stat values from repositories.
///
/// Calls four repositories in parallel to populate:
///   - activeCrewCount       (AttendanceRepository)
///   - cutFillVolume         (TrackingRepository)
///   - equipmentChecksCount  (EquipmentCheckRepository)
///   - unreadNotificationsCount (NotificationRepository)
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_state.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/notifications/domain/repositories/notification_repository.dart';

/// Cubit that loads dashboard summary statistics from the four feature
/// repositories. Defaults to 0 on any error so the UI never crashes.
class DashboardCubit extends Cubit<DashboardState> {
  final AttendanceRepository _attendanceRepository;
  final TrackingRepository _trackingRepository;
  final EquipmentCheckRepository _equipmentCheckRepository;
  final NotificationRepository _notificationRepository;

  DashboardCubit({
    required this._attendanceRepository,
    required this._trackingRepository,
    required this._equipmentCheckRepository,
    required this._notificationRepository,
  }) : super(const DashboardState());

  /// Fetches today's stat values for the given [siteId].
  ///
  /// Emits [DashboardStatus.loading] first, then
  /// [DashboardStatus.success] with real values, or
  /// [DashboardStatus.failure] with fallback 0 for each stat.
  Future<void> loadDashboardStats(String siteId) async {
    emit(state.copyWith(status: DashboardStatus.loading));

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));

      // Fire all four fetches in parallel.
      final results = await Future.wait([
        _fetchActiveCrewCount(siteId, todayStart, todayEnd),
        _fetchCutFillVolume(siteId, todayStart, todayEnd),
        _fetchEquipmentChecksCount(siteId, todayStart, todayEnd),
        _fetchUnreadNotificationsCount(),
      ]);

      emit(
        DashboardState(
          status: DashboardStatus.success,
          activeCrewCount: results[0] as int,
          cutFillVolume: results[1] as double,
          equipmentChecksCount: results[2] as int,
          unreadNotificationsCount: results[3] as int,
        ),
      );
    } catch (_) {
      emit(
        const DashboardState(
          status: DashboardStatus.failure,
          activeCrewCount: 0,
          cutFillVolume: 0.0,
          equipmentChecksCount: 0,
          unreadNotificationsCount: 0,
        ),
      );
    }
  }

  Future<int> _fetchActiveCrewCount(
    String siteId,
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    try {
      final records = await _attendanceRepository.getAttendanceForDate(
        todayStart,
        siteId: siteId,
      );
      // CF-012: only crew marked present count as "active" — absent/sick/leave
      // must not inflate the headline.
      return records.where((r) => r.status == AttendanceStatus.present).length;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _fetchCutFillVolume(
    String siteId,
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    try {
      final records = await _trackingRepository.getCutFillRecords(
        siteId: siteId,
        startDate: todayStart,
        endDate: todayEnd,
      );
      // CF-011: BCM and LCM are two bases of the same material — summing them
      // raw double-counts. Use the bank-equivalent net volume instead.
      double total = 0.0;
      for (final r in records) {
        total += r.netVolume;
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  Future<int> _fetchEquipmentChecksCount(
    String siteId,
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    try {
      final records = await _equipmentCheckRepository.getEquipmentChecks(
        siteId: siteId,
        startDate: todayStart,
        endDate: todayEnd,
      );
      return records.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchUnreadNotificationsCount() async {
    try {
      return await _notificationRepository.getUnreadCount();
    } catch (_) {
      return 0;
    }
  }
}
