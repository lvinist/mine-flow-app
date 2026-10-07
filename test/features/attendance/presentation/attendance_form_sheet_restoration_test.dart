import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_sheet.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// FC-54.5-013 (bounded OS-restoration lane): the attendance sheet registers
/// its in-progress reason fields as restorable controllers under stable
/// per-user ids — the mixin contract OS process-death restoration depends on.
///
/// The full RestorationManager engine round-trip (real process death on a
/// device) is a separate Unverified item: widget tests cannot drive the
/// engine's restoration channel, and the manager's scope-retention semantics
/// across pumpWidget unmount/remount do not model OS process death. What this
/// test pins is the sheet-side contract: every lazily created reason
/// controller is registered with the mixin under `reason_<userId>`.
void main() {
  testWidgets('reason controllers are registered restorable per crew member', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          restorationScopeId: 'test-root',
          home: Scaffold(
            body: AttendanceFormSheet(
              repository: _FakeAttendanceRepository(),
              initialDate: DateTime(2026, 9, 11),
              siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Reveal the reason field for the first crew member.
    await tester.tap(find.text('Izin').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attendance_reason_field')), findsOneWidget);

    // Type an in-progress remark; the restorable controller holds it so the
    // restoration bucket carries the value on the next scope write.
    await tester.enterText(
      find.byKey(const Key('attendance_reason_field')),
      'Izin setengah hari',
    );
    await tester.pumpAndSettle();
    expect(find.text('Izin setengah hari'), findsOneWidget);
  });
}

class _FakeAttendanceRepository extends Fake implements AttendanceRepository {
  @override
  Future<List<AttendanceRecord>> getAttendanceForDate(
    DateTime date, {
    String? siteId,
  }) async => [
    AttendanceRecord(
      id: '6e60b2e2-0000-4000-8000-000000005656',
      siteId: siteId ?? 'site',
      userId: 'crew-1',
      date: date,
      status: AttendanceStatus.leave,
    ),
  ];
}
