// Dashboard page — card-based stats summary inspired by shadcn-admin.
//
// Replaces the old `_DashboardPlaceholder` grid-of-icons with a premium
// dashboard layout: a top row of stat summary cards and quick navigation
// links below. Uses placeholder (dummy) values for now; real repository
// data will be wired in a later STEP.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_cubit.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_state.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/app/theme/app_theme.dart';

/// The main dashboard page displayed at the root route.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Stat summary cards row (backed by DashboardCubit) ---
            BlocBuilder<DashboardCubit, DashboardState>(
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
                    : 'Today\'s total volume';
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

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isWide ? 240 : double.infinity,
                      child: _StatCard(
                        icon: Icons.groups_outlined,
                        label: 'Active Crew',
                        value: activeCrewValue,
                        subtitle: activeCrewSubtitle,
                        accentColor: const Color(0xFF166534),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 240 : double.infinity,
                      child: _StatCard(
                        icon: Icons.moving_outlined,
                        label: 'Cut / Fill Volume',
                        value: cutFillValue,
                        subtitle: cutFillSubtitle,
                        accentColor: const Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 240 : double.infinity,
                      child: _StatCard(
                        icon: Icons.build_outlined,
                        label: 'Equipment Checks',
                        value: equipmentChecksValue,
                        subtitle: equipmentChecksSubtitle,
                        accentColor: const Color(0xFFD97706),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 240 : double.infinity,
                      child: _StatCard(
                        icon: Icons.notifications_active_outlined,
                        label: 'Notifications',
                        value: notificationsValue,
                        subtitle: notificationsSubtitle,
                        accentColor: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),

            // --- Section divider ---
            const Divider(height: 32),

            // --- Section heading ---
            Text(
              'Quick Navigation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Akses cepat ke semua fitur',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // --- Quick navigation cards ---
            _QuickNavGrid(isWide: isWide),
          ],
        ),
      ),
    );
  }
}

/// A single stat summary card with icon, label, value, and accent colour.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: kBorderRadius,
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + label row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: kBorderRadius,
                  ),
                  child: Icon(icon, size: 22, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Value
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The grid of quick-navigation cards (reports, timeline, notifications, data bucket).
class _QuickNavGrid extends StatelessWidget {
  final bool isWide;

  const _QuickNavGrid({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Existing cards
        _NavCard(
          icon: Icons.description_outlined,
          label: 'Laporan',
          color: const Color(0xFF2563EB),
          onTap: () => context.push(AppRoutes.reports),
        ),
        _NavCard(
          icon: Icons.timeline_outlined,
          label: 'Timeline Pekerjaan',
          color: const Color(0xFF166534),
          onTap: () => context.push(AppRoutes.timeline),
        ),
        _NavCard(
          icon: Icons.notifications_outlined,
          label: 'Notifikasi',
          color: const Color(0xFFD97706),
          onTap: () => context.push(AppRoutes.notifications),
        ),
        _NavCard(
          icon: Icons.folder_outlined,
          label: 'Data Bucket',
          color: const Color(0xFF7C3AED),
          onTap: () => context.push(AppRoutes.dataBucket),
        ),
        // New capability cards
        _NavCard(
          icon: Icons.people_outlined,
          label: 'Absensi',
          color: const Color(0xFF0891B2),
          onTap: () => context.push(AppRoutes.attendance),
        ),
        _NavCard(
          icon: Icons.assignment_outlined,
          label: 'Log Harian',
          color: const Color(0xFF7C3AED),
          onTap: () => context.push(AppRoutes.dailyLog),
        ),
        _NavCard(
          icon: Icons.auto_graph_outlined,
          label: 'Cut / Fill',
          color: const Color(0xFF2563EB),
          onTap: () => context.push(AppRoutes.cutFill),
        ),
        _NavCard(
          icon: Icons.forest_outlined,
          label: 'Land Clearing',
          color: const Color(0xFF166534),
          onTap: () => context.push(AppRoutes.landClearing),
        ),
        _NavCard(
          icon: Icons.inventory_2_outlined,
          label: 'Inventaris',
          color: const Color(0xFFD97706),
          onTap: () => context.push(AppRoutes.inventory),
        ),
        _NavCard(
          icon: Icons.handyman_outlined,
          label: 'Cek Alat',
          color: const Color(0xFFDC2626),
          onTap: () => context.push(AppRoutes.equipmentCheck),
        ),
      ],
    );
  }
}

/// A single quick-navigation card (icon + label).
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: kBorderRadius,
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: kBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
