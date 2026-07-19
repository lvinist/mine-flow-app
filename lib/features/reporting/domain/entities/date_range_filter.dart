import 'package:equatable/equatable.dart';

/// Value object representing a date range filter for reports.
///
/// Used to specify the time window for data aggregation in report generation.
class DateRangeFilter extends Equatable {
  /// Start date of the range (inclusive).
  final DateTime startDate;

  /// End date of the range (inclusive).
  final DateTime endDate;

  const DateRangeFilter({required this.startDate, required this.endDate});

  /// Duration of the date range.
  Duration get duration => endDate.difference(startDate);

  /// Number of days in the range (inclusive).
  int get dayCount => duration.inDays + 1;

  /// Whether this is a valid range (start <= end).
  bool get isValid => !startDate.isAfter(endDate);

  /// Creates a filter for the current week (Monday to Sunday).
  factory DateRangeFilter.currentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return DateRangeFilter(
      startDate: DateTime(monday.year, monday.month, monday.day),
      endDate: DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
    );
  }

  /// Creates a filter for the current month.
  factory DateRangeFilter.currentMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateRangeFilter(startDate: firstDay, endDate: lastDay);
  }

  /// Creates a filter for Year-To-Date.
  factory DateRangeFilter.yearToDate() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// Creates a filter for Project-To-Date (from project start to now).
  /// Uses a fixed project start date for the MVP.
  factory DateRangeFilter.projectToDate() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(2026, 1, 1), // Project start — adjust as needed
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// Creates a new [DateRangeFilter] with the given fields replaced.
  DateRangeFilter copyWith({DateTime? startDate, DateTime? endDate}) {
    return DateRangeFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [startDate, endDate];
}
