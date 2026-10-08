import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_state.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_sheet.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_crew_card.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

const _site = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
final _date = DateTime(2026, 9, 11);

/// Fixed persisted baseline; unsaved edits cannot leak through this fake.
class _Repository extends Fake implements AttendanceRepository {
  _Repository({this.status = AttendanceStatus.leave});
  final AttendanceStatus status;
  String savedRemarks = 'saved reason';
  int? failOnLoad;
  final List<List<AttendanceRecord>> writes = [];
  final List<DateTime> loads = [];

  @override
  Future<List<AttendanceRecord>> getAttendanceForDate(
    DateTime date, {
    String? siteId,
  }) async {
    loads.add(date);
    if (loads.length == failOnLoad) throw StateError('restore read failed');
    return [
      AttendanceRecord(
        id: '6e60b2e2-0000-4000-8000-000000005656',
        siteId: siteId ?? _site,
        userId: 'crew-1',
        date: date,
        status: status,
        remarks: status == AttendanceStatus.leave ? savedRemarks : null,
      ),
    ];
  }

  @override
  Future<void> saveAttendanceBatch(List<AttendanceRecord> records) async {
    writes.add(List.of(records));
  }
}

/// Builds the real sheet beneath the framework restoration channel.
Future<void> _pump(WidgetTester tester, _Repository repository) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        restorationScopeId: 'test-root',
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (_, child) => FToaster(child: child!),
        home: AttendanceFormSheet(
          repository: repository,
          initialDate: _date,
          siteId: _site,
          onClose: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Reads the real editable draft, not a controller-only assertion.
AttendanceFormBloc _bloc(WidgetTester tester) =>
    tester.element(find.byType(AttendanceCrewCard)).read<AttendanceFormBloc>();
AttendanceFormLoaded _state(WidgetTester tester) =>
    _bloc(tester).state as AttendanceFormLoaded;

/// Exercises the SDK restoration channel and reloads the production sheet.
Future<void> _restart(WidgetTester tester) async {
  await tester.restartAndRestore();
  await tester.pumpAndSettle();
  expect(find.byType(AttendanceCrewCard), findsOneWidget);
}

void main() {
  testWidgets('clean snapshot reloads fresh persisted values', (tester) async {
    final repository = _Repository();
    await _pump(tester, repository);
    repository.savedRemarks = 'new server value';
    await _restart(tester);
    expect(_state(tester).drafts.single.remarks, 'new server value');
    expect(find.text('new server value'), findsOneWidget);
    expect(_state(tester).isDirty, isFalse);
  });

  testWidgets('restoration load failure shows recoverable error, not spinner', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(tester, repository);
    await tester.enterText(
      find.byKey(const Key('attendance_reason_field')),
      'draft',
    );
    await tester.pumpAndSettle();
    repository.failOnLoad = repository.loads.length + 2;
    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(find.textContaining('restore read failed'), findsOneWidget);
    expect(find.byType(FCircularProgress), findsNothing);
  });

  testWidgets('unsaved reason restores into dirty draft and saved payload', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(tester, repository);
    await tester.enterText(
      find.byKey(const Key('attendance_reason_field')),
      'unsaved restored reason',
    );
    await tester.pumpAndSettle();
    await _restart(tester);
    expect(find.text('unsaved restored reason'), findsOneWidget);
    expect(_state(tester).drafts.single.remarks, 'unsaved restored reason');
    expect(_state(tester).isDirty, isTrue);
    expect(
      tester
          .widget<AppResponsiveSheet>(find.byType(AppResponsiveSheet))
          .isDirty,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('save_attendance_batch_button')));
    await tester.pumpAndSettle();
    expect(repository.writes.single.single.remarks, 'unsaved restored reason');
    expect(repository.writes.single.single.date, _date);
  });

  testWidgets('changed status and reason restore together', (tester) async {
    final repository = _Repository(status: AttendanceStatus.present);
    await _pump(tester, repository);
    await tester.tap(find.text('Izin'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('attendance_reason_field')),
      'leave draft',
    );
    await tester.pumpAndSettle();
    await _restart(tester);
    expect(_state(tester).drafts.single.status, AttendanceStatus.leave);
    expect(_state(tester).drafts.single.remarks, 'leave draft');
    expect(find.text('leave draft'), findsOneWidget);
  });

  testWidgets('selected date and draft restore without wrong-day writes', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(tester, repository);
    final selectedDate = DateTime(2026, 9, 12);
    _bloc(tester).add(AttendanceFormDateChanged(selectedDate));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('attendance_reason_field')),
      'next-day draft',
    );
    await tester.pumpAndSettle();
    await _restart(tester);
    expect(_state(tester).date, selectedDate);
    expect(repository.loads.last, selectedDate);
    await tester.tap(find.byKey(const Key('save_attendance_batch_button')));
    await tester.pumpAndSettle();
    expect(repository.writes.single.single.date, selectedDate);
    expect(repository.writes.single.single.remarks, 'next-day draft');
  });

  testWidgets(
    'explicit empty reason stays empty and cannot save after restore',
    (tester) async {
      final repository = _Repository();
      await _pump(tester, repository);
      await tester.enterText(
        find.byKey(const Key('attendance_reason_field')),
        '',
      );
      await tester.pumpAndSettle();
      await _restart(tester);
      expect(find.text('saved reason'), findsNothing);
      expect(_state(tester).drafts.single.trimmedRemarks, isNull);
      expect(_state(tester).isDirty, isTrue);
      await tester.tap(find.byKey(const Key('save_attendance_batch_button')));
      await tester.pumpAndSettle();
      expect(repository.writes, isEmpty);
      expect(_state(tester).firstInvalidUserId, 'crew-1');
    },
  );
}
