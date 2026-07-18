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
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/auth/presentation/pages/login_page.dart';

/// Named route constants — use these instead of raw strings throughout the app.
abstract class AppRoutes {
  static const login = '/login';
  static const dashboard = '/';
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
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (BuildContext context, GoRouterState state) =>
          const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      // TODO(STEP-4): Replace with real dashboard shell once features land.
      builder: (BuildContext context, GoRouterState state) =>
          const _DashboardPlaceholder(),
    ),
  ],
);

/// Temporary placeholder shown at the dashboard route until feature shells
/// are built in STEP-4 through STEP-9.
class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('mine-flow — Dashboard (coming in STEP-4)'),
      ),
    );
  }
}
