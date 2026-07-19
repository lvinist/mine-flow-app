// Responsive application shell — shadcn-admin inspired.
//
// Implements Doc 07 §4 Navigation & Layout:
//   - Wide screens (≥ 600dp): collapsible NavigationRail on the left.
//   - Narrow screens (< 600dp): NavigationBar (bottom tabs).
//
// The shell wraps all authenticated routes via ShellRoute in GoRouter.
// The StatefulShellRoute.indexedStack variant preserves each branch's state
// when switching tabs.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/bloc/theme_cubit.dart';

/// Width threshold at which we switch between mobile and desktop layout.
const double _kBreakpoint = 600;

/// Navigation destination labels and icons.
///
/// Matches the AppRoutes constants in router.dart. All user-facing strings are
/// Indonesian per Doc 07 §5 i18n.
enum ShellDestination {
  dashboard('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  dataBucket('Data Bucket', Icons.folder_outlined, Icons.folder),
  reports('Laporan', Icons.description_outlined, Icons.description),
  timeline('Timeline', Icons.timeline_outlined, Icons.timeline),
  notifications(
    'Notifikasi',
    Icons.notifications_outlined,
    Icons.notifications,
  );

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const ShellDestination(this.label, this.icon, this.selectedIcon);
}

/// Main responsive shell — provides sidebar (wide) or bottom nav (narrow).
///
/// [child] is the routed page content rendered by StatefulShellRoute.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kBreakpoint) {
          return _WideLayout(navigationShell: navigationShell);
        }
        return _NarrowLayout(navigationShell: navigationShell);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Wide layout — collapsible NavigationRail
// ---------------------------------------------------------------------------

class _WideLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _WideLayout({required this.navigationShell});

  @override
  State<_WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends State<_WideLayout> {
  bool _railExtended = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const destinations = ShellDestination.values;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: _railExtended,
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: _railExtended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: _railExtended
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      'mine-flow',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            trailing: _buildThemeToggle(theme),
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _railExtended = true;
    });
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Widget _buildThemeToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IconButton(
        icon: Icon(
          theme.brightness == Brightness.dark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
        ),
        tooltip: 'Toggle tema',
        onPressed: () => context.read<ThemeCubit>().toggleTheme(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Narrow layout — bottom NavigationBar (mobile)
// ---------------------------------------------------------------------------

class _NarrowLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _NarrowLayout({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    const destinations = ShellDestination.values;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.landscape, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('mine-flow'),
          ],
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
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
