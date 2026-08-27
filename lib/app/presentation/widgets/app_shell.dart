// Responsive application shell — ForUI FScaffold & FSidebar driven.
//
// Implements Doc 07 §4 Navigation & Layout & STEP-30.1 contract:
//   - Wide screens (≥ 600dp): FSidebar on the left with sectioned groups.
//   - Narrow screens (< 600dp): Bottom navigation bar / tabs.
//
// Structured navigation groups (AppNavGroup & AppNavItem) are exposed so that
// STEP-31 can regroup feature routing without touching layout code.

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/models/app_nav_model.dart';
import 'package:mine_flow/app/router.dart';

/// Width threshold at which we switch between mobile and desktop layout.
const double _kBreakpoint = 600;

/// Default structured navigation items and groups provided to the shell.
/// STEP-31 will extend and regroup this structure.
const List<AppNavGroup> defaultAppNavGroups = [
  AppNavGroup(
    title: 'Utama',
    items: [
      AppNavItem(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icon(LucideIcons.layoutDashboard),
        selectedIcon: Icon(LucideIcons.layoutDashboard),
        route: AppRoutes.dashboard,
        branchIndex: 0,
      ),
      AppNavItem(
        id: 'data_bucket',
        label: 'Data Bucket',
        icon: Icon(LucideIcons.folder),
        selectedIcon: Icon(LucideIcons.folder),
        route: AppRoutes.dataBucket,
        branchIndex: 1,
      ),
      AppNavItem(
        id: 'timeline',
        label: 'Timeline',
        icon: Icon(LucideIcons.activity),
        selectedIcon: Icon(LucideIcons.activity),
        route: AppRoutes.timeline,
        branchIndex: 2,
      ),
      AppNavItem(
        id: 'notifications',
        label: 'Notifikasi',
        icon: Icon(LucideIcons.bell),
        selectedIcon: Icon(LucideIcons.bell),
        route: AppRoutes.notifications,
        branchIndex: 3,
      ),
    ],
  ),
];

/// Main responsive shell — provides FSidebar (wide) or bottom nav (narrow).
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<AppNavGroup>? navGroups;

  const AppShell({super.key, required this.navigationShell, this.navGroups});

  @override
  Widget build(BuildContext context) {
    final groups = navGroups ?? defaultAppNavGroups;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kBreakpoint) {
          return _WideLayout(
            navigationShell: navigationShell,
            navGroups: groups,
          );
        }
        return _NarrowLayout(
          navigationShell: navigationShell,
          navGroups: groups,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Wide layout — FSidebar + Content Area
// ---------------------------------------------------------------------------

class _WideLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<AppNavGroup> navGroups;

  const _WideLayout({required this.navigationShell, required this.navGroups});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: Row(
        children: [
          FSidebar(
            header: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  const Icon(LucideIcons.mountain, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'mine-flow',
                    style: theme.typography.display.xl.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              for (final group in navGroups)
                FSidebarGroup(
                  label: Text(group.title),
                  children: [
                    for (final item in group.items)
                      FSidebarItem(
                        icon: item.icon,
                        label: Text(item.label),
                        selected: currentIndex == item.branchIndex,
                        onPress: () {
                          navigationShell.goBranch(
                            item.branchIndex,
                            initialLocation: item.branchIndex == currentIndex,
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
          const FDivider(axis: Axis.vertical),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Narrow layout — Mobile NavigationBar
// ---------------------------------------------------------------------------

class _NarrowLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<AppNavGroup> navGroups;

  const _NarrowLayout({required this.navigationShell, required this.navGroups});

  @override
  Widget build(BuildContext context) {
    final allItems = navGroups.expand((g) => g.items).toList();
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < allItems.length ? currentIndex : 0,
        onDestinationSelected: (index) {
          if (index < allItems.length) {
            final item = allItems[index];
            navigationShell.goBranch(
              item.branchIndex,
              initialLocation: item.branchIndex == currentIndex,
            );
          }
        },
        destinations: allItems
            .map(
              (item) => NavigationDestination(
                icon: item.icon,
                selectedIcon: item.selectedIcon ?? item.icon,
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
