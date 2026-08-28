// E2E Critical User Journey: Attendance (STEP-45.4)
//
// Exercises attendance batch recording, status toggling, remarks editing,
// correct author/recorder attribution (CF-006/007/009 guards), update persistence,
// and summary card / list view reflection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_page.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/crew_roster_item.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/main.dart' as app_main;

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Attendance Journey (STEP-45.4)', () {
    testWidgets(
      'login, create attendance, assert correct author attribution, edit, and reflect in list E2E',
      (tester) async {
        if (!isStagingConfigured) {
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

        final storage = SecureStorageService();
        await storage.clearAll();

        // 1. Boot app and log in.
        await pumpApp(tester);
        await loginAsStagingUser(tester);

        expect(authCubit?.state.status, AuthStatus.authenticated);
        final currentUserIdVal = currentUserId();
        expect(currentUserIdVal, isNotNull);
        expect(currentUserIdVal, isNotEmpty);

        // 2. Navigate to Attendance screen.
        appRouter.go(AppRoutes.attendance);
        await tester.pumpAndSettle();

        expect(find.byType(AttendanceScreen), findsOneWidget);
        expect(find.byType(AttendanceSummaryCard), findsOneWidget);

        // 3. Open Attendance Form page via "Input Absensi" FAB.
        final inputAbsensiFab = find.widgetWithText(
          FloatingActionButton,
          'Input Absensi',
        );
        expect(inputAbsensiFab, findsOneWidget);
        await tester.tap(inputAbsensiFab);
        await tester.pumpAndSettle();

        expect(find.byType(AttendanceFormPage), findsOneWidget);

        // If roster is empty, load the debug default roster.
        final loadDefaultBtn = find.text('Muat Daftar Kru Default (Debug)');
        if (loadDefaultBtn.evaluate().isNotEmpty) {
          await tester.tap(loadDefaultBtn);
          await tester.pumpAndSettle();
        }

        expect(find.byType(CrewRosterItem), findsWidgets);

        // 4. Update status of the first crew member to 'Sakit'.
        final sakitChip = find.text('Sakit').first;
        await tester.tap(sakitChip);
        await tester.pumpAndSettle();

        // 5. Add remarks for that crew member.
        final editRemarksBtn = find.byTooltip('Tambah Catatan / Remarks').first;
        await tester.tap(editRemarksBtn);
        await tester.pumpAndSettle();

        // Enter text into the remarks dialog input using EditableText finder.
        final remarksEditable = find
            .descendant(
              of: find.byType(FDialog),
              matching: find.byType(EditableText),
            )
            .first;
        await tester.enterText(remarksEditable, 'Izin sakit shift pagi');
        await tester.pumpAndSettle();

        final simpanDialogBtn = find.descendant(
          of: find.byType(FDialog),
          matching: find.widgetWithText(FButton, 'Simpan'),
        );
        await tester.tap(simpanDialogBtn);
        await tester.pumpAndSettle();

        // 6. Save attendance batch.
        final saveBatchBtn = find.textContaining('Simpan Absensi');
        expect(saveBatchBtn, findsOneWidget);
        await tester.tap(saveBatchBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 7. Verify persistence and attribution (CF-006/007/009 guards).
        final now = DateTime.now();
        final savedRecords = await app_main.appServices!.attendanceRepository
            .getAttendanceForDate(now);

        expect(savedRecords, isNotEmpty);
        final recordedCrew = savedRecords.first;
        expect(recordedCrew.loggedBy, isNotNull);
        expect(recordedCrew.loggedBy, isNotEmpty);
        expect(recordedCrew.loggedBy, equals(currentUserIdVal));
        expect(recordedCrew.status, AttendanceStatus.sick);
        expect(recordedCrew.remarks, 'Izin sakit shift pagi');

        // 8. Assert AttendanceScreen list reflects the saved record.
        expect(find.byType(AttendanceScreen), findsOneWidget);
        expect(find.textContaining('Izin sakit shift pagi'), findsOneWidget);

        // 9. Edit flow: Re-open form and change status to 'Izin' (Leave).
        await tester.tap(
          find.widgetWithText(FloatingActionButton, 'Input Absensi'),
        );
        await tester.pumpAndSettle();

        final izinChip = find.text('Izin').first;
        await tester.tap(izinChip);
        await tester.pumpAndSettle();

        final updateSaveBtn = find.textContaining('Simpan Absensi');
        await tester.tap(updateSaveBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Confirm update in repository.
        final updatedRecords = await app_main.appServices!.attendanceRepository
            .getAttendanceForDate(now);
        final updatedCrew = updatedRecords.firstWhere(
          (r) => r.userId == recordedCrew.userId,
        );
        expect(updatedCrew.status, AttendanceStatus.leave);
        expect(updatedCrew.loggedBy, equals(currentUserIdVal));
      },
    );
  });
}
