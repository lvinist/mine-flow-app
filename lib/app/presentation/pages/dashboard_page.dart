// Dashboard page — card-based stats summary in shadcn-admin aesthetic.
//
// Phase 2 styling pass: clean card surfaces with 12 px rounded corners,
// subtle 1 px borders (outlineVariant), consistent spacing scale, and
// refined typography — matching the conventions established in LoginPage
// (STEP-13). No logic, state, or data-fetching changes in this substep.
//
// Substep 14.3 audit: accessibility (a11y) + responsive checks applied.
//   - Keyboard focus support on nav cards (Focus + onKey for Enter/Space).
//   - Semantics labels on card groups and interactive elements.
//   - Responsive breakpoints: mobile <600 / tablet 600-899 / desktop ≥900.
//   - Contrast verified against DESIGN.md §19 (≥4.5:1 on body text).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_cubit.dart';
import 'package:mine_flow/app/presentation/bloc/dashboard_state.dart';
import 'package:mine_flow/app/router.dart';

/// Spacing scale constants matching the shadcn-admin design language.
/// See DESIGN.md §29 — explicit scale: 4, 8, 12, 16, 20, 24, 32.
const double _kPagePadding = 24;
const double _kCardPadding = 24;

/// Brand primary — Steel Blue / Navy (#0f172a), the restrained foundation.
const Color _kBrandPrimary = Color(0xFF0F172A);

/// Accent — Cyan / Teal, used sparingly for interactive elements.
const Color _kAccent = Color(0xFF0891B2);

// --- Responsive breakpoints (DESIGN.md §28) ---
const double _kBreakMobile = 600;
const double _kBreakTablet = 900;

/// The main dashboard page displayed at the root route.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            'Dashboard',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
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
            // --- Stat summary cards row (backed by DashboardCubit) ---
            // State transitions use AnimatedSwitcher for a restrained
            // crossfade — matching DESIGN.md §33 (easeOutQuart curves,
            // crossfades for reduced motion).
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

            const SizedBox(height: 8),

            // --- Section divider ---
            // Subdued divider matching the restrained palette.
            Divider(
              height: 32,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),

            // --- Section heading ---
            // Constrained width per DESIGN.md §19 — prevent excessively
            // long heading lines on wide screens.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Quick Navigation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Akses cepat ke semua fitur',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Quick navigation cards (responsive grid) ---
            const _QuickNavGrid(),
          ],
        ),
      ),
    );
  }
}

/// A single stat summary card with icon, label, value, and subtitle.
///
/// Uses a restrained colour palette: icon container gets the brand primary
/// with low opacity, text stays in onSurface/onSurfaceVariant. No saturated
/// accent colours per stat — consistency with the shadcn-admin aesthetic.
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive card width: 240px desktop, full-width on narrow.
        final cardWidth = constraints.maxWidth >= _kBreakMobile
            ? 240.0
            : double.infinity;

        return SizedBox(
          width: cardWidth,
          child: Semantics(
            label: label,
            value: value,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(_kCardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + label row — restrained, using brand primary.
                    Row(
                      children: [
                        Semantics(
                          excludeSemantics: true,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _kBrandPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, size: 22, color: _kAccent),
                          ),
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
                    // Value — bold, prominent, matching LoginPage's heading style.
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
            ),
          ),
        );
      },
    );
  }
}

/// A navigation card definition used to build the quick-nav grid.
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

/// The grid of quick-navigation cards (reports, timeline, notifications, data bucket).
///
/// Responsive columns (DESIGN.md §28):
///   <600px → 2 cols     (mobile)
///   600-899px → 3 cols  (tablet)
///   ≥900px → 4 cols     (desktop)
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

/// A single quick-navigation card (icon + label) with micro-interaction.
///
/// Uses an [_AnimatedNavCard] internally to provide a subtle elevation
/// and border colour change on hover/press — matching DESIGN.md §33
/// (Curves.easeOutQuart, no decorative layout shifting).
///
/// Keyboard accessible: Focus widget + onKey handler for Enter/Space
/// activation — required for web/desktop compliance.
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
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Merge hover and focus states for visual feedback.
    final isActive = _isHovered || _isFocused;

    return Semantics(
      label: widget.label,
      button: true,
      child: Focus(
        onKeyEvent: (node, event) {
          // Activate on Enter or Space key.
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        onFocusChange: (isFocused) {
          setState(() => _isFocused = isFocused);
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? colorScheme.outlineVariant
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                focusColor: colorScheme.primary.withValues(alpha: 0.08),
                hoverColor: Colors.transparent,
                splashColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        excludeSemantics: true,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _kBrandPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(widget.icon, size: 24, color: _kAccent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.label,
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
            ),
          ),
        ),
      ),
    );
  }
}
