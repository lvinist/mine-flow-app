/// A small badge showing the unread notification count.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:mine_flow/features/notifications/presentation/bloc/notification_state.dart';

/// Displays a red dot with the unread notification count.
///
/// Intended for use in the app bar (e.g. alongside a bell icon). It reads
/// directly from [NotificationCubit] via `context.watch`.
class NotificationBadge extends StatelessWidget {
  final Color? color;
  final double size;

  const NotificationBadge({super.key, this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is! NotificationLoaded || state.unreadCount == 0) {
          return const SizedBox.shrink();
        }

        final bgColor = color ?? Theme.of(context).colorScheme.error;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(size / 2),
          ),
          constraints: BoxConstraints(minWidth: size, minHeight: size),
          child: Text(
            state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.55,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
