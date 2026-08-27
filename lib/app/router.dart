// Top-level route definitions for mine-flow.
//
// Uses GoRouter (go_router package) with StatefulShellRoute for persistent
// navigation shell across 5 main branches:
//   Branch 0: Dashboard
//   Branch 1: Tools (Data Bucket)
//   Branch 2: Operations (Cut/Fill, Land Clearing, Benchmark DB)
//   Branch 3: Teams (Attendance, Daily Log, Inventory, Equipment Check)
//   Branch 4: Settings
//
// Navigation pattern per Doc 07 §4:
//   Web  → Collapsible left sidebar
//   Android → Bottom tab bar
//
// STEP-31.1: Restructured from 5 old branches (Dashboard, Data Bucket, Reports,
// Timeline, Notifications) to the new groupings above. Old push-on-top routes
// for feature screens are now nested inside their respective branches.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_cubit.dart';
import 'package:mine_flow/app/presentation/pages/dashboard_page.dart';
import 'package:mine_flow/app/presentation/pages/app_shell.dart';
import 'package:mine_flow/features/settings/presentation/pages/settings_page.dart';
import 'package:mine_flow/app/presentation/pages/group_landing_page.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/pages/login_page.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/data_bucket_list_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/upload_file_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/file_detail_page.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/pages/report_config_page.dart';
import 'package:mine_flow/features/reporting/presentation/pages/report_type_picker_page.dart';
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
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_page.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_list_screen.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_history_screen.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_check_form_screen.dart';
import 'package:mine_flow/features/benchmark/presentation/pages/benchmark_list_screen.dart';

/// Named route constants — use these instead of raw strings throughout the app.
abstract class AppRoutes {
  static const login = '/login';
  static const dashboard = '/';
  static const tools = '/tools';
  static const operations = '/operations';
  static const teams = '/teams';
  static const attendance = '/teams/attendance';
  static const attendanceForm = '/teams/attendance/form';
  static const cutFill = '/operations/cut-fill';
  static const landClearing = '/operations/land-clearing';
  static const dailyLog = '/teams/daily-log';
  static const inventory = '/teams/inventory';
  static const equipmentCheck = '/teams/equipment-check';
  static const equipmentCheckForm = '/teams/equipment-check/form';
  static const dataBucket = '/tools/data-bucket';
  static const dataBucketUpload = '/tools/data-bucket/upload';
  static const dataBucketDetail = '/tools/data-bucket/:id';
  static const reportConfig = '/reports/config';
  static const timeline = '/teams/timeline';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const benchmarkDb = '/operations/benchmark-db';
  static const benchmarkForm = '/operations/benchmark-db/form';
}

/// The application [GoRouter] instance.
///
/// Authentication redirect: if the user is not logged in they are redirected to
/// [AppRoutes.login]; an authenticated user is bounced off the login route to
/// the dashboard. The redirect re-evaluates whenever [authRevision] changes
/// (i.e. on every sign-in / sign-out).
final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  debugLogDiagnostics: true,
  refreshListenable: authRevision,
  redirect: (BuildContext context, GoRouterState state) {
    final user = authCubit?.state.user;
    final isLogin = state.matchedLocation == AppRoutes.login;
    if (user == null && !isLogin) return AppRoutes.login;
    if (user != null && isLogin) return AppRoutes.dashboard;
    return null;
  },
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
        // ================================================================
        // Branch 0: Dashboard
        // ================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  BlocProvider<DashboardCubit>(
                    create: (_) => DashboardCubit(
                      attendanceRepository: appServices!.attendanceRepository,
                      trackingRepository: appServices!.trackingRepository,
                      equipmentCheckRepository:
                          appServices!.equipmentCheckRepository,
                      notificationRepository:
                          appServices!.notificationRepository,
                    )..loadDashboardStats(defaultSiteId),
                    child: const DashboardPage(),
                  ),
            ),
          ],
        ),

        // ================================================================
        // Branch 1: Tools (Data Bucket)
        // ================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tools,
              name: 'tools',
              builder: (BuildContext context, GoRouterState state) =>
                  const GroupLandingPage(
                    title: 'Tools',
                    subtitle: 'Alat dan utilitas tambahan',
                    features: [
                      FeatureTileConfig(
                        label: 'Data Bucket',
                        description: 'Penyimpanan data geospasial',
                        icon: Icons.folder_zip_outlined,
                        route: AppRoutes.dataBucket,
                      ),
                    ],
                  ),
              routes: [
                GoRoute(
                  path: 'data-bucket',
                  name: 'data-bucket',
                  builder: (BuildContext context, GoRouterState state) {
                    return DataBucketListPage(
                      repository:
                          state.extra as DataBucketRepository? ??
                          _defaultDataBucketRepository(),
                      siteId: defaultSiteId,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'upload',
                      name: 'data-bucket-upload',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        return UploadFilePage(
                          repository:
                              extra?['repository'] as DataBucketRepository? ??
                              _defaultDataBucketRepository(),
                          siteId: extra?['siteId'] as String? ?? defaultSiteId,
                          driveService:
                              extra?['driveService'] as GoogleDriveService?,
                        );
                      },
                    ),
                    GoRoute(
                      path: ':id',
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
              ],
            ),
          ],
        ),

        // ================================================================
        // Branch 2: Operations (Cut/Fill, Land Clearing, Benchmark DB)
        // ================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.operations,
              name: 'operations',
              builder: (BuildContext context, GoRouterState state) =>
                  const GroupLandingPage(
                    title: 'Operations',
                    subtitle: 'Manajemen pelacakan operasi lapangan',
                    features: [
                      FeatureTileConfig(
                        label: 'Cut / Fill',
                        description: 'Volume & material',
                        icon: Icons.moving_outlined,
                        route: AppRoutes.cutFill,
                      ),
                      FeatureTileConfig(
                        label: 'Land Clearing',
                        description: 'Area pembukaan',
                        icon: Icons.landscape_outlined,
                        route: AppRoutes.landClearing,
                      ),
                      FeatureTileConfig(
                        label: 'Benchmark DB',
                        description: 'Database benchmark',
                        icon: Icons.trip_origin,
                        route: AppRoutes.benchmarkDb,
                      ),
                    ],
                  ),
              routes: [
                GoRoute(
                  path: 'cut-fill',
                  name: 'cut-fill',
                  builder: (BuildContext context, GoRouterState state) =>
                      CutFillListScreen(
                        repository: appServices!.trackingRepository,
                        siteId: defaultSiteId,
                        foremanId: currentUserId() ?? '',
                        zoneRepository: appServices!.zoneRepository,
                      ),
                ),
                GoRoute(
                  path: 'land-clearing',
                  name: 'land-clearing',
                  builder: (BuildContext context, GoRouterState state) =>
                      LandClearingSummaryScreen(
                        repository: appServices!.trackingRepository,
                        siteId: defaultSiteId,
                        foremanId: currentUserId() ?? '',
                        zoneRepository: appServices!.zoneRepository,
                      ),
                ),
                GoRoute(
                  path: 'benchmark-db',
                  name: 'benchmark-db',
                  builder: (BuildContext context, GoRouterState state) =>
                      BenchmarkListScreen(
                        repository: appServices!.benchmarkRepository,
                      ),
                ),
              ],
            ),
          ],
        ),

        // ================================================================
        // Branch 3: Teams (Attendance, Daily Log, Inventory, Eq Check)
        // ================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.teams,
              name: 'teams',
              builder: (BuildContext context, GoRouterState state) =>
                  const GroupLandingPage(
                    title: 'Teams',
                    subtitle: 'Kehadiran kru dan dokumentasi harian',
                    features: [
                      FeatureTileConfig(
                        label: 'Attendance',
                        description: 'Kehadiran kru',
                        icon: Icons.groups_outlined,
                        route: AppRoutes.attendance,
                      ),
                      FeatureTileConfig(
                        label: 'Daily Log',
                        description: 'Laporan lapangan',
                        icon: Icons.event_note_outlined,
                        route: AppRoutes.dailyLog,
                      ),
                      FeatureTileConfig(
                        label: 'Inventory',
                        description: 'Stok barang',
                        icon: Icons.inventory_2_outlined,
                        route: AppRoutes.inventory,
                      ),
                      FeatureTileConfig(
                        label: 'Equipment Check',
                        description: 'Inspeksi alat',
                        icon: Icons.build_outlined,
                        route: AppRoutes.equipmentCheck,
                      ),
                      FeatureTileConfig(
                        label: 'Timeline Pekerjaan',
                        description: 'Jadwal & progres',
                        icon: Icons.timeline_outlined,
                        route: AppRoutes.timeline,
                      ),
                    ],
                  ),
              routes: [
                GoRoute(
                  path: 'attendance',
                  name: 'attendance',
                  builder: (BuildContext context, GoRouterState state) =>
                      AttendanceScreen(
                        repository: appServices!.attendanceRepository,
                      ),
                  routes: [
                    GoRoute(
                      path: 'form',
                      name: 'attendance-form',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        return AttendanceFormPage(
                          repository:
                              extra?['repository'] as AttendanceRepository? ??
                              appServices!.attendanceRepository,
                          siteId: extra?['siteId'] as String? ?? defaultSiteId,
                          initialDate: extra?['date'] as DateTime?,
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'daily-log',
                  name: 'daily-log',
                  builder: (BuildContext context, GoRouterState state) =>
                      DailyLogListScreen(
                        repository: appServices!.dailyLogRepository,
                        zoneRepository: appServices!.zoneRepository,
                        foremanId: currentFilterForemanId(),
                        siteId: defaultSiteId,
                      ),
                ),
                GoRoute(
                  path: 'inventory',
                  name: 'inventory',
                  builder: (BuildContext context, GoRouterState state) =>
                      InventoryDashboardScreen(
                        repository: appServices!.trackingRepository,
                        siteId: defaultSiteId,
                      ),
                ),
                GoRoute(
                  path: 'equipment-check',
                  name: 'equipment-check',
                  builder: (BuildContext context, GoRouterState state) =>
                      EquipmentHistoryScreen(
                        repository: appServices!.equipmentCheckRepository,
                        siteId: defaultSiteId,
                        foremanId: currentUserId() ?? '',
                      ),
                  routes: [
                    GoRoute(
                      path: 'form',
                      name: 'equipment-check-form',
                      builder: (BuildContext context, GoRouterState state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        return EquipmentCheckFormScreen(
                          repository: appServices!.equipmentCheckRepository,
                          siteId: extra?['siteId'] as String? ?? defaultSiteId,
                          foremanId:
                              extra?['foremanId'] as String? ??
                              currentUserId() ??
                              '',
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'timeline',
                  name: 'timeline',
                  builder: (BuildContext context, GoRouterState state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    final repository =
                        extra?['repository'] as TimelineRepository?;
                    final siteId = extra?['siteId'] as String? ?? defaultSiteId;
                    return TimelinePage(
                      repository: repository ?? _defaultTimelineRepository(),
                      siteId: siteId,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // ================================================================
        // Branch 4: Settings
        // ================================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              builder: (BuildContext context, GoRouterState state) =>
                  const SettingsPage(),
            ),
          ],
        ),
      ],
    ),

    // --- Standalone authenticated routes (pushed on top of the shell) ---
    //
    // Timeline, Notifications, and Report Config live outside the shell branches so
    // they render as full-screen pages when pushed from the Dashboard or other
    // feature screens. Each route is a simple GoRoute that pushes on top of
    // the current shell context.
    GoRoute(
      path: AppRoutes.reportConfig,
      name: 'report-config',
      builder: (BuildContext context, GoRouterState state) {
        final reportType = state.extra as ReportType?;
        // CF-030: no report type → show a type-picker landing instead of a
        // dead-end, so Reports is reachable without another feature screen.
        if (reportType == null) {
          return const ReportTypePickerPage();
        }
        return BlocProvider<ReportCubit>(
          create: (_) =>
              ReportCubit(repository: appServices!.reportingRepository),
          child: ReportConfigPage(reportType: reportType),
        );
      },
    ),
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
