import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_state.dart';
import 'package:mine_flow/features/notifications/presentation/widgets/notification_banner.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationCubit extends MockCubit<NotificationState>
    implements NotificationCubit {}

void main() {
  late MockNotificationCubit mockNotificationCubit;

  final criticalNotification = AppNotification(
    id: 'n-crit-1',
    type: NotificationType.missingAttendance,
    severity: NotificationSeverity.critical,
    title: 'Absensi Belum Diisi',
    message: 'Perlu pengisian absensi segera',
    createdAt: DateTime(2026, 7, 25, 8, 0),
  );

  setUp(() {
    mockNotificationCubit = MockNotificationCubit();
  });

  Widget buildTestWidget() {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        home: Scaffold(
          body: BlocProvider<NotificationCubit>.value(
            value: mockNotificationCubit,
            child: const NotificationBanner(),
          ),
        ),
      ),
    );
  }

  group('NotificationBanner Widget Tests', () {
    testWidgets(
      'does not use MaterialBanner or TextButton when displaying critical notification',
      (tester) async {
        when(() => mockNotificationCubit.state).thenReturn(
          NotificationLoaded(
            notifications: [criticalNotification],
            unreadCount: 1,
          ),
        );

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(MaterialBanner), findsNothing);
        expect(find.byType(TextButton), findsNothing);
        expect(find.byType(Container), findsWidgets);
        expect(find.byType(FButton), findsOneWidget);
        expect(find.text('Perlu pengisian absensi segera'), findsOneWidget);
        expect(find.text('Tutup'), findsOneWidget);
      },
    );

    testWidgets('triggers dismiss on Tutup FButton tap', (tester) async {
      when(() => mockNotificationCubit.state).thenReturn(
        NotificationLoaded(
          notifications: [criticalNotification],
          unreadCount: 1,
        ),
      );
      when(
        () => mockNotificationCubit.dismiss('n-crit-1'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      verify(() => mockNotificationCubit.dismiss('n-crit-1')).called(1);
    });

    testWidgets(
      'renders SizedBox.shrink when no critical notifications present',
      (tester) async {
        when(() => mockNotificationCubit.state).thenReturn(
          const NotificationLoaded(notifications: [], unreadCount: 0),
        );

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(MaterialBanner), findsNothing);
        expect(find.byType(FButton), findsNothing);
      },
    );
  });
}
