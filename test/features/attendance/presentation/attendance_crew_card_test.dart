import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_crew_draft.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_state.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_crew_card.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

void main() {
  testWidgets('sync-state changes remain named live-region updates', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController();
    final focusNode = FocusNode();
    var state = AttendanceSyncState.queued;

    Widget buildCard() {
      return FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AttendanceCrewCard(
              draft: const AttendanceCrewDraft(
                userId: 'crew-1',
                userName: 'Alex',
                status: AttendanceStatus.present,
              ),
              syncState: state,
              reasonController: controller,
              reasonFocusNode: focusNode,
              onStatusSelected: (_) {},
              onRemarksChanged: (_, {clear = false}) {},
            ),
          ),
        ),
      );
    }

    try {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Status sinkronisasi: Menunggu sinkronisasi' &&
              widget.properties.liveRegion == true,
        ),
        findsOneWidget,
      );

      state = AttendanceSyncState.failed;
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Status sinkronisasi: Gagal sinkronisasi' &&
              widget.properties.liveRegion == true,
        ),
        findsOneWidget,
      );
    } finally {
      controller.dispose();
      focusNode.dispose();
      semantics.dispose();
    }
  });
}
