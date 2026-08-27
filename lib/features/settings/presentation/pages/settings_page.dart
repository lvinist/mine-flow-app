/// Settings Page UI Shell & Integrations for mine-flow.
///
/// Implements the comprehensive Settings page with Profile, Preferences
/// (Language & Theme), Support (Email/WhatsApp), and Logout sections using
/// ForUI components per the shadcn-admin design language (Doc 07).
///
/// State management is delegated to [SettingsCubit] (theme & locale) —
/// wired at the app root in [app.dart]. Auth/profile data is read from
/// the Supabase session (placeholder values when offline/unauthenticated).
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// The comprehensive Settings page — reached via AppRoutes.settings.
///
/// Layout (scrollable card groups):
///   1. **Profile** — Avatar, display name, role (from auth state).
///   2. **Preferences** — Language (English / Indonesian) and Theme toggle.
///   3. **Support** — Contact email and WhatsApp buttons.
///   4. **Logout** — Destructive action.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      header: FHeader(
        title: Text(
          'Pengaturan',
          style: theme.typography.display.lg.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================================
              // Profile Section
              // ============================================================
              _ProfileCard(theme: theme),
              const SizedBox(height: 24),

              // ============================================================
              // Preferences Section
              // ============================================================
              FCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferensi',
                        style: theme.typography.display.sm.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Language selector ---
                      Text(
                        'Bahasa / Language',
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          final isEnglish = state.locale.languageCode == 'en';
                          return Row(
                            children: [
                              Expanded(
                                child: FButton(
                                  variant: isEnglish
                                      ? FButtonVariant.primary
                                      : FButtonVariant.outline,
                                  onPress: () {
                                    if (!isEnglish) {
                                      context
                                          .read<SettingsCubit>()
                                          .updateLocale(const Locale('en'));
                                    }
                                  },
                                  child: const Text('English'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FButton(
                                  variant: !isEnglish
                                      ? FButtonVariant.primary
                                      : FButtonVariant.outline,
                                  onPress: () {
                                    if (isEnglish) {
                                      context
                                          .read<SettingsCubit>()
                                          .updateLocale(const Locale('id'));
                                    }
                                  },
                                  child: const Text('Indonesia'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                      // CF-059: the English locale is only partially migrated
                      // (RISK-0004), so flag it rather than implying a full
                      // translation.
                      Text(
                        'Terjemahan bahasa Inggris masih sebagian.',
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Theme selector ---
                      Text(
                        'Tema / Theme',
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          return Row(
                            children: [
                              _ThemeOption(
                                label: 'Terang',
                                icon: LucideIcons.sun,
                                isSelected: state.themeMode == ThemeMode.light,
                                onPress: () {
                                  context.read<SettingsCubit>().updateThemeMode(
                                    ThemeMode.light,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _ThemeOption(
                                label: 'Gelap',
                                icon: LucideIcons.moon,
                                isSelected: state.themeMode == ThemeMode.dark,
                                onPress: () {
                                  context.read<SettingsCubit>().updateThemeMode(
                                    ThemeMode.dark,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _ThemeOption(
                                label: 'Sistem',
                                icon: LucideIcons.settings2,
                                isSelected: state.themeMode == ThemeMode.system,
                                onPress: () {
                                  context.read<SettingsCubit>().updateThemeMode(
                                    ThemeMode.system,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ============================================================
              // Support Section
              // ============================================================
              FCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dukungan',
                        style: theme.typography.display.sm.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hubungi tim support jika ada kendala teknis.',
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Email button ---
                      FButton(
                        variant: FButtonVariant.outline,
                        onPress: () => _launchEmail(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.mail, size: 18),
                            SizedBox(width: 8),
                            Text('alvin.geomatics@gmail.com'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- WhatsApp button ---
                      FButton(
                        variant: FButtonVariant.outline,
                        onPress: () => _launchWhatsApp(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.messageCircle, size: 18),
                            SizedBox(width: 8),
                            Text('+62 851-5604-2854'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ============================================================
              // Logout Section
              // ============================================================
              FButton(
                variant: FButtonVariant.destructive,
                onPress: () => _confirmLogout(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.logOut, size: 18),
                    SizedBox(width: 8),
                    Text('Keluar / Logout'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- App version (CF-090: read at runtime, not hardcoded) ---
              Center(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    return Text(
                      'mine-flow v${snapshot.data?.version ?? '0.1.0'}',
                      style: theme.typography.body.xs3.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the default email client with the support address pre-filled.
  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'alvin.geomatics@gmail.com',
      queryParameters: {
        'subject': 'mine-flow — Bantuan Teknis',
        'body': 'Halo, saya mengalami kendala berikut:\n\n',
      },
    );
    final launched = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (launched) {
      await launchUrl(uri);
    } else {
      _showSnackError(context, 'Tidak dapat membuka aplikasi email.');
    }
  }

  /// Opens the WhatsApp chat with the support number.
  Future<void> _launchWhatsApp(BuildContext context) async {
    // CF-058: use the real support number (matching the displayed text), not a
    // masked placeholder.
    final uri = Uri.parse('https://wa.me/6285156042854');
    final launched = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (launched) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackError(context, 'Tidak dapat membuka WhatsApp.');
    }
  }

  /// Shows a confirmation dialog before logging out.
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Anda akan diarahkan ke halaman login.',
        ),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // CF-004: terminate the Supabase session and clear cached role/token
      // before leaving, so a shared field device does not carry the session.
      await context.read<AuthCubit>().signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }

  /// Shows a short error snackbar.
  void _showSnackError(BuildContext context, String message) {
    final theme = FTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// Profile Card — displays user avatar, name, and role
// ============================================================================

/// Profile card showing the current user's avatar, display name, and role.
///
/// Reads the authenticated [AuthCubit] user (CF-005): the name and role now
/// come from the signed-in account, with a neutral placeholder while auth is
/// still resolving — no fabricated role.
class _ProfileCard extends StatelessWidget {
  final FThemeData theme;

  const _ProfileCard({required this.theme});

  /// Human-readable Indonesian label for a role value.
  static String _roleLabel(String role) {
    switch (role) {
      case 'supervisor':
        return 'Supervisor';
      case 'foreman':
        return 'Foreman';
      case 'crew':
        return 'Crew';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // --- Avatar ---
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colors.muted,
              child: Icon(
                LucideIcons.user,
                size: 28,
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(width: 16),

            // --- Name & role ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? '—',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user != null ? _roleLabel(user.role) : '—',
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Theme option button — used inside the theme segmented selector
// ============================================================================

/// A single theme option button in the theme segmented control.
///
/// When [isSelected] is true the button renders with [FButtonVariant.primary];
/// otherwise with [FButtonVariant.outline].
class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPress;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FButton(
        variant: isSelected ? FButtonVariant.primary : FButtonVariant.outline,
        onPress: onPress,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 4),
            Text(label, style: FTheme.of(context).typography.body.xs),
          ],
        ),
      ),
    );
  }
}
