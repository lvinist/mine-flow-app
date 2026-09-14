import 'package:flutter/material.dart';
// Dashboard page — root landing for the Dashboard branch.
//
// STEP-31.3: Stripped of the old AppBar (the shell provides headers) and the
// full Quick Nav grid (features are now accessible via the sidebar/bottom nav).
// Retains the stats summary cards and adds 3 quick-access cards for the
// standalone push-on-top routes: Reports, Timeline, and Notifications.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_cubit.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_state.dart';
import 'package:mine_flow/core/constants/app_constants.dart';

const double _kPagePadding = 24;
const double _kCardPadding = 24;

// Responsive breakpoints
const double _kBreakMobile = 600;

/// The main dashboard page displayed at the root route.
///
/// Shows live stats summary cards and quick-access tiles for Reports, Timeline,
/// and Notifications — the three standalone full-screen shortcuts that push on
/// top of the shell.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<DashboardCubit>().loadDashboardStats(
            defaultSiteId,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(_kPagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Page title ---
              Semantics(
                header: true,
                child: Text(
                  'Dashboard',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Stat summary cards row ---
              Semantics(
                label: 'Statistik ringkasan',
                child: BlocBuilder<DashboardCubit, DashboardState>(
                  builder: (context, state) {
                    final isLoading = state.status == DashboardStatus.loading;
                    final isFailure = state.status == DashboardStatus.failure;

                    final activeCrewValue = state.hasData
                        ? '${state.activeCrewCount}'
                        : '-';
                    final cutFillValue = state.hasData
                        ? '${state.cutFillVolume.toStringAsFixed(0)} m³'
                        : '-';
                    final equipmentChecksValue = state.hasData
                        ? '${state.equipmentChecksCount}'
                        : '-';
                    final notificationsValue = state.hasData
                        ? '${state.unreadNotificationsCount}'
                        : '-';

                    final activeCrewSubtitle = (!state.hasData && isFailure)
                        ? 'Gagal memuat'
                        : (!state.hasData)
                        ? 'Memuat…'
                        : state.activeCrewCount == 0
                        ? 'Belum ada kru hadir' // Valid zero / CTA
                        : '${state.activeCrewCount} kru hari ini';
                    final cutFillSubtitle = (!state.hasData && isFailure)
                        ? 'Gagal memuat'
                        : (!state.hasData)
                        ? 'Memuat…'
                        : state.cutFillVolume == 0
                        ? 'Belum ada data volume' // Valid zero / CTA
                        : 'Volume setara bank hari ini';
                    final equipmentChecksSubtitle =
                        (!state.hasData && isFailure)
                        ? 'Gagal memuat'
                        : (!state.hasData)
                        ? 'Memuat…'
                        : state.equipmentChecksCount == 0
                        ? 'Belum ada pemeriksaan' // Valid zero / CTA
                        : '${state.equipmentChecksCount} pemeriksaan hari ini';
                    final notificationsSubtitle = (!state.hasData && isFailure)
                        ? 'Gagal memuat'
                        : (!state.hasData)
                        ? 'Memuat…'
                        : state.unreadNotificationsCount == 0
                        ? 'Tidak ada notifikasi baru'
                        : '${state.unreadNotificationsCount} belum dibaca';

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeOutQuart,
                      child: Column(
                        key: ValueKey('${isLoading}_$isFailure'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFailure)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FButton(
                                variant: FButtonVariant.outline,
                                prefix: const Icon(
                                  LucideIcons.refreshCcw,
                                  size: 16,
                                ),
                                onPress: () {
                                  context
                                      .read<DashboardCubit>()
                                      .loadDashboardStats(defaultSiteId);
                                },
                                child: const Text('Coba Lagi'),
                              ),
                            ),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _StatCard(
                                icon: LucideIcons.users,
                                label: 'Kru Aktif',
                                value: activeCrewValue,
                                subtitle: activeCrewSubtitle,
                                route: AppRoutes.attendance,
                              ),
                              _StatCard(
                                icon: LucideIcons.move,
                                label: 'Volume Setara Bank',
                                value: cutFillValue,
                                subtitle: cutFillSubtitle,
                                route: AppRoutes.cutFill,
                              ),
                              _StatCard(
                                icon: LucideIcons.wrench,
                                label: 'Pemeriksaan Alat',
                                value: equipmentChecksValue,
                                subtitle: equipmentChecksSubtitle,
                                route: AppRoutes.equipmentCheck,
                              ),
                              _StatCard(
                                icon: LucideIcons.bellRing,
                                label: 'Notifikasi',
                                value: notificationsValue,
                                subtitle: notificationsSubtitle,
                                route: AppRoutes.notifications,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),
              Semantics(
                header: true,
                child: Text(
                  'Akses Cepat',
                  style: theme.typography.display.xs.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ShortcutChip(
                    icon: LucideIcons.mountainSnow,
                    label: 'Land Clearing',
                    route: AppRoutes.landClearing,
                  ),
                  _ShortcutChip(
                    icon: LucideIcons.circleDot,
                    label: 'Benchmark DB',
                    route: AppRoutes.benchmarkDb,
                  ),
                  _ShortcutChip(
                    icon: LucideIcons.clipboardList,
                    label: 'Daily Log',
                    route: AppRoutes.dailyLog,
                  ),
                  _ShortcutChip(
                    icon: LucideIcons.boxes,
                    label: 'Inventory',
                    route: AppRoutes.inventory,
                  ),
                  _ShortcutChip(
                    icon: LucideIcons.fileArchive,
                    label: 'Data Bucket',
                    route: AppRoutes.dataBucket,
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
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
  final String route;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.route,
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
            button: true,
            onTapHint: 'Buka $label',
            child: InkWell(
              onTap: () => context.go(route),
              borderRadius: BorderRadius.circular(12),
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
                        style: theme.typography.display.sm.copyWith(
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
          ),
        );
      },
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _ShortcutChip({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Semantics(
      button: true,
      label: label,
      onTapHint: 'Buka $label',
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colors.mutedForeground.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
            color: theme.colors.background,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colors.foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
