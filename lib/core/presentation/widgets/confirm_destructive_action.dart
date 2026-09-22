import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/domain/entities/user_entity.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';

/// Supervisor-gated confirmation for a destructive action.
///
/// CF-019–024: deletes of operational/safety records must be role-gated to
/// supervisors and explicitly confirmed. Returns true only when the current
/// user is a supervisor AND confirms the dialog.
///
/// STEP-55.7 RESIDUAL (2026-09-21): [sessionUser] lets a caller pass the
/// session it already resolved through the widget tree (see
/// `MineFlowApp`'s root `BlocProvider<AuthCubit>`), so the gate is testable
/// per-widget. When omitted, the process-wide [authCubit] global is used —
/// every existing caller keeps that behavior unchanged.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String message,
  UserEntity? sessionUser,
}) async {
  final user = sessionUser ?? authCubit?.state.user;
  if (user == null || !user.isSupervisor) {
    showFToast(
      context: context,
      variant: FToastVariant.destructive,
      title: const Text('Hanya supervisor yang dapat menghapus data.'),
    );
    return false;
  }

  // CF-087: ForUI dialog (FDialog + FAlert) instead of Material AlertDialog.
  final confirmed = await showFDialog<bool>(
    context: context,
    builder: (context, style, animation) => FDialog(
      builder: (context, style) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FAlert(
            variant: FAlertVariant.destructive,
            title: const Text('Hapus Data'),
            subtitle: Text(message),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              FButton(
                variant: FButtonVariant.destructive,
                onPress: () => Navigator.of(context).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  return confirmed == true;
}
