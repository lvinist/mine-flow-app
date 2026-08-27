// STEP-31.5: Global App Header — Shadcn Admin style.
//
// Desktop (>= 800px): row with breadcrumb, search field, theme toggle, avatar.
// Mobile (< 800px): search-centric header with theme toggle and avatar.
//
// Docstrings are required per coding-standards/README.md.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';

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
class _Breadcrumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final path = GoRouterState.of(context).uri.path;

    // Normalise the path: remove leading/trailing slash, split by "/".
    final segments = path
        .split('/')
        .where((s) => s.isNotEmpty)
        .map(_capitalise)
        .toList();

    // If root, show "Dashboard" as a single segment.
    if (segments.isEmpty) {
      segments.add('Dashboard');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Semantics(
        label: 'Breadcrumb navigasi',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < segments.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              Text(
                segments[i],
                style: theme.typography.body.xs.copyWith(
                  fontWeight: i == segments.length - 1
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: i == segments.length - 1
                      ? theme.colors.foreground
                      : theme.colors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Converts a hyphenated path segment into a title-cased label.
  ///
  /// Example: 'daily-log' → 'Daily Log', 'equipment-check' → 'Equipment Check'.
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
            Icon(LucideIcons.search, size: 16, color: theme.colors.mutedForeground),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Semantics(
          label: isDark ? 'Aktifkan mode terang' : 'Aktifkan mode gelap',
          button: true,
          child: FButton(
            variant: FButtonVariant.ghost,
            onPress: () => context.read<SettingsCubit>().updateThemeMode(
              isDark ? ThemeMode.light : ThemeMode.dark,
            ),
            child: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 18),
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

    return Semantics(
      label: 'Profil pengguna',
      button: true,
      child: FButton(
        variant: FButtonVariant.ghost,
        onPress: () => context.go(AppRoutes.settings),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: theme.colors.muted,
          child: Icon(
            LucideIcons.user,
            size: 16,
            color: theme.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

/// Expanded avatar widget for Desktop showing name and role.
class _AvatarWidgetDesktop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Semantics(
      label: 'Profil pengguna',
      button: true,
      child: InkWell(
        onTap: () => context.go(AppRoutes.settings),
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
              Icon(LucideIcons.user, size: 20, color: theme.colors.mutedForeground),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pengguna',
                    style: theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'Foreman',
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
}
