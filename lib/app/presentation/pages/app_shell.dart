// STEP-31.2: Responsive AppShell with Desktop sidebar and Mobile bottom navbar.
// STEP-31.5: Global App Header added above the content area on both layouts.
//
// Desktop (>= 800px): FSidebar with sectioned groups matching the 5 router
//   branches, a profile card in the footer, and a theme toggle button. A
//   GlobalAppHeader (breadcrumb, search, theme toggle, avatar) sits above the
//   main content.
// Mobile (< 800px): FBottomNavigationBar with FBottomNavigationBarItems,
//   and a search-centric GlobalAppHeader at the top.
//
// Navigation groups (Doc 07 §4):
//   Branch 0: Dashboard
//   Branch 1: Tools       (Data Bucket)
//   Branch 2: Operations  (Cut/Fill, Land Clearing)
//   Branch 3: Teams       (Attendance, Daily Log, Inventory, Equipment Check)
//   Branch 4: Settings
//
// Docstrings are required per coding-standards/README.md.

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/widgets/global_app_header.dart';
import 'package:mine_flow/app/router.dart';

/// Width threshold that switches between desktop (sidebar) and mobile (bottom
/// nav) layout. Set at 800dp to accommodate tablets in landscape.
const double _kBreakpoint = 800;

/// Configuration for a single navigation branch (used for Mobile bottom nav).
class _BranchConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _BranchConfig(this.label, this.icon, this.activeIcon);
}

/// The five main navigation branches for mobile bottom nav.
const _kBranchConfigs = <_BranchConfig>[
  _BranchConfig(
    'Dashboard',
    LucideIcons.layoutDashboard,
    LucideIcons.layoutDashboard,
  ),
  _BranchConfig('Tools', LucideIcons.wrench, LucideIcons.wrench),
  _BranchConfig('Operations', LucideIcons.hardHat, LucideIcons.hardHat),
  _BranchConfig('Teams', LucideIcons.users, LucideIcons.users),
  _BranchConfig('Settings', LucideIcons.settings, LucideIcons.settings),
];

// --- Desktop Sidebar Configuration ---

class _SidebarItemConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int branchIndex;
  final String route;

  const _SidebarItemConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.branchIndex,
    required this.route,
  });
}

class _SidebarSection {
  final String label;
  final List<_SidebarItemConfig> items;

  const _SidebarSection({required this.label, required this.items});
}

const _kSidebarSections = <_SidebarSection>[
  _SidebarSection(
    label: 'General',
    items: [
      _SidebarItemConfig(
        label: 'Dashboard',
        icon: LucideIcons.layoutDashboard,
        activeIcon: LucideIcons.layoutDashboard,
        branchIndex: 0,
        route: AppRoutes.dashboard,
      ),
    ],
  ),
  _SidebarSection(
    label: 'Tools',
    items: [
      _SidebarItemConfig(
        label: 'Data Bucket',
        icon: LucideIcons.fileArchive,
        activeIcon: LucideIcons.fileArchive,
        branchIndex: 1,
        route: AppRoutes.dataBucket,
      ),
    ],
  ),
  _SidebarSection(
    label: 'Operations',
    items: [
      _SidebarItemConfig(
        label: 'Cut / Fill',
        icon: LucideIcons.move,
        activeIcon: LucideIcons.move,
        branchIndex: 2,
        route: AppRoutes.cutFill,
      ),
      _SidebarItemConfig(
        label: 'Land Clearing',
        icon: LucideIcons.mountainSnow,
        activeIcon: LucideIcons.mountainSnow,
        branchIndex: 2,
        route: AppRoutes.landClearing,
      ),
      _SidebarItemConfig(
        label: 'Benchmark DB',
        icon: LucideIcons.circleDot,
        activeIcon: LucideIcons.circleDot,
        branchIndex: 2,
        route: AppRoutes.benchmarkDb,
      ),
    ],
  ),
  _SidebarSection(
    label: 'Teams',
    items: [
      _SidebarItemConfig(
        label: 'Attendance',
        icon: LucideIcons.users,
        activeIcon: LucideIcons.users,
        branchIndex: 3,
        route: AppRoutes.attendance,
      ),
      _SidebarItemConfig(
        label: 'Daily Log',
        icon: LucideIcons.clipboardList,
        activeIcon: LucideIcons.clipboardList,
        branchIndex: 3,
        route: AppRoutes.dailyLog,
      ),
      _SidebarItemConfig(
        label: 'Inventory',
        icon: LucideIcons.boxes,
        activeIcon: LucideIcons.boxes,
        branchIndex: 3,
        route: AppRoutes.inventory,
      ),
      _SidebarItemConfig(
        label: 'Equipment Check',
        icon: LucideIcons.wrench,
        activeIcon: LucideIcons.wrench,
        branchIndex: 3,
        route: AppRoutes.equipmentCheck,
      ),
      _SidebarItemConfig(
        label: 'Timeline Pekerjaan',
        icon: LucideIcons.activity,
        activeIcon: LucideIcons.activity,
        branchIndex: 3,
        route: AppRoutes.timeline,
      ),
    ],
  ),
  _SidebarSection(
    label: 'Other',
    items: [
      _SidebarItemConfig(
        label: 'Reports',
        icon: LucideIcons.fileText,
        activeIcon: LucideIcons.fileText,
        branchIndex: 0,
        route: AppRoutes.reportConfig,
      ),
      _SidebarItemConfig(
        label: 'Settings',
        icon: LucideIcons.settings,
        activeIcon: LucideIcons.settings,
        branchIndex: 4,
        route: AppRoutes.settings,
      ),
    ],
  ),
];

// ============================================================================
// AppShell — root responsive shell
// ============================================================================

/// Root shell that wraps all authenticated branches with a responsive layout.
///
/// Delegates to [_WideLayout] (FSidebar) or [_NarrowLayout] (FBottomNavBar)
/// depending on the available width.
class AppShell extends StatelessWidget {
  /// The navigation shell provided by [StatefulShellRoute].
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

// ============================================================================
// Wide layout — FSidebar on desktop/tablet
// ============================================================================

/// Desktop layout with a ForUI [FSidebar] on the left and [GlobalAppHeader]
/// above the main content area.
///
/// The sidebar includes:
///   - **Header:** "mine-flow" branding with an icon.
///   - **Content:** Sidebar items for the 5 branches.
///   - **Footer:** Profile card and theme toggle button.
///
/// Content area layout:
///   +---------------------------+
///   |     GlobalAppHeader       |
///   +---------------------------+
///   |     navigationShell       |
///   +---------------------------+
class _WideLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _WideLayout({required this.navigationShell});

  @override
  State<_WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends State<_WideLayout> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            width: _isCollapsed ? 0 : 256,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: OverflowBox(
              minWidth: 256,
              maxWidth: 256,
              alignment: Alignment.centerLeft,
              child: FSidebar(
                header: _buildHeader(theme),
                children: [
                  for (final section in _kSidebarSections)
                    FSidebarGroup(
                      label: Text(section.label),
                      children: [
                        for (final item in section.items)
                          _buildSidebarItem(
                            context: context,
                            item: item,
                            currentPath: GoRouterState.of(context).uri.path,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const FDivider(axis: Axis.vertical),
          // Right side: Global header + page content
          Expanded(
            child: Column(
              children: [
                GlobalAppHeader(
                  onToggleSidebar: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                  isSidebarCollapsed: _isCollapsed,
                ),
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sidebar header with app logo and name.
  Widget _buildHeader(FThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.mountain, size: 20, color: theme.colors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'mine-flow',
              style: theme.typography.display.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Footer removed per spec.

  /// Builds a single sidebar item for Desktop.
  Widget _buildSidebarItem({
    required BuildContext context,
    required _SidebarItemConfig item,
    required String currentPath,
  }) {
    final isSelected =
        currentPath == item.route || currentPath.startsWith('${item.route}/');

    return FSidebarItem(
      icon: Icon(isSelected ? item.activeIcon : item.icon),
      label: Text(item.label),
      selected: isSelected,
      onPress: () {
        // Navigate to the specific child route even if already on the branch.
        context.go(item.route);
      },
    );
  }
}

// ============================================================================
// Narrow layout — FBottomNavigationBar on mobile
// ============================================================================

/// Mobile layout with [GlobalAppHeader] at the top and [FBottomNavigationBar]
/// at the bottom.
///
/// The header is search-centric (search field, theme toggle, avatar). The
/// bottom bar uses ForUI [FBottomNavigationBarItem] widgets.
class _NarrowLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _NarrowLayout({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    // Use Material for the narrow layout; it interoperates with ForUI widgets
    // via the FTheme wrapper in app.dart.
    return Material(
      child: Column(
        children: [
          if (GoRouterState.of(context).uri.path == AppRoutes.dashboard)
            const GlobalAppHeader(),
          Expanded(child: navigationShell),
          FBottomNavigationBar(
            index: currentIndex,
            onChange: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            children: [
              for (int i = 0; i < _kBranchConfigs.length; i++)
                FBottomNavigationBarItem(
                  icon: Icon(
                    currentIndex == i
                        ? _kBranchConfigs[i].activeIcon
                        : _kBranchConfigs[i].icon,
                  ),
                  label: Text(_kBranchConfigs[i].label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Shared widgets
// ============================================================================

// Removed _SidebarProfileCard and _ThemeToggleButton as they were moved to GlobalAppHeader.
