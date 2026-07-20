/// Dashboard state — holds the 4 stat card values and a load status.
library;

/// Load status for the dashboard data.
enum DashboardStatus { initial, loading, success, failure }

/// The state emitted by [DashboardCubit].
class DashboardState {
  final DashboardStatus status;
  final int activeCrewCount;
  final double cutFillVolume;
  final int equipmentChecksCount;
  final int unreadNotificationsCount;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.activeCrewCount = 0,
    this.cutFillVolume = 0.0,
    this.equipmentChecksCount = 0,
    this.unreadNotificationsCount = 0,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    int? activeCrewCount,
    double? cutFillVolume,
    int? equipmentChecksCount,
    int? unreadNotificationsCount,
  }) {
    return DashboardState(
      status: status ?? this.status,
      activeCrewCount: activeCrewCount ?? this.activeCrewCount,
      cutFillVolume: cutFillVolume ?? this.cutFillVolume,
      equipmentChecksCount: equipmentChecksCount ?? this.equipmentChecksCount,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
    );
  }
}
