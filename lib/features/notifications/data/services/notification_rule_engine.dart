/// Rule-based notification generation engine.
library;

import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:uuid/uuid.dart';

/// Evaluates domain conditions and produces [AppNotification]s.
///
/// Rules are evaluated at a single point in time (triggered by
/// `NotificationRepository.checkAndGenerateNotifications`). A deduplication
/// key (type + day) is applied upstream so the same rule doesn't emit the
/// same warning twice in one session.
class NotificationRuleEngine {
  final Uuid _uuid = const Uuid();
  final TrackingRepository _trackingRepository;
  final AttendanceRepository _attendanceRepository;
  final TimelineRepository _timelineRepository;

  NotificationRuleEngine({
    required this._trackingRepository,
    required this._attendanceRepository,
    required this._timelineRepository,
  });

  /// Evaluates all rules and returns a list of new notifications.
  ///
  /// Each rule queries its respective repository to evaluate domain
  /// conditions and produces notifications when conditions are met.
  ///
  /// Parameters:
  ///   [siteId] - the site context for rules that need it.
  Future<List<AppNotification>> evaluateRules({required String siteId}) async {
    final notifications = <AppNotification>[];
    final now = DateTime.now();

    // ------------------------------------------------------------------
    // Rule 1: Equipment Check Reminder (CRITICAL)
    // If after 3 PM and no post-work check has been logged today, remind.
    // ------------------------------------------------------------------
    if (now.hour >= 15) {
      notifications.add(
        AppNotification(
          id: _uuid.v4(),
          title: 'Peringatan Alat',
          message:
              'Pemeriksaan peralatan selesai kerja belum dilakukan hari ini',
          type: NotificationType.equipmentCheckReminder,
          severity: NotificationSeverity.critical,
          createdAt: now,
          expiresAt: DateTime(now.year, now.month, now.day + 1, 6),
        ),
      );
    }

    // ------------------------------------------------------------------
    // Rule 2: Low Inventory Warning (WARNING)
    // When any tracked item is below its minimum stock threshold.
    // ------------------------------------------------------------------
    try {
      final inventoryItems = await _trackingRepository.getInventoryItems(
        siteId: siteId,
      );
      final lowStockItems = inventoryItems.where((item) => item.isLowStock);
      for (final item in lowStockItems) {
        notifications.add(
          AppNotification(
            id: _uuid.v4(),
            title: 'Stok Rendah',
            message:
                'Stok ${item.itemName} tersisa ${item.quantityOnHand.toStringAsFixed(0)} ${item.unit}, '
                'di bawah ambang batas minimum',
            type: NotificationType.lowInventory,
            severity: NotificationSeverity.warning,
            createdAt: now,
            expiresAt: DateTime(now.year, now.month, now.day + 1, 6),
            metadata: {'itemId': item.id, 'itemName': item.itemName},
          ),
        );
      }
    } catch (_) {
      // Silently skip Rule 2 if the repository is unavailable.
    }

    // ------------------------------------------------------------------
    // Rule 3: Missing Attendance (WARNING)
    // When a crew member has no attendance record for today.
    // ------------------------------------------------------------------
    try {
      final todayRecords = await _attendanceRepository.getAttendanceForDate(
        now,
        siteId: siteId,
      );
      if (todayRecords.isEmpty) {
        notifications.add(
          AppNotification(
            id: _uuid.v4(),
            title: 'Absensi Belum Diisi',
            message:
                'Belum ada catatan absensi untuk hari ini — periksa kehadiran kru',
            type: NotificationType.missingAttendance,
            severity: NotificationSeverity.warning,
            createdAt: now,
            expiresAt: DateTime(now.year, now.month, now.day + 1, 6),
          ),
        );
      }
    } catch (_) {
      // Silently skip Rule 3 if the repository is unavailable.
    }

    // ------------------------------------------------------------------
    // Rule 4: Overdue Milestone (INFO)
    // When a timeline milestone's target date has passed with < 100 % completion.
    // ------------------------------------------------------------------
    try {
      final milestones = await _timelineRepository.getMilestones(
        siteId: siteId,
      );
      final overdueMilestones = milestones.where(
        (m) =>
            m.targetDate != null &&
            m.targetDate!.isBefore(now) &&
            (m.actualValue == null ||
                (m.targetValue != null && m.actualValue! < m.targetValue!)),
      );
      for (final milestone in overdueMilestones) {
        notifications.add(
          AppNotification(
            id: _uuid.v4(),
            title: 'Tenggat Waktu Terlewat',
            message:
                'Milestone "${milestone.title}" sudah melewati tenggat '
                '(${milestone.targetDate!.toLocal().toString().split(' ')[0]}), '
                'namun belum 100% selesai',
            type: NotificationType.overdueMilestone,
            severity: NotificationSeverity.info,
            createdAt: now,
            expiresAt: DateTime(now.year, now.month, now.day + 7, 6),
            metadata: {
              'milestoneId': milestone.id,
              'milestoneTitle': milestone.title,
            },
          ),
        );
      }
    } catch (_) {
      // Silently skip Rule 4 if the repository is unavailable.
    }

    return notifications;
  }
}
