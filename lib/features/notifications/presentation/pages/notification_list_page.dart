/// Full-screen notification list with read/dismiss actions.
///
/// Phase 2 Tier 2 rebuild (STEP-30.4): Switched Theme.of(context)/ColorScheme to
/// FTheme.of(context) semantic tokens. Remaining Container borders use FTheme
/// border colors. No logic, state, or data-fetching changes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_state.dart';

const double _kPagePadding = 24;

/// Responsive breakpoint: at or above this width, content is constrained
/// to a comfortable reading width.
const double _kContentMaxWidth = 720;

/// Spacing scale derived from DESIGN.md §29 (4, 8, 12, 16, 20, 24, 32 dp).
const double _kSpacing4 = 4;
const double _kSpacing8 = 8;
const double _kSpacing12 = 12;
const double _kSpacing16 = 16;

/// Animation curve constant — easeOutQuart per DESIGN.md §33.
const Curve _kEaseOutQuart = Curves.easeOutQuart;

/// Card border radius for surface containers.
const double _kCardRadius = 12;

/// Duration for card entrance stagger — each card delays by this increment.
const Duration _kStaggerStep = Duration(milliseconds: 20);

/// Displays all active (non-dismissed) notifications as cards.
///
/// Each card can be marked as read or dismissed. A "Dismiss All" button in
/// the app bar clears everything at once.
class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: MediaQuery.of(context).size.width > 800
          ? null
          : AppBar(
              title: Semantics(
                header: true,
                child: Text(
                  'Notifikasi',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              elevation: 0,
            ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          final theme = FTheme.of(context);
          switch (state) {
            case NotificationInitial():
              return Semantics(
                label: 'Memuat...',
                child: Center(
                  child: Text(
                    'Memuat...',
                    style: theme.typography.body.md.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              );
            case NotificationLoading():
              return const Center(child: CircularProgressIndicator());
            case NotificationLoaded(:final notifications):
              if (notifications.isEmpty) {
                return Semantics(
                  label: 'Tidak ada notifikasi',
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(_kPagePadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.bellOff,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: _kSpacing12),
                          Text(
                            'Tidak ada notifikasi',
                            style: theme.typography.body.md.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  // CF-032: "Tutup Semua" lives in the body so it persists on
                  // the desktop layout where the AppBar is absent.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _kPagePadding,
                      _kSpacing12,
                      _kPagePadding,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${notifications.length} notifikasi',
                          style: theme.typography.body.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        FButton(
                          variant: FButtonVariant.ghost,
                          onPress: () =>
                              context.read<NotificationCubit>().dismissAll(),
                          prefix: const Icon(LucideIcons.x, size: 18),
                          child: const Text('Tutup Semua'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kContentMaxWidth,
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(_kPagePadding),
                          itemCount: notifications.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: _kSpacing8),
                          itemBuilder: (context, index) =>
                              _AnimatedNotificationCard(
                                notification: notifications[index],
                                index: index,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            case NotificationError(:final message):
              return _buildErrorState(context, message, theme);
          }
        },
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    FThemeData theme,
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
              Container(
                padding: const EdgeInsets.all(_kSpacing16),
                decoration: BoxDecoration(
                  color: theme.colors.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  LucideIcons.alertCircle,
                  size: 48,
                  color: theme.colors.destructive,
                ),
              ),
              const SizedBox(height: _kSpacing12),
              Text(
                message,
                style: theme.typography.body.md.copyWith(
                  color: theme.colors.mutedForeground,
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

/// Wraps [_NotificationCard] with a staggered entrance animation.
///
/// Each card slides up and fades in with an easeOutQuart curve, delayed by
/// [index] × [_kStaggerStep] for a cascading reveal effect.
class _AnimatedNotificationCard extends StatefulWidget {
  final AppNotification notification;
  final int index;

  const _AnimatedNotificationCard({
    required this.notification,
    required this.index,
  });

  @override
  State<_AnimatedNotificationCard> createState() =>
      _AnimatedNotificationCardState();
}

class _AnimatedNotificationCardState extends State<_AnimatedNotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _startTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // CF-084: within Doc 07 §5's 150–200ms budget.
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: _kEaseOutQuart));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: _kEaseOutQuart));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // CF-084: honor reduced motion and cap the stagger; the timer is
    // cancellable so it can't fire on a disposed controller. (MediaQuery is
    // read in didChangeDependencies, not initState.)
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else {
      _startTimer = Timer(
        _kStaggerStep * widget.index.clamp(0, 8),
        _controller.forward,
      );
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _NotificationCard(notification: widget.notification),
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
        return LucideIcons.wrench;
      case NotificationType.lowInventory:
        return LucideIcons.boxes;
      case NotificationType.missingAttendance:
        return LucideIcons.userX;
      case NotificationType.overdueMilestone:
        return LucideIcons.send;
    }
  }

  Color _iconColor(FThemeData theme) {
    switch (notification.severity) {
      case NotificationSeverity.critical:
        return theme.colors.destructive;
      case NotificationSeverity.warning:
        return theme.colors.secondary;
      case NotificationSeverity.info:
        return theme.colors.mutedForeground;
    }
  }

  Color _bgColor(FThemeData theme) {
    switch (notification.severity) {
      case NotificationSeverity.critical:
        return theme.colors.destructive.withValues(alpha: 0.1);
      case NotificationSeverity.warning:
        return theme.colors.secondary.withValues(alpha: 0.1);
      case NotificationSeverity.info:
        return theme.colors.background;
    }
  }

  Color _borderColor(FThemeData theme) {
    switch (notification.severity) {
      case NotificationSeverity.critical:
        return theme.colors.destructive;
      case NotificationSeverity.warning:
        return theme.colors.secondary;
      case NotificationSeverity.info:
        return theme.colors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final cubit = context.read<NotificationCubit>();

    return Semantics(
      explicitChildNodes: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_kSpacing16),
          decoration: BoxDecoration(
            color: _bgColor(theme),
            border: Border(
              left: BorderSide(color: _borderColor(theme), width: 3),
              right: BorderSide(
                color: theme.colors.border.withValues(alpha: 0.5),
                width: 1,
              ),
              top: BorderSide(
                color: theme.colors.border.withValues(alpha: 0.5),
                width: 1,
              ),
              bottom: BorderSide(
                color: theme.colors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  label: notification.isRead
                      ? '${notification.title} — ${notification.message}'
                      : '${notification.title} — ${notification.message} — Ketuk untuk menandai dibaca',
                  hint: notification.isRead
                      ? null
                      : 'Ketuk untuk menandai dibaca',
                  container: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!notification.isRead) {
                        cubit.markAsRead(notification.id);
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
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
                          child: Icon(
                            _icon(),
                            size: 22,
                            color: _iconColor(theme),
                          ),
                        ),
                        const SizedBox(width: _kSpacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: theme.typography.body.sm.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  // CF-046: foreground (not primaryForeground) so the
                                  // title stays readable on a card surface.
                                  color: theme.colors.foreground,
                                ),
                              ),
                              const SizedBox(height: _kSpacing4),
                              Text(
                                notification.message,
                                style: theme.typography.body.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: _kSpacing6),
                              Text(
                                _formatTime(notification.createdAt),
                                style: theme.typography.body.sm.copyWith(
                                  color: theme.colors.mutedForeground
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Semantics(
                label: 'Tutup notifikasi',
                button: true,
                container: true,
                child: FButton.icon(
                  key: Key('dismiss_notification_${notification.id}'),
                  onPress: () => cubit.dismiss(notification.id),
                  variant: FButtonVariant.ghost,
                  child: const Icon(LucideIcons.x, size: 18),
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
