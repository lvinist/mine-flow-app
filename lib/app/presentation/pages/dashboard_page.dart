// Dashboard page — root landing for the Dashboard branch.
//
// STEP-31.3: Stripped of the old AppBar (the shell provides headers) and the
// full Quick Nav grid (features are now accessible via the sidebar/bottom nav).
// Retains the stats summary cards and adds 3 quick-access cards for the
// standalone push-on-top routes: Reports, Timeline, and Notifications.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_cubit.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_state.dart';

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

    return Scaffold(
      body: SingleChildScrollView(
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
                      : '${state.activeCrewCount} kru hari ini';
                  final cutFillSubtitle = isFailure
                      ? 'Gagal memuat'
                      : isLoading
                      ? 'Memuat…'
                      : 'Volume setara bank hari ini';
                  final equipmentChecksSubtitle = isFailure
                      ? 'Gagal memuat'
                      : isLoading
                      ? 'Memuat…'
                      : '${state.equipmentChecksCount} pemeriksaan hari ini';
                  final notificationsSubtitle = isFailure
                      ? 'Gagal memuat'
                      : isLoading
                      ? 'Memuat…'
                      : '${state.unreadNotificationsCount} belum dibaca';

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeOutQuart,
                    child: Wrap(
                      key: ValueKey('${isLoading}_$isFailure'),
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          icon: Icons.groups_outlined,
                          label: 'Kru Aktif',
                          value: activeCrewValue,
                          subtitle: activeCrewSubtitle,
                        ),
                        _StatCard(
                          icon: Icons.moving_outlined,
                          label: 'Volume Setara Bank',
                          value: cutFillValue,
                          subtitle: cutFillSubtitle,
                        ),
                        _StatCard(
                          icon: Icons.build_outlined,
                          label: 'Pemeriksaan Alat',
                          value: equipmentChecksValue,
                          subtitle: equipmentChecksSubtitle,
                        ),
                        _StatCard(
                          icon: Icons.notifications_active_outlined,
                          label: 'Notifikasi',
                          value: notificationsValue,
                          subtitle: notificationsSubtitle,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
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
        );
      },
    );
  }
}
