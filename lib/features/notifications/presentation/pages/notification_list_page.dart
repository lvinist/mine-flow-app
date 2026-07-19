/// Full-screen notification list with read/dismiss actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_state.dart';

/// Displays all active (non-dismissed) notifications as cards.
///
/// Each card can be marked as read or dismissed. A "Dismiss All" button in
/// the app bar clears everything at once.
class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded &&
                  state.notifications.isNotEmpty) {
                return TextButton.icon(
                  onPressed: () =>
                      context.read<NotificationCubit>().dismissAll(),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Tutup Semua'),
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
              return const Center(child: Text('Memuat...'));
            case NotificationLoading():
              return const Center(child: CircularProgressIndicator());
            case NotificationLoaded(:final notifications):
              if (notifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: kColorMuted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tidak ada notifikasi',
                        style: TextStyle(color: kColorMuted),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _NotificationCard(notification: notifications[index]),
              );
            case NotificationError(:final message):
              return Center(child: Text(message));
          }
        },
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

  Color _bgColor() {
    switch (notification.severity) {
      case NotificationSeverity.critical:
        return kColorPrimaryContainer;
      case NotificationSeverity.warning:
        return const Color(0xFFFEF3C7); // amber-50
      case NotificationSeverity.info:
        return kColorSurface;
    }
  }

  Color _borderColor() {
    switch (notification.severity) {
      case NotificationSeverity.critical:
        return kColorPrimary;
      case NotificationSeverity.warning:
        return const Color(0xFFF59E0B); // amber-500
      case NotificationSeverity.info:
        return kColorBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationCubit>();

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          cubit.markAsRead(notification.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor(),
          borderRadius: kBorderRadius,
          border: Border(left: BorderSide(color: _borderColor(), width: 3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon(), size: 24, color: _borderColor()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification.createdAt),
                    style: const TextStyle(fontSize: 11, color: kColorMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => cubit.dismiss(notification.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
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
