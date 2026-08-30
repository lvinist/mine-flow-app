import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_state.dart';
import 'package:mine_flow/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationCubit extends MockCubit<NotificationState>
    implements NotificationCubit {}

void main() {
  late MockNotificationCubit mockNotificationCubit;

  final tNotifications = [
    AppNotification(
      id: 'n1',
      type: NotificationType.lowInventory,
      severity: NotificationSeverity.warning,
      title: 'Stok Solar Rendah',
      message: 'Sisa stok solar 150L',
      createdAt: DateTime(2026, 7, 25, 8, 0),
    ),
  ];

  setUp(() {
    mockNotificationCubit = MockNotificationCubit();
  });

  Widget buildTestWidget() {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        home: BlocProvider<NotificationCubit>.value(
          value: mockNotificationCubit,
          child: const NotificationListPage(),
        ),
      ),
    );
  }

  group('NotificationListPage Widget Tests', () {
    testWidgets('does not use raw TextButton for dismiss-all', (tester) async {
      when(() => mockNotificationCubit.state).thenReturn(
        NotificationLoaded(notifications: tNotifications, unreadCount: 1),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Contract: the dismiss-all control is a ForUI FButton, never a raw
      // Material TextButton (CF-032 / STEP-37 ForUI-only component contract).
      expect(find.byType(TextButton), findsNothing);
      // Scope to the dismiss-all button by its label. STEP-48.9 converted the
      // per-notification-card dismiss control from IconButton to FButton.icon,
      // so the page legitimately contains more than one FButton now; asserting
      // a single FButton across the whole tree is stale. The 'Tutup Semua'
      // button itself must be exactly one FButton.
      expect(
        find.widgetWithText(FButton, 'Tutup Semua'),
        findsOneWidget,
      );
    });

    testWidgets('triggers dismissAll on FButton tap', (tester) async {
      when(() => mockNotificationCubit.state).thenReturn(
        NotificationLoaded(notifications: tNotifications, unreadCount: 1),
      );
      when(() => mockNotificationCubit.dismissAll()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Tutup Semua'));
      await tester.pumpAndSettle();

      verify(() => mockNotificationCubit.dismissAll()).called(1);
    });
  });
}
