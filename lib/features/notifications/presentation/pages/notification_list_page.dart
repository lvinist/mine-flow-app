/// Full-screen notification list with read/dismiss actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_state.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kPagePadding = 24;

/// Spacing scale derived from DESIGN.md §29 (4, 8, 12, 16, 20, 24, 32 dp).
const double _kSpacing4 = 4;
const double _kSpacing8 = 8;
const double _kSpacing12 = 12;
const double _kSpacing16 = 16;

/// Card border radius for surface containers — matches the 12dp used across
/// Phase 2 card surfaces (DESIGN.md §29 shape scale).
const double _kCardRadius = 12;

/// Displays all active (non-dismissed) notifications as cards.
///
/// Each card can be marked as read or dismissed. A "Dismiss All" button in
/// the app bar clears everything at once.
class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            'Notifikasi',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded &&
                  state.notifications.isNotEmpty) {
                return Semantics(
                  label: 'Tutup Semua',
                  button: true,
                  child: TextButton.icon(
                    onPressed: () =>
                        context.read<NotificationCubit>().dismissAll(),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Tutup Semua'),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          switch (state) {
            case NotificationInitial():
              return Semantics(
                label: 'Memuat...',
                child: const Center(child: Text('Memuat...')),
              );
            case NotificationLoading():
              return const Center(child: CircularProgressIndicator());
            case NotificationLoaded(:final notifications):
              if (notifications.isEmpty) {
                return Semantics(
                  label: 'Tidak ada notifikasi',
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: _kSpacing12),
                        Text(
                          'Tidak ada notifikasi',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(_kPagePadding),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: _kSpacing8),
                itemBuilder: (context, index) =>
                    _NotificationCard(notification: notifications[index]),
              );
            case NotificationError(:final message):
              return _buildErrorState(context, message, theme, colorScheme);
          }
        },
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Semantics(
      label: 'Kesalahan: $message',
      container: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(_kPagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: _kSpacing12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single notification card with severity-based styling.
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  IconData _icon() {
    switch (notification.type) {
      case NotificationType.equipmentCheckReminder:
        return Icons.build_circle_outlined;
      case NotificationType.lowInventory:
        return Icons.inventory_2_outlined;
      case NotificationType.missingAttendance:
        return Icons.person_off_outlined;
      case NotificationType.overdueMilestone:
        return Icons.schedule_send_outlined;
    }
  }

  Color _iconColor(ThemeData theme) {
    switch (notification.severity) {
      case NotificationSeverity.critical:
        return theme.colorScheme.primary;
      case NotificationSeverity.warning:
        return theme.colorScheme.tertiary;
      case NotificationSeverity.info:
        return theme.colorScheme.outline;
    }
  }

  Color _bgColor(ThemeData theme) {
    switch (notification.severity) {
      case NotificationSeverity.critical:
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.5);
      case NotificationSeverity.warning:
        return theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4);
      case NotificationSeverity.info:
        return theme.colorScheme.surface;
    }
  }

  Color _borderColor(ThemeData theme) {
    switch (notification.severity) {
      case NotificationSeverity.critical:
        return theme.colorScheme.primary;
      case NotificationSeverity.warning:
        return theme.colorScheme.tertiary;
      case NotificationSeverity.info:
        return theme.colorScheme.outlineVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<NotificationCubit>();

    return Semantics(
      label: notification.title,
      container: true,
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            cubit.markAsRead(notification.id);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_kSpacing16),
          decoration: BoxDecoration(
            color: _bgColor(theme),
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border(
              left: BorderSide(color: _borderColor(theme), width: 3),
              right: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                excludeSemantics: true,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _bgColor(theme),
                    borderRadius: BorderRadius.circular(_kSpacing8),
                    border: Border.all(
                      color: _borderColor(theme).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(_icon(), size: 22, color: _iconColor(theme)),
                ),
              ),
              const SizedBox(width: _kSpacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: _kSpacing4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: _kSpacing6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Tutup notifikasi',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => cubit.dismiss(notification.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit yang lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam yang lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

/// Spacing used for timestamp-description gap.
const double _kSpacing6 = 6;
