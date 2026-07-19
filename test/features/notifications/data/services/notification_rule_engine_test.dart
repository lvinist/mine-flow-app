import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/notifications/data/services/notification_rule_engine.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_data_point.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';

/// A simple stub implementation of [TrackingRepository] for testing.
class _StubTrackingRepository implements TrackingRepository {
  final List<InventoryItem> items;

  _StubTrackingRepository({this.items = const []});

  @override
  Future<List<InventoryItem>> getInventoryItems({
    String? siteId,
    String? zoneId,
    String? category,
  }) async {
    return items;
  }

  // Remaining methods unused by the rule engine — keep them minimal.
  @override
  Future<List<CutFillRecord>> getCutFillRecords({
    String? siteId,
    String? zoneId,
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];
  @override
  Future<CutFillRecord?> getCutFillRecordById(String id) async => null;
  @override
  Future<void> saveCutFillRecord(CutFillRecord record) async {}
  @override
  Future<void> deleteCutFillRecord(String id) async {}
  @override
  Future<List<LandClearingRecord>> getLandClearingRecords({
    String? siteId,
    String? zoneId,
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];
  @override
  Future<LandClearingRecord?> getLandClearingRecordById(String id) async =>
      null;
  @override
  Future<void> saveLandClearingRecord(LandClearingRecord record) async {}
  @override
  Future<void> deleteLandClearingRecord(String id) async {}
  @override
  Future<InventoryItem?> getInventoryItemById(String id) async => null;
  @override
  Future<void> saveInventoryItem(InventoryItem item) async {}
  @override
  Future<void> updateInventoryQuantity(String id, double deltaQuantity) async {}
  @override
  Future<void> deleteInventoryItem(String id) async {}
  @override
  Future<void> syncRemote() async {}
}

/// A simple stub implementation of [AttendanceRepository] for testing.
class _StubAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> records;

  _StubAttendanceRepository({this.records = const []});

  @override
  Future<List<AttendanceRecord>> getAttendanceForDate(
    DateTime date, {
    String? siteId,
  }) async {
    return records;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];
  @override
  Future<AttendanceRecord?> getAttendanceById(String id) async => null;
  @override
  Future<void> saveAttendance(AttendanceRecord record) async {}
  @override
  Future<void> saveAttendanceBatch(List<AttendanceRecord> records) async {}
  @override
  Future<void> deleteAttendance(String id) async {}
  @override
  Future<List<AttendanceRecord>> syncRemote() async => [];
}

/// A simple stub implementation of [TimelineRepository] for testing.
class _StubTimelineRepository implements TimelineRepository {
  final List<TimelineMilestone> milestones;

  _StubTimelineRepository({this.milestones = const []});

  @override
  Future<List<TimelineMilestone>> getMilestones({
    required String siteId,
    String? zoneId,
  }) async {
    return milestones;
  }

  @override
  Future<TimelineMilestone> createMilestone(
    TimelineMilestone milestone,
  ) async => milestone;
  @override
  Future<void> updateMilestone(TimelineMilestone milestone) async {}
  @override
  Future<void> deleteMilestone(String id) async {}
  @override
  Future<List<TimelineDataPoint>> getProgressData({
    required String siteId,
    String? zoneId,
    required DateTime startDate,
    required DateTime endDate,
  }) async => [];
}

void main() {
  group('NotificationRuleEngine', () {
    test(
      'evaluateRules returns equipment check reminder when called after 3 PM',
      () async {
        final now = DateTime.now();

        final ruleEngine = NotificationRuleEngine(
          trackingRepository: _StubTrackingRepository(),
          attendanceRepository: _StubAttendanceRepository(),
          timelineRepository: _StubTimelineRepository(),
        );

        final notifications = await ruleEngine.evaluateRules(
          siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        );

        if (now.hour >= 15) {
          // After 3 PM — should generate the equipment check reminder
          expect(notifications.length, greaterThanOrEqualTo(1));

          final reminder = notifications.firstWhere(
            (n) => n.type == NotificationType.equipmentCheckReminder,
            orElse: () =>
                throw Exception('Expected equipment check reminder not found'),
          );

          expect(reminder.title, equals('Peringatan Alat'));
          expect(
            reminder.message,
            contains('Pemeriksaan peralatan selesai kerja belum dilakukan'),
          );
          expect(reminder.severity, equals(NotificationSeverity.critical));
          expect(reminder.isRead, isFalse);
          expect(reminder.isDismissed, isFalse);
          expect(reminder.expiresAt, isNotNull);
        } else {
          // Before 3 PM — no notifications should be generated
          expect(notifications, isEmpty);
        }
      },
    );

    test(
      'evaluateRules generates low inventory warning for low-stock items',
      () async {
        final ruleEngine = NotificationRuleEngine(
          trackingRepository: _StubTrackingRepository(
            items: [
              const InventoryItem(
                id: 'item-1',
                siteId: 'site-1',
                itemName: 'Fuel',
                quantityOnHand: 50,
                minThreshold: 100,
                unit: 'L',
              ),
              const InventoryItem(
                id: 'item-2',
                siteId: 'site-1',
                itemName: 'Lubricant',
                quantityOnHand: 200,
                minThreshold: 50,
                unit: 'L',
              ),
            ],
          ),
          attendanceRepository: _StubAttendanceRepository(),
          timelineRepository: _StubTimelineRepository(),
        );

        final notifications = await ruleEngine.evaluateRules(siteId: 'site-1');

        // Should have at least one low-inventory notification (Fuel is low)
        final lowInventoryNotifs = notifications.where(
          (n) => n.type == NotificationType.lowInventory,
        );

        expect(lowInventoryNotifs.length, equals(1));
        expect(lowInventoryNotifs.first.message, contains('Fuel'));
        expect(
          lowInventoryNotifs.first.severity,
          equals(NotificationSeverity.warning),
        );
      },
    );

    test(
      'evaluateRules generates missing attendance warning when no records',
      () async {
        final ruleEngine = NotificationRuleEngine(
          trackingRepository: _StubTrackingRepository(),
          attendanceRepository: _StubAttendanceRepository(records: []),
          timelineRepository: _StubTimelineRepository(),
        );

        final notifications = await ruleEngine.evaluateRules(siteId: 'site-1');

        final attendanceNotifs = notifications.where(
          (n) => n.type == NotificationType.missingAttendance,
        );

        expect(attendanceNotifs.length, equals(1));
        expect(
          attendanceNotifs.first.severity,
          equals(NotificationSeverity.warning),
        );
      },
    );

    test(
      'evaluateRules does NOT generate missing attendance when records exist',
      () async {
        final ruleEngine = NotificationRuleEngine(
          trackingRepository: _StubTrackingRepository(),
          attendanceRepository: _StubAttendanceRepository(
            records: [
              AttendanceRecord(
                id: 'att-1',
                siteId: 'site-1',
                userId: 'user-1',
                date: DateTime.now(),
                status: AttendanceStatus.present,
                loggedBy: 'user-1',
              ),
            ],
          ),
          timelineRepository: _StubTimelineRepository(),
        );

        final notifications = await ruleEngine.evaluateRules(siteId: 'site-1');

        final attendanceNotifs = notifications.where(
          (n) => n.type == NotificationType.missingAttendance,
        );

        expect(attendanceNotifs, isEmpty);
      },
    );

    test(
      'evaluateRules generates overdue milestone info when target date passed',
      () async {
        final ruleEngine = NotificationRuleEngine(
          trackingRepository: _StubTrackingRepository(),
          attendanceRepository: _StubAttendanceRepository(),
          timelineRepository: _StubTimelineRepository(
            milestones: [
              TimelineMilestone(
                id: 'ms-1',
                siteId: 'site-1',
                title: 'Complete Excavation',
                targetDate: DateTime(2024, 1, 1),
                actualValue: 500,
                targetValue: 1000,
                startDate: DateTime(2023, 1, 1),
              ),
              TimelineMilestone(
                id: 'ms-2',
                siteId: 'site-1',
                title: 'Completed On Time',
                targetDate: DateTime(2024, 1, 1),
                actualValue: 1000,
                targetValue: 1000,
                startDate: DateTime(2023, 1, 1),
              ),
            ],
          ),
        );

        final notifications = await ruleEngine.evaluateRules(siteId: 'site-1');

        final overdueNotifs = notifications.where(
          (n) => n.type == NotificationType.overdueMilestone,
        );

        // Only ms-1 should be flagged (target passed, not 100% complete)
        expect(overdueNotifs.length, equals(1));
        expect(overdueNotifs.first.message, contains('Complete Excavation'));
        expect(overdueNotifs.first.severity, equals(NotificationSeverity.info));
      },
    );

    test(
      'evaluateRules handles all rules gracefully when repositories are empty',
      () async {
        final ruleEngine = NotificationRuleEngine(
          trackingRepository: _StubTrackingRepository(),
          attendanceRepository: _StubAttendanceRepository(),
          timelineRepository: _StubTimelineRepository(),
        );

        // Should not throw even when all repositories return empty data
        final notifications = await ruleEngine.evaluateRules(siteId: 'site-1');

        // Still fine: the result depends on time of day for Rule 1
        expect(notifications, isA<List<AppNotification>>());
      },
    );
  });
}
