// Top-level route definitions for mine-flow.
//
// Uses GoRouter (go_router package) for declarative navigation.
// Routes are split by role surface:
//   - Web (Supervisor): sidebar layout, management pages
//   - Android (Foreman/Crew): bottom-tab layout, field pages
//
// Navigation pattern per Doc 07 — UI / Design System, §4 Navigation & Layout:
//   Web  → Collapsible left sidebar
//   Android → Bottom tab bar

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/pages/dashboard_page.dart';
import 'package:mine_flow/app/presentation/widgets/app_shell.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/features/auth/presentation/pages/login_page.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/data_bucket_list_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/upload_file_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/file_detail_page.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/pages/report_dashboard_page.dart';
import 'package:mine_flow/features/reporting/presentation/pages/report_config_page.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:mine_flow/features/timeline/presentation/pages/timeline_page.dart';
import 'package:mine_flow/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:mine_flow/main.dart';
import 'package:mine_flow/features/tracking/presentation/pages/cut_fill_list_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_list_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_dashboard_screen.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_list_screen.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_history_screen.dart';

/// Named route constants — use these instead of raw strings throughout the app.
abstract class AppRoutes {
  static const login = '/login';
  static const dashboard = '/';
  static const attendance = '/attendance';
  static const cutFill = '/cut-fill';
  static const landClearing = '/land-clearing';
  static const dailyLog = '/daily-log';
  static const inventory = '/inventory';
  static const equipmentCheck = '/equipment-check';
  static const dataBucket = '/data-bucket';
  static const dataBucketUpload = '/data-bucket/upload';
  static const dataBucketDetail = '/data-bucket/:id';
  static const reports = '/reports';
  static const reportConfig = '/reports/config';
  static const timeline = '/timeline';
  static const notifications = '/notifications';
}

/// The application [GoRouter] instance.
///
/// Authentication redirect: if the user is not logged in they are redirected to
/// [AppRoutes.login]. The actual auth-state listener is wired in STEP-3 when
/// the Supabase auth BLoC is added.
final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  debugLogDiagnostics: true,
  routes: [
    // --- Unauthenticated routes (no shell) ---
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (BuildContext context, GoRouterState state) => const LoginPage(),
    ),

    // --- Authenticated routes wrapped in responsive shell ---
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) => AppShell(navigationShell: navigationShell),
      branches: [
        // Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const DashboardPage(),
            ),
          ],
        ),

        // Data Bucket
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dataBucket,
              name: 'data-bucket',
              builder: (BuildContext context, GoRouterState state) {
                return DataBucketListPage(
                  repository:
                      state.extra as DataBucketRepository? ??
                      _defaultDataBucketRepository(),
                  siteId: defaultSiteId,
                );
              },
            ),
            GoRoute(
              path: AppRoutes.dataBucketUpload,
              name: 'data-bucket-upload',
              builder: (BuildContext context, GoRouterState state) {
                final extra = state.extra as Map<String, dynamic>?;
                return UploadFilePage(
                  repository:
                      extra?['repository'] as DataBucketRepository? ??
                      _defaultDataBucketRepository(),
                  siteId: extra?['siteId'] as String? ?? defaultSiteId,
                  driveService: extra?['driveService'] as GoogleDriveService?,
                );
              },
            ),
            GoRoute(
              path: AppRoutes.dataBucketDetail,
              name: 'data-bucket-detail',
              builder: (BuildContext context, GoRouterState state) {
                final extra = state.extra as Map<String, dynamic>?;
                final file = extra?['file'] as GeospatialFile?;
                if (file == null) {
                  return const Scaffold(
                    body: Center(child: Text('File tidak ditemukan.')),
                  );
                }
                return FileDetailPage(
                  file: file,
                  repository:
                      extra?['repository'] as DataBucketRepository? ??
                      _defaultDataBucketRepository(),
                );
              },
            ),
          ],
        ),

        // Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.reports,
              name: 'reports',
              builder: (BuildContext context, GoRouterState state) =>
                  const ReportDashboardPage(),
            ),
            GoRoute(
              path: AppRoutes.reportConfig,
              name: 'report-config',
              builder: (BuildContext context, GoRouterState state) {
                final reportType = state.extra as ReportType?;
                if (reportType == null) {
                  return const Scaffold(
                    body: Center(child: Text('Jenis laporan tidak ditemukan.')),
                  );
                }
                return BlocProvider<ReportCubit>(
                  create: (_) =>
                      ReportCubit(repository: appServices!.reportingRepository),
                  child: ReportConfigPage(reportType: reportType),
                );
              },
            ),
          ],
        ),

        // Timeline
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.timeline,
              name: 'timeline',
              builder: (BuildContext context, GoRouterState state) {
                final extra = state.extra as Map<String, dynamic>?;
                final repository = extra?['repository'] as TimelineRepository?;
                final siteId = extra?['siteId'] as String? ?? defaultSiteId;
                return TimelinePage(
                  repository: repository ?? _defaultTimelineRepository(),
                  siteId: siteId,
                );
              },
            ),
          ],
        ),

        // Notifications
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.notifications,
              name: 'notifications',
              builder: (BuildContext context, GoRouterState state) =>
                  BlocProvider<NotificationCubit>(
                    create: (_) => NotificationCubit(
                      repository: appServices!.notificationRepository,
                      siteId: defaultSiteId,
                    )..loadNotifications(),
                    child: const NotificationListPage(),
                  ),
            ),
          ],
        ),
      ],
    ),

    // --- Push-on-top routes (navigated from Dashboard quick nav cards) ---
    GoRoute(
      path: AppRoutes.attendance,
      name: 'attendance',
      builder: (BuildContext context, GoRouterState state) =>
          AttendanceScreen(repository: appServices!.attendanceRepository),
    ),
    GoRoute(
      path: AppRoutes.cutFill,
      name: 'cut-fill',
      builder: (BuildContext context, GoRouterState state) => CutFillListScreen(
        repository: appServices!.trackingRepository,
        siteId: defaultSiteId,
        foremanId: '',
      ),
    ),
    GoRoute(
      path: AppRoutes.landClearing,
      name: 'land-clearing',
      builder: (BuildContext context, GoRouterState state) =>
          LandClearingSummaryScreen(
            repository: appServices!.trackingRepository,
            siteId: defaultSiteId,
            foremanId: '',
          ),
    ),
    GoRoute(
      path: AppRoutes.dailyLog,
      name: 'daily-log',
      builder: (BuildContext context, GoRouterState state) =>
          DailyLogListScreen(
            repository: appServices!.dailyLogRepository,
            foremanId: '',
            siteId: defaultSiteId,
          ),
    ),
    GoRoute(
      path: AppRoutes.inventory,
      name: 'inventory',
      builder: (BuildContext context, GoRouterState state) =>
          InventoryDashboardScreen(
            repository: appServices!.trackingRepository,
            siteId: defaultSiteId,
          ),
    ),
    GoRoute(
      path: AppRoutes.equipmentCheck,
      name: 'equipment-check',
      builder: (BuildContext context, GoRouterState state) =>
          EquipmentHistoryScreen(
            repository: appServices!.equipmentCheckRepository,
            siteId: defaultSiteId,
            foremanId: '',
          ),
    ),
  ],
);

/// Creates a default [DataBucketRepository] for route building.
DataBucketRepository _defaultDataBucketRepository() {
  if (appServices != null) {
    return appServices!.dataBucketRepository;
  }
  throw UnimplementedError(
    'DataBucketRepository not wired and appServices is null.',
  );
}

/// Creates a default [TimelineRepository] for route building.
TimelineRepository _defaultTimelineRepository() {
  if (appServices != null) {
    return appServices!.timelineRepository;
  }
  throw UnimplementedError(
    'TimelineRepository not wired and appServices is null.',
  );
}
