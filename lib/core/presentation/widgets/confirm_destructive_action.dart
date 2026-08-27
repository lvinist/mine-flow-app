import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';

/// Supervisor-gated confirmation for a destructive action.
///
/// CF-019–024: deletes of operational/safety records must be role-gated to
/// supervisors and explicitly confirmed. Returns true only when the current
/// user is a supervisor AND confirms the dialog.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String message,
}) async {
  final theme = FTheme.of(context);

  final user = authCubit?.state.user;
  if (user == null || !user.isSupervisor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Hanya supervisor yang dapat menghapus data.',
        ),
        backgroundColor: theme.colors.destructive,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus Data'),
      content: Text(message),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FButton(
          variant: FButtonVariant.destructive,
          onPress: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  return confirmed == true;
}
