import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// STEP-55.6 structured hazard contract tests (spec §4.5 item 7 /
/// FC-54.6-002): entity semantics, DTO/Hive JSON round-trips, and the
/// explicit no-hazard state — before any UI claims persistence.
void main() {
  group('HazardAssessment', () {
    test('default is not-assessed (pre-upgrade rows read back correctly)', () {
      const hazard = HazardAssessment.notAssessed();
      expect(hazard.state, HazardState.notAssessed);
      expect(hazard.severity, isNull);
      expect(hazard.isValid, isTrue);
    });

    test('explicit none state is valid without severity/notes', () {
      const hazard = HazardAssessment.none();
      expect(hazard.state, HazardState.none);
      expect(hazard.isValid, isTrue);
    });

    test('present requires severity to be valid', () {
      const noSeverity = HazardAssessment(state: HazardState.present);
      expect(noSeverity.isValid, isFalse);

      const withSeverity = HazardAssessment(
        state: HazardState.present,
        severity: HazardSeverity.high,
      );
      expect(withSeverity.isValid, isTrue);
    });

    test('normalized drops severity/notes/action unless present', () {
      const incoherent = HazardAssessment(
        state: HazardState.none,
        severity: HazardSeverity.low,
        notes: '  leftover  ',
        correctiveAction: 'stale action',
      );
      final normalized = incoherent.normalized();
      expect(normalized.severity, isNull);
      expect(normalized.notes, isNull);
      expect(normalized.correctiveAction, isNull);
      expect(normalized.state, HazardState.none);
    });

    test('normalized trims present-state notes to null when blank', () {
      const blank = HazardAssessment(
        state: HazardState.present,
        severity: HazardSeverity.critical,
        notes: '   ',
      );
      expect(blank.normalized().notes, isNull);
    });

    test('severity enum round-trips through its wire values', () {
      const wire = ['low', 'medium', 'high', 'critical'];
      for (final value in wire) {
        final severity = HazardSeverityValue.fromString(value);
        expect(severity, isNotNull, reason: value);
        expect(severity!.toValue(), value);
      }
      expect(HazardSeverityValue.fromString('bogus'), isNull);
      expect(HazardSeverityValue.fromString(null), isNull);
    });

    test('state enum round-trips through its wire values', () {
      expect(HazardStateValue.fromString('none'), HazardState.none);
      expect(HazardStateValue.fromString('present'), HazardState.present);
      expect(
        HazardStateValue.fromString('not_assessed'),
        HazardState.notAssessed,
      );
      // Unknown/legacy values degrade to the domain default, matching the
      // migration's NOT NULL DEFAULT 'not_assessed'.
      expect(HazardStateValue.fromString('bogus'), HazardState.notAssessed);
      expect(HazardStateValue.fromString(null), HazardState.notAssessed);
    });
  });

  group('DailyLogDto hazard round-trip', () {
    final tDate = DateTime(2026, 9, 12);

    DailyLogDto dtoFor(HazardAssessment hazard) => DailyLogDto(
      id: 'log-1',
      siteId: 'site-1',
      foremanId: 'foreman-1',
      logDate: tDate,
      status: LogStatus.draft.toValue(),
      hazardState: hazard.state.toValue(),
      hazardSeverity: hazard.severity?.toValue(),
      hazardNotes: hazard.notes,
      hazardAction: hazard.correctiveAction,
    );

    test('explicit none persists as hazard_state=none (never null)', () {
      final json = dtoFor(const HazardAssessment.none()).toJson();
      expect(json['hazard_state'], 'none');
      expect(json['hazard_severity'], isNull);
      // Round-trip preserves the explicit absence.
      final back = DailyLogDto.fromJson(json).toDomain();
      expect(back.hazard.state, HazardState.none);
      expect(back.hazard.severity, isNull);
    });

    test('present with severity/notes/action round-trips losslessly', () {
      const hazard = HazardAssessment(
        state: HazardState.present,
        severity: HazardSeverity.high,
        notes: 'Lereng tidak stabil',
        correctiveAction: 'Pasang penahan',
      );
      final back = DailyLogDto.fromJson(dtoFor(hazard).toJson()).toDomain();
      expect(back.hazard.state, HazardState.present);
      expect(back.hazard.severity, HazardSeverity.high);
      expect(back.hazard.notes, 'Lereng tidak stabil');
      expect(back.hazard.correctiveAction, 'Pasang penahan');
    });

    test('legacy JSON without hazard columns reads back as not_assessed', () {
      // A pre-migration row (or stale offline payload) carries no hazard
      // keys; the DTO must degrade to the domain default, never crash.
      final json = {
        'id': 'legacy-1',
        'site_id': 'site-1',
        'foreman_id': 'foreman-1',
        'log_date': tDate.toIso8601String(),
        'status': 'draft',
      };
      final back = DailyLogDto.fromJson(json).toDomain();
      expect(back.hazard.state, HazardState.notAssessed);
      expect(back.hazard.severity, isNull);
    });

    test('toDomain normalizes through HazardAssessment contract', () {
      // The DTO constructor can carry an incoherent combination (severity
      // without present); toDomain's normalized() twin keeps the entity
      // coherent regardless of the transport shape.
      final dto = DailyLogDto(
        id: 'log-x',
        siteId: 'site-1',
        foremanId: 'foreman-1',
        logDate: tDate,
        status: LogStatus.draft.toValue(),
        hazardState: 'none',
        hazardSeverity: 'low',
        hazardNotes: 'leftover',
      );
      final back = dto.toDomain();
      expect(back.hazard.state, HazardState.none);
      expect(back.hazard.severity, isNull);
      expect(back.hazard.notes, isNull);
    });
  });

  group('DailyLog hazard + workflow semantics', () {
    final tDate = DateTime(2026, 9, 12);

    test('canSubmit requires the hazard question to be answered', () {
      final unanswered = DailyLog(
        id: 'l1',
        siteId: 's',
        foremanId: 'f',
        logDate: tDate,
        status: LogStatus.draft,
        hazard: const HazardAssessment.notAssessed(),
      );
      expect(unanswered.canSubmit, isFalse);

      final answered = unanswered.copyWith(
        hazard: const HazardAssessment.none(),
      );
      expect(answered.canSubmit, isTrue);
    });

    test('canApprove is exactly submitted', () {
      DailyLog log(HazardAssessment hazard, LogStatus status) => DailyLog(
        id: 'l',
        siteId: 's',
        foremanId: 'f',
        logDate: tDate,
        status: status,
        hazard: hazard,
      );
      expect(
        log(const HazardAssessment.none(), LogStatus.draft).canApprove,
        isFalse,
      );
      expect(
        log(const HazardAssessment.none(), LogStatus.submitted).canApprove,
        isTrue,
      );
      expect(
        log(const HazardAssessment.none(), LogStatus.approved).canApprove,
        isFalse,
      );
    });

    test('transition machine allows only the forward path', () {
      expect(LogStatus.draft.canTransitionTo(LogStatus.submitted), isTrue);
      expect(LogStatus.draft.canTransitionTo(LogStatus.approved), isFalse);
      expect(LogStatus.submitted.canTransitionTo(LogStatus.approved), isTrue);
      expect(LogStatus.submitted.canTransitionTo(LogStatus.draft), isFalse);
      expect(LogStatus.approved.canTransitionTo(LogStatus.draft), isFalse);
      expect(LogStatus.approved.canTransitionTo(LogStatus.submitted), isFalse);
      expect(LogStatus.approved.canTransitionTo(LogStatus.approved), isTrue);
    });
  });
}
