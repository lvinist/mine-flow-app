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

      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(FButton), findsOneWidget);
      expect(find.text('Tutup Semua'), findsOneWidget);
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
