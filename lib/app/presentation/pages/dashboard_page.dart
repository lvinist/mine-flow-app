// Dashboard page — card-based stats summary in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.1): Replaced hand-rolled Material cards and
// hardcoded raw colors with ForUI components (FCard) and FTheme
// colors/typography tokens. No logic, state, or data-fetching changes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_cubit.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_state.dart';
import 'package:mine_flow/app/presentation/bloc/theme_cubit.dart';
import 'package:mine_flow/app/router.dart';

const double _kPagePadding = 24;
const double _kCardPadding = 24;

// Responsive breakpoints
const double _kBreakMobile = 600;
const double _kBreakTablet = 900;

/// The main dashboard page displayed at the root route.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            'Dashboard',
            style: theme.typography.display.xl.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle tema',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Stat summary cards row ---
            Semantics(
              label: 'Statistik ringkasan',
              child: BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  final isLoading =
                      state.status == DashboardStatus.loading ||
                      state.status == DashboardStatus.initial;
                  final isFailure = state.status == DashboardStatus.failure;

                  final activeCrewValue = isLoading
                      ? '-'
                      : '${state.activeCrewCount}';
                  final cutFillValue = isLoading
                      ? '-'
                      : '${state.cutFillVolume.toStringAsFixed(0)} m³';
                  final equipmentChecksValue = isLoading
                      ? '-'
                      : '${state.equipmentChecksCount}';
                  final notificationsValue = isLoading
                      ? '-'
                      : '${state.unreadNotificationsCount}';

                  final activeCrewSubtitle = isFailure
                      ? 'Gagal memuat'
                      : isLoading
                      ? 'Memuat…'
                      : '${state.activeCrewCount} crew today';
                  final cutFillSubtitle = isFailure
                      ? 'Gagal memuat'
                      : isLoading
                      ? 'Memuat…'
                      : "Today's total volume";
                  final equipmentChecksSubtitle = isFailure
                      ? 'Gagal memuat'
                      : isLoading
                      ? 'Memuat…'
                      : '${state.equipmentChecksCount} checks today';
                  final notificationsSubtitle = isFailure
                      ? 'Gagal memuat'
                      : isLoading
                      ? 'Memuat…'
                      : '${state.unreadNotificationsCount} unread';

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeOutQuart,
                    child: Wrap(
                      key: ValueKey('${isLoading}_$isFailure'),
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          icon: Icons.groups_outlined,
                          label: 'Active Crew',
                          value: activeCrewValue,
                          subtitle: activeCrewSubtitle,
                        ),
                        _StatCard(
                          icon: Icons.moving_outlined,
                          label: 'Cut / Fill Volume',
                          value: cutFillValue,
                          subtitle: cutFillSubtitle,
                        ),
                        _StatCard(
                          icon: Icons.build_outlined,
                          label: 'Equipment Checks',
                          value: equipmentChecksValue,
                          subtitle: equipmentChecksSubtitle,
                        ),
                        _StatCard(
                          icon: Icons.notifications_active_outlined,
                          label: 'Notifications',
                          value: notificationsValue,
                          subtitle: notificationsSubtitle,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // --- Section heading ---
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Quick Navigation',
                      style: theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Akses cepat ke semua fitur',
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Quick navigation cards ---
            const _QuickNavGrid(),
          ],
        ),
      ),
    );
  }
}

/// A single stat summary card built with FCard.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= _kBreakMobile
            ? 240.0
            : double.infinity;

        return SizedBox(
          width: cardWidth,
          child: Semantics(
            label: label,
            value: value,
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.all(_kCardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Semantics(
                          excludeSemantics: true,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colors.muted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              size: 22,
                              color: theme.colors.foreground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      style: theme.typography.display.xl2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _QuickNavGrid extends StatelessWidget {
  const _QuickNavGrid();

  @override
  Widget build(BuildContext context) {
    const navItems = [
      _NavItem(
        icon: Icons.description_outlined,
        label: 'Laporan',
        route: AppRoutes.reports,
      ),
      _NavItem(
        icon: Icons.timeline_outlined,
        label: 'Timeline Pekerjaan',
        route: AppRoutes.timeline,
      ),
      _NavItem(
        icon: Icons.notifications_outlined,
        label: 'Notifikasi',
        route: AppRoutes.notifications,
      ),
      _NavItem(
        icon: Icons.folder_outlined,
        label: 'Data Bucket',
        route: AppRoutes.dataBucket,
      ),
      _NavItem(
        icon: Icons.people_outlined,
        label: 'Absensi',
        route: AppRoutes.attendance,
      ),
      _NavItem(
        icon: Icons.assignment_outlined,
        label: 'Log Harian',
        route: AppRoutes.dailyLog,
      ),
      _NavItem(
        icon: Icons.auto_graph_outlined,
        label: 'Cut / Fill',
        route: AppRoutes.cutFill,
      ),
      _NavItem(
        icon: Icons.forest_outlined,
        label: 'Land Clearing',
        route: AppRoutes.landClearing,
      ),
      _NavItem(
        icon: Icons.inventory_2_outlined,
        label: 'Inventaris',
        route: AppRoutes.inventory,
      ),
      _NavItem(
        icon: Icons.handyman_outlined,
        label: 'Cek Alat',
        route: AppRoutes.equipmentCheck,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;
        final crossAxisCount = parentWidth >= _kBreakTablet
            ? 4
            : parentWidth >= _kBreakMobile
            ? 3
            : 2;

        return Semantics(
          label: 'Navigasi cepat',
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: navItems.map((item) {
              return _NavCard(
                icon: item.icon,
                label: item.label,
                onTap: () => context.push(item.route),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _NavCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavCard> createState() => _NavCardState();
}

class _NavCardState extends State<_NavCard> {
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Semantics(
      label: widget.label,
      button: true,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: FCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    excludeSemantics: true,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colors.muted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 24,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
