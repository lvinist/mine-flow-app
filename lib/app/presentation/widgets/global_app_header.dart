// STEP-31.5: Global App Header — Shadcn Admin style.
//
// Desktop (>= 800px): row with breadcrumb, search field, theme toggle, avatar.
// Mobile (< 800px): search-centric header with theme toggle and avatar.
//
// Docstrings are required per coding-standards/README.md.

// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';

/// Width breakpoint matching app_shell.dart.
const double _kBreakpoint = 800;

/// Shadcn Admin style global header.
///
/// Desktop layout:
///   [ Breadcrumb ]  [ Search field ]  [ Theme toggle ]  [ Avatar ]
///
/// Mobile layout:
///   [ Search field ]  [ Theme toggle ]  [ Avatar ]
class GlobalAppHeader extends StatelessWidget {
  final VoidCallback? onToggleSidebar;
  final bool isSidebarCollapsed;

  const GlobalAppHeader({
    super.key,
    this.onToggleSidebar,
    this.isSidebarCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kBreakpoint) {
          return _DesktopHeader(
            onToggleSidebar: onToggleSidebar,
            isSidebarCollapsed: isSidebarCollapsed,
          );
        }
        return const _MobileHeader();
      },
    );
  }
}

// ============================================================================
// Desktop header
// ============================================================================

/// Desktop header with breadcrumb, search, theme toggle, and avatar.
class _DesktopHeader extends StatelessWidget {
  final VoidCallback? onToggleSidebar;
  final bool isSidebarCollapsed;

  const _DesktopHeader({this.onToggleSidebar, this.isSidebarCollapsed = false});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          bottom: BorderSide(
            color: theme.colors.mutedForeground.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (onToggleSidebar != null) ...[
            Semantics(
              label: isSidebarCollapsed ? 'Buka sidebar' : 'Tutup sidebar',
              button: true,
              child: FButton(
                variant: FButtonVariant.ghost,
                onPress: onToggleSidebar,
                child: const Icon(LucideIcons.panelLeft, size: 18),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // --- Breadcrumb ---
          Expanded(flex: 1, child: _Breadcrumb()),

          // --- Search ---
          SizedBox(width: 280, child: _SearchField()),

          const SizedBox(width: 12),

          // --- Theme toggle ---
          _ThemeIconButton(),

          const SizedBox(width: 8),

          // --- Notifications ---
          _NotificationIconButton(),

          const SizedBox(width: 8),

          // --- Avatar ---
          _AvatarWidgetDesktop(),
        ],
      ),
    );
  }
}

// ============================================================================
// Mobile header (search-centric)
// ============================================================================

/// Mobile header with prominent search, theme toggle, and avatar.
class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          bottom: BorderSide(
            color: theme.colors.mutedForeground.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // --- Search (prominent, takes remaining space) ---
          Expanded(child: _SearchField()),

          const SizedBox(width: 8),

          // --- Theme toggle ---
          _ThemeIconButton(),

          const SizedBox(width: 4),

          // --- Notifications ---
          _NotificationIconButton(),

          const SizedBox(width: 4),

          // --- Avatar ---
          _AvatarWidget(),
        ],
      ),
    );
  }
}

// ============================================================================
// Breadcrumb
// ============================================================================

/// Builds a breadcrumb trail from the current route path.
///
/// Splits the URI path by "/", capitalises each segment, and renders them as
/// a row of "Segment › Segment › Segment" text.
class _BreadcrumbItem {
  final String label;
  final String route;
  const _BreadcrumbItem(this.label, this.route);
}

class _Breadcrumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final uri = GoRouterState.of(context).uri;
    final path = uri.path;

    final ancestors = _buildAncestors(path, uri.queryParameters);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Semantics(
            label: 'Breadcrumb navigasi',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < ancestors.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  if (i == ancestors.length - 1)
                    Semantics(
                      selected: true,
                      child: Text(
                        ancestors[i].label,
                        style: theme.typography.body.xs.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colors.foreground,
                        ),
                      ),
                    )
                  else
                    Semantics(
                      button: true,
                      onTapHint: 'Navigasi ke ${ancestors[i].label}',
                      child: InkWell(
                        onTap: () => context.go(ancestors[i].route),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          child: Text(
                            ancestors[i].label,
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<_BreadcrumbItem> _buildAncestors(
    String path,
    Map<String, String> queryParams,
  ) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final items = <_BreadcrumbItem>[];

    items.add(const _BreadcrumbItem('Dashboard', AppRoutes.dashboard));

    if (segments.isEmpty) return items;

    String current = '';
    for (int i = 0; i < segments.length; i++) {
      current += '/${segments[i]}';

      // Canonical Indonesian breadcrumb labels per route; keys are route paths.
      // Falls back to a capitalised segment name for unknown paths.
      const canonicalLabels = <String, String>{
        AppRoutes.operations: 'Operasi',
        AppRoutes.teams: 'Tim',
        AppRoutes.tools: 'Peralatan',
        AppRoutes.settings: 'Pengaturan',
        AppRoutes.cutFill: 'Cut / Fill',
        AppRoutes.landClearing: 'Land Clearing',
        AppRoutes.equipmentCheck: 'Pemeriksaan Alat',
        AppRoutes.dailyLog: 'Daily Log',
        AppRoutes.attendance: 'Attendance',
        AppRoutes.inventory: 'Inventory',
        AppRoutes.dataBucket: 'Data Bucket',
        AppRoutes.benchmarkDb: 'Benchmark DB',
      };
      String label = canonicalLabels[current] ?? _capitalise(segments[i]);
      if (segments[i] == 'form') label = 'Formulir';

      items.add(_BreadcrumbItem(label, current));
    }
    return items;
  }

  String _capitalise(String s) {
    if (s.isEmpty) return s;
    return s
        .split('-')
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }
}

// ============================================================================
// Search field
// ============================================================================

/// A search input field with a magnifying glass icon prefix.
///
/// Uses an aligned [Row] with a search icon and a compact [FTextField].
/// Hint text is in Indonesian per the i18n convention.
class _SearchField extends StatefulWidget {
  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Semantics(
      label: 'Cari fitur atau data',
      child: Container(
        decoration: BoxDecoration(
          color: theme.colors.muted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(
              LucideIcons.search,
              size: 16,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FTextField(
                control: FTextFieldControl.managed(controller: _controller),
                hint: 'Cari fitur atau data…',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Theme toggle icon button
// ============================================================================

/// Icon-only theme toggle button that cycles light/dark mode.
///
/// Uses [BlocBuilder] to read the current [SettingsCubit] state and displays a
/// sun (light) or moon (dark) icon accordingly. Tapping calls [SettingsCubit.updateThemeMode].
class _ThemeIconButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final mode = state.themeMode;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final nextMode = mode == ThemeMode.system
            ? (isDark ? ThemeMode.light : ThemeMode.dark)
            : mode == ThemeMode.dark
            ? ThemeMode.light
            : ThemeMode.system;

        IconData icon;
        String label;
        if (mode == ThemeMode.system) {
          icon = LucideIcons.settings2;
          label = 'Mode Sistem (Ubah ke ${isDark ? 'Terang' : 'Gelap'})';
        } else if (mode == ThemeMode.dark) {
          icon = LucideIcons.moon;
          label = 'Mode Gelap (Ubah ke Terang)';
        } else {
          icon = LucideIcons.sun;
          label = 'Mode Terang (Ubah ke Sistem)';
        }

        return Semantics(
          label: label,
          button: true,
          child: FButton(
            variant: FButtonVariant.ghost,
            onPress: () =>
                context.read<SettingsCubit>().updateThemeMode(nextMode),
            child: Icon(icon, size: 18),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Notification icon button
// ============================================================================

/// Icon-only notification button that navigates to the notifications page.
class _NotificationIconButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Notifikasi',
      button: true,
      child: FButton(
        variant: FButtonVariant.ghost,
        onPress: () => context.push(AppRoutes.notifications),
        child: const Icon(LucideIcons.inbox, size: 18),
      ),
    );
  }
}

// ============================================================================
// Avatar widget
// ============================================================================

/// A small circular avatar button for the user profile.
///
/// Displays a person icon inside a [CircleAvatar]. Tapping navigates to the
/// Settings page (where the full profile is managed).
class _AvatarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final user = context.watch<AuthCubit>().state.user;
    final name = user?.name ?? 'Loading...';
    final rawRole = user?.role ?? '';
    final roleDisplay = _mapRole(rawRole);
    final initials = user?.name.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : '?';

    return Semantics(
      label: 'Profil pengguna: $name, $roleDisplay',
      button: true,
      child: FButton(
        variant: FButtonVariant.ghost,
        onPress: () => context.go(AppRoutes.settingsProfile),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: theme.colors.muted,
          child: Text(
            initials,
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }

  String _mapRole(String role) {
    switch (role) {
      case 'supervisor':
        return 'Supervisor';
      case 'foreman':
        return 'Foreman';
      case 'crew':
        return 'Crew';
      default:
        return '—';
    }
  }
}

/// Expanded avatar widget for Desktop showing name and role.
class _AvatarWidgetDesktop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final user = context.watch<AuthCubit>().state.user;
    final name = user?.name ?? 'Loading...';
    final rawRole = user?.role ?? '';
    // Provide a simple localized role mapping for display.
    final roleDisplay = _mapRole(rawRole);
    final initials = user?.name.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : '?';

    return Semantics(
      label: 'Profil pengguna: $name, $roleDisplay',
      button: true,
      child: InkWell(
        onTap: () => context.go(AppRoutes.settingsProfile),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colors.muted.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colors.mutedForeground.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colors.muted,
                child: Text(
                  initials,
                  style: theme.typography.body.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    roleDisplay,
                    style: theme.typography.body.xs3.copyWith(
                      color: theme.colors.mutedForeground,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mapRole(String role) {
    switch (role) {
      case 'supervisor':
        return 'Supervisor';
      case 'foreman':
        return 'Foreman';
      case 'crew':
        return 'Crew';
      default:
        return '—';
    }
  }
}
