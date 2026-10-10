import 'dart:convert';

import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';

/// Restorable snapshot of the daily log form's editable entry fields only.
///
/// Per 59.0 design §5: hazard fields are stored *as entered* (the 55.6
/// hazard/approval contract must not be pre-fulfilled by a snapshot); validation
/// re-runs on restore, never trusting the snapshot. Status-gated: only draft
/// logs are restorable — a submitted/approved log restores as rejected (null).
///
/// CONTEXT fields (id, siteId, foremanId, status, approvedBy, createdAt,
/// updatedAt, deletedAt) are reloaded from the repository on restore — never
/// snapshotted. Only the ENTRY fields are encoded:
///   logDate, zoneId, weather, summary, notes, hazard{state,severity,notes,correctiveAction}
class DailyLogDraftRestoration {
  const DailyLogDraftRestoration({
    required this.siteId,
    required this.foremanId,
    required this.date,
    required this.status,
    required this.zoneId,
    required this.weather,
    required this.summary,
    required this.notes,
    required this.hazard,
  });

  // Identity (ENTRY context, not restored record fields)
  final String siteId;
  final String foremanId;
  final DateTime date;

  // Status gate — restore is rejected for non-draft (59.0 §5)
  final LogStatus status;

  // ENTRY fields — hazard stored *as entered*, validation re-runs on restore
  final String? zoneId;
  final String? weather;
  final String? summary;
  final String? notes;
  final HazardAssessment hazard;

  /// Captures editable values without persisting success, errors, or sync state.
  /// Only called when [DailyLogFormState.log.status] is [LogStatus.draft].
  static String encode(DailyLogFormState state) {
    final log = state.log;
    final h = log.hazard;
    return jsonEncode({
      'version': 1,
      'siteId': log.siteId,
      'foremanId': log.foremanId,
      'date': log.logDate.toIso8601String().substring(0, 10),
      'status': log.status.toValue(),
      'zoneId': log.zoneId,
      'weather': log.weather,
      'summary': log.summary,
      'notes': log.notes,
      'hazard': {
        'state': h.state.toValue(),
        'severity': h.severity?.toValue(),
        'hazardNotes': h.notes,
        'correctiveAction': h.correctiveAction,
      },
    });
  }

  /// Strict version-gated decode → null on mismatch (mirrors CutFillDraftRestoration).
  /// Returns null (→ form starts clean) for any malformed, version-mismatched,
  /// or non-draft-status snapshot. The caller is responsible for re-running
  /// hazard validation after applying the restored values.
  static DailyLogDraftRestoration? decode(
    String? serialized,
    String expectedSiteId,
    String expectedForemanId,
  ) {
    if (serialized == null) return null;
    final data = _tryJson(serialized);
    if (data == null) return null;

    // Identity must match the current form context (59.0 §2: snapshot is
    // identity-gated on siteId + foremanId + date for daily log).
    if (data['siteId'] != expectedSiteId ||
        data['foremanId'] != expectedForemanId) {
      return null;
    }

    final status = LogStatus.fromString(data['status'] as String?);
    // Status gate per 59.0 §5: restore only drafts. A snapshot carrying
    // submitted/approved status is ignored — the form loads fresh and the
    // auto-save/draft contract re-establishes state from the repository.
    if (status != LogStatus.draft) return null;

    final hazard = _decodeHazard(data['hazard']);
    if (hazard == null) return null;

    final date = _decodeDate(data['date'] as String?);
    if (date == null) return null;

    final summary = data['summary'];
    if (summary != null && summary is! String) return null;
    final notes = data['notes'];
    if (notes != null && notes is! String) return null;
    final weather = data['weather'];
    if (weather != null && weather is! String) return null;
    final zoneId = data['zoneId'];
    if (zoneId != null && zoneId is! String) return null;

    return DailyLogDraftRestoration(
      siteId: data['siteId'] as String,
      foremanId: data['foremanId'] as String,
      date: date,
      status: status,
      zoneId: zoneId as String?,
      weather: weather as String?,
      summary: summary as String?,
      notes: notes as String?,
      hazard: hazard,
    );
  }

  static Map<String, dynamic>? _tryJson(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic> ||
          data['version'] != 1 ||
          data['siteId'] is! String ||
          data['foremanId'] is! String ||
          data['date'] is! String ||
          data['status'] is! String ||
          data['hazard'] is! Map) {
        return null;
      }
      // Identity must match the current form context.
      return data;
    } on FormatException {
      return null;
    }
  }

  static DateTime? _decodeDate(String? dateText) {
    if (dateText == null) return null;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateText)) return null;
    final date = DateTime.tryParse(dateText);
    if (date == null || date.toIso8601String().substring(0, 10) != dateText) {
      return null;
    }
    return date;
  }

  /// Decodes the hazard sub-object *as entered* — does NOT apply [normalized()],
  /// because the 59.0 design mandates that validation re-runs on restore.
  /// An invalid combination (e.g. present+null severity) is preserved verbatim
  /// from the snapshot and rejected by the form's submit validator, exactly as
  /// it would be for fresh input.
  static HazardAssessment? _decodeHazard(dynamic raw) {
    final hazard = raw as Map<String, dynamic>;
    final stateVal = hazard['state'] as String?;
    final state = HazardStateValue.fromString(stateVal);
    if (stateVal != null &&
        state == HazardState.notAssessed &&
        stateVal != 'not_assessed') {
      return null;
    }

    final severityVal = hazard['severity'] as String?;
    final severity = HazardSeverityValue.fromString(severityVal);

    final notes = hazard['hazardNotes'];
    if (notes != null && notes is! String) return null;
    final action = hazard['correctiveAction'];
    if (action != null && action is! String) return null;

    return HazardAssessment(
      state: state,
      severity: severity,
      notes: notes as String?,
      correctiveAction: action as String?,
    );
  }
}

/// Apply a decoded snapshot onto a freshly-loaded [DailyLog] (reload-before-apply
/// per 59.0 design §2). Context fields come from the repository; ENTRY fields
/// come from the snapshot. The caller must still re-run validation — the hazard
/// is NOT normalized here, so an invalid snapshot is rejected by the same
/// validator that guards fresh input.
DailyLog applyDailyLogSnapshot(
  DailyLog base,
  DailyLogDraftRestoration snapshot,
) {
  return base.copyWith(
    logDate: snapshot.date,
    zoneId: snapshot.zoneId,
    weather: snapshot.weather,
    summary: snapshot.summary,
    notes: snapshot.notes,
    hazard: snapshot.hazard,
  );
}
