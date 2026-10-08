import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/init/app_initializer.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_sheet.dart';
import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mine_flow/main.dart' as app_main;

/// External repositories are mocked; the production router and sheet are real.
class _Services extends Mock implements AppServices {}

class _Attendance extends Mock implements AttendanceRepository {}

class _Auth extends Mock implements AuthRepository {}

class _Settings extends Mock implements SettingsRepository {}

class _Notifications extends Mock implements NotificationRepository {}

class _Sync extends Mock implements SyncQueueManager {}

class _Queue extends Mock implements HiveCacheRepository<SyncQueueItem> {}

void main() {
  test('production shell has restoration scopes for every branch', () {
    final shell = appRouter.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;
    expect(shell.restorationScopeId, isNotNull);
    // The shell may be built via either `builder` or `pageBuilder`; what
    // matters for restoration is that the shell + branch scope ids exist.
    expect(shell.builder != null || shell.pageBuilder != null, isTrue);
    final scopes = shell.branches
        .map((branch) => branch.restorationScopeId)
        .toList();
    expect(scopes, everyElement(isNotNull));
    expect(scopes.toSet().length, scopes.length);
  });

  testWidgets('production attendance route restores URL and unsaved draft', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    registerFallbackValue(DateTime(2026));
    const site = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    const user = UserEntity(
      id: 'owner-1',
      email: 'owner@example.invalid',
      name: 'Owner',
      role: 'supervisor',
      siteId: site,
    );
    final authRepository = _Auth();
    when(() => authRepository.getCurrentUser()).thenAnswer((_) async => user);
    when(
      () => authRepository.getSiteRoster(siteId: any(named: 'siteId')),
    ).thenAnswer((_) async => [user]);
    final auth = AuthCubit(repository: authRepository);
    authCubit = auth;
    await auth.initialize();
    final settingsRepository = _Settings();
    when(
      () => settingsRepository.getThemeMode(),
    ).thenAnswer((_) async => ThemeMode.light);
    when(
      () => settingsRepository.getLocale(),
    ).thenAnswer((_) async => const Locale('id'));
    when(
      () => settingsRepository.getPrivacyAckVersion(),
    ).thenAnswer((_) async => 1);
    final settings = SettingsCubit(repository: settingsRepository);
    final repository = _Attendance();
    when(
      () =>
          repository.getAttendanceForDate(any(), siteId: any(named: 'siteId')),
    ).thenAnswer(
      (invocation) async => [
        AttendanceRecord(
          id: 'record-1',
          userId: user.id,
          siteId: site,
          date: invocation.positionalArguments.first as DateTime,
          status: AttendanceStatus.leave,
          remarks: 'saved reason',
        ),
      ],
    );
    final queue = _Queue();
    when(
      () => queue.watchAll(),
    ).thenAnswer((_) => const Stream<List<SyncQueueItem>>.empty());
    final sync = _Sync();
    when(() => sync.queueRepository).thenReturn(queue);
    final notifications = _Notifications();
    when(
      () => notifications.getActiveNotifications(),
    ).thenAnswer((_) async => <AppNotification>[]);
    when(() => notifications.getUnreadCount()).thenAnswer((_) async => 0);
    final services = _Services();
    when(() => services.attendanceRepository).thenReturn(repository);
    when(() => services.authRepository).thenReturn(authRepository);
    when(() => services.syncQueueManager).thenReturn(sync);
    when(() => services.notificationRepository).thenReturn(notifications);
    app_main.appServices = services;
    // ignore: prefer_const_declarations - interpolation is not a const expr
    final location = '/teams/attendance/form?date=2026-09-11&siteId=$site';
    appRouter.go(location);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: settings),
        ],
        child: FTheme(
          data: FTheme.neutral.light.touch,
          child: MaterialApp.router(
            restorationScopeId: 'app-root',
            routerConfig: appRouter,
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (_, child) => FToaster(child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceFormSheet), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('attendance_reason_field')),
      'route-restored draft',
    );
    await tester.pumpAndSettle();
    // The journey under test is OS process death: the widget tree is rebuilt
    // from restoration data, exactly as go_router's own tests simulate it via
    // restartAndRestore (the app's global appRouter is reused as the same
    // router instance would be in a restored process).
    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.toString(), location);
    expect(find.byType(AttendanceFormSheet), findsOneWidget);
    expect(find.text('route-restored draft'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    app_main.appServices = null;
    authCubit = null;
    await auth.close();
    await settings.close();
  });
}
