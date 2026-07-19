/// A persistent banner for critical notifications.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
import 'package:mine_flow/features/notifications/domain/entities/app_notification.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_state.dart';

/// Shows a [MaterialBanner] at the top of the screen when critical
/// notifications are present.
///
/// Place this widget inside a `BlocBuilder<NotificationCubit>` at the root
/// of your page (typically wrapping `Scaffold`). The banner is automatically
/// dismissed when the user taps "Tutup" or when there are no more critical
/// notifications.
class NotificationBanner extends StatelessWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is! NotificationLoaded) return const SizedBox.shrink();

        final critical = state.notifications
            .where(
              (n) => n.severity == NotificationSeverity.critical && !n.isRead,
            )
            .toList();

        if (critical.isEmpty) return const SizedBox.shrink();

        // Show the most recent critical notification
        final notification = critical.first;

        return MaterialBanner(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: kColorPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(notification.message)),
            ],
          ),
          backgroundColor: kColorPrimaryContainer,
          leadingPadding: EdgeInsets.zero,
          actions: [
            TextButton(
              onPressed: () =>
                  context.read<NotificationCubit>().dismiss(notification.id),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
