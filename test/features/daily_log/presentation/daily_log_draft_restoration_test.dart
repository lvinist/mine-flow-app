import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_draft_restoration.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';

void main() {
  const siteId = 'site-1';
  const foremanId = 'foreman-1';
  final logDate = DateTime(2026, 10, 10);

  group('DailyLogDraftRestoration', () {
    test('round-trip equality: encode → decode → fields equal', () {
      final log = DailyLog(
        id: 'dl-001',
        siteId: siteId,
        foremanId: foremanId,
        logDate: logDate,
        zoneId: 'zone-A',
        status: LogStatus.draft,
        summary: 'Completed excavation in pit 3',
        weather: 'Sunny',
        notes: 'Crew finished early',
        hazard: const HazardAssessment(
          state: HazardState.present,
          severity: HazardSeverity.high,
          notes: 'Exposed high-voltage line',
          correctiveAction: 'Erect barricades',
        ),
      );

      final state = DailyLogFormState(log: log);
      final encoded = DailyLogDraftRestoration.encode(state);
      final decoded = DailyLogDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      expect(decoded!.siteId, siteId);
      expect(decoded.foremanId, foremanId);
      expect(decoded.date, logDate);
      expect(decoded.status, LogStatus.draft);
      expect(decoded.zoneId, 'zone-A');
      expect(decoded.weather, 'Sunny');
      expect(decoded.summary, 'Completed excavation in pit 3');
      expect(decoded.notes, 'Crew finished early');
      expect(decoded.hazard.state, HazardState.present);
      expect(decoded.hazard.severity, HazardSeverity.high);
      expect(decoded.hazard.notes, 'Exposed high-voltage line');
      expect(decoded.hazard.correctiveAction, 'Erect barricades');
    });

    test('round-trip with hazard none', () {
      final log = DailyLog(
        id: 'dl-002',
        siteId: siteId,
        foremanId: foremanId,
        logDate: logDate,
        status: LogStatus.draft,
        summary: 'Normal shift',
        hazard: const HazardAssessment.none(),
      );

      final state = DailyLogFormState(log: log);
      final encoded = DailyLogDraftRestoration.encode(state);
      final decoded = DailyLogDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      expect(decoded!.hazard.state, HazardState.none);
      expect(decoded.hazard.severity, isNull);
    });

    test('version-mismatch fallback: v2 snapshot → null', () {
      final snapshot =
          '{"version":2,"siteId":"site-1","foremanId":"foreman-1",'
          '"date":"2026-10-10","status":"draft","zoneId":"zone-A",'
          '"weather":"Sunny","summary":"test","notes":"note","hazard":'
          '{"state":"none","severity":null,"hazardNotes":null,"correctiveAction":null}}';

      final decoded = DailyLogDraftRestoration.decode(
        snapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('version-mismatch fallback: malformed JSON → null', () {
      final decoded = DailyLogDraftRestoration.decode(
        'not valid json',
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('null snapshot → null', () {
      final decoded = DailyLogDraftRestoration.decode(null, siteId, foremanId);
      expect(decoded, isNull);
    });

    test('siteId mismatch → null', () {
      final log = DailyLog(
        id: 'dl-003',
        siteId: siteId,
        foremanId: foremanId,
        logDate: logDate,
        status: LogStatus.draft,
        summary: 'test',
        hazard: const HazardAssessment.none(),
      );
      final encoded = DailyLogDraftRestoration.encode(
        DailyLogFormState(log: log),
      );

      final decoded = DailyLogDraftRestoration.decode(
        encoded,
        'wrong-site',
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('foremanId mismatch → null', () {
      final log = DailyLog(
        id: 'dl-003',
        siteId: siteId,
        foremanId: foremanId,
        logDate: logDate,
        status: LogStatus.draft,
        summary: 'test',
        hazard: const HazardAssessment.none(),
      );
      final encoded = DailyLogDraftRestoration.encode(
        DailyLogFormState(log: log),
      );

      final decoded = DailyLogDraftRestoration.decode(
        encoded,
        siteId,
        'wrong-foreman',
      );
      expect(decoded, isNull);
    });

    test('status-gated restore: submitted snapshot → null', () {
      // 59.0 §5: restore is rejected for non-draft logs — the snapshot must
      // not pre-fulfill the hazard/approval contract.
      final snapshot =
          '{"version":1,"siteId":"site-1","foremanId":"foreman-1",'
          '"date":"2026-10-10","status":"submitted","zoneId":"zone-A",'
          '"weather":"Sunny","summary":"test","notes":"note","hazard":'
          '{"state":"none","severity":null,"hazardNotes":null,"correctiveAction":null}}';

      final decoded = DailyLogDraftRestoration.decode(
        snapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('status-gated restore: approved snapshot → null', () {
      final snapshot =
          '{"version":1,"siteId":"site-1","foremanId":"foreman-1",'
          '"date":"2026-10-10","status":"approved","zoneId":"zone-A",'
          '"weather":"Sunny","summary":"test","notes":"note","hazard":'
          '{"state":"none","severity":null,"hazardNotes":null,"correctiveAction":null}}';

      final decoded = DailyLogDraftRestoration.decode(
        snapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test(
      'hazard-validation-reruns-on-restore: invalid hazard '
      '(present without severity) is preserved as-entered, not normalized',
      () {
        // The snapshot stores the hazard *as entered*. An invalid combination
        // (present without severity) is NOT normalized away by decode — it is
        // preserved verbatim so the form's submit validator rejects it exactly
        // as it would for fresh input.
        final snapshot =
            '{"version":1,"siteId":"site-1","foremanId":"foreman-1",'
            '"date":"2026-10-10","status":"draft","zoneId":"zone-A",'
            '"weather":"Sunny","summary":"test","notes":"note","hazard":'
            '{"state":"present","severity":null,"hazardNotes":"Some notes",'
            '"correctiveAction":"Take action"}}';

        final decoded = DailyLogDraftRestoration.decode(
          snapshot,
          siteId,
          foremanId,
        );

        expect(decoded, isNotNull);
        // The invalid hazard (present + null severity) is preserved as-entered.
        expect(decoded!.hazard.state, HazardState.present);
        expect(decoded.hazard.severity, isNull);
        expect(decoded.hazard.notes, 'Some notes');
        expect(decoded.hazard.correctiveAction, 'Take action');
      },
    );

    test('missing required fields → null', () {
      final badSnapshot = '{"version":1,"siteId":"site-1"}';
      final decoded = DailyLogDraftRestoration.decode(
        badSnapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('malformed date → null', () {
      final snapshot =
          '{"version":1,"siteId":"site-1","foremanId":"foreman-1",'
          '"date":"not-a-date","status":"draft","zoneId":"zone-A",'
          '"weather":"Sunny","summary":"test","notes":"note","hazard":'
          '{"state":"none","severity":null,"hazardNotes":null,"correctiveAction":null}}';

      final decoded = DailyLogDraftRestoration.decode(
        snapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });
  });

  group('applyDailyLogSnapshot', () {
    test('applies ENTRY fields onto fresh base log, preserves CONTEXT', () {
      final base = DailyLog(
        id: 'base-id',
        siteId: siteId,
        foremanId: foremanId,
        logDate: DateTime(2026, 1, 1),
        zoneId: null,
        status: LogStatus.draft,
        summary: null,
        weather: null,
        notes: null,
        hazard: const HazardAssessment.notAssessed(),
      );

      final snapshot = DailyLogDraftRestoration(
        siteId: siteId,
        foremanId: foremanId,
        date: logDate,
        status: LogStatus.draft,
        zoneId: 'restored-zone',
        weather: 'Cloudy',
        summary: 'Restored summary',
        notes: 'Restored notes',
        hazard: const HazardAssessment(state: HazardState.none),
      );

      final restored = applyDailyLogSnapshot(base, snapshot);

      // ENTRY fields come from snapshot.
      expect(restored.logDate, logDate);
      expect(restored.zoneId, 'restored-zone');
      expect(restored.weather, 'Cloudy');
      expect(restored.summary, 'Restored summary');
      expect(restored.notes, 'Restored notes');
      expect(restored.hazard.state, HazardState.none);

      // CONTEXT fields preserved from base.
      expect(restored.id, 'base-id');
      expect(restored.siteId, siteId);
      expect(restored.foremanId, foremanId);
      expect(restored.status, LogStatus.draft);
    });
  });
}
