import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Visual auto-save status indicator chip for field data safety.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced hardcoded
/// Colors.amber, Colors.orange, and theme.colorScheme with FTheme semantic tokens.
class AutoSaveIndicator extends StatelessWidget {
  final bool isSaving;
  final bool hasUnsavedChanges;
  final String statusText;

  const AutoSaveIndicator({
    super.key,
    required this.isSaving,
    required this.hasUnsavedChanges,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    Color bgColor;
    Color fgColor;
    IconData iconData;

    if (isSaving) {
      bgColor = theme.colors.primary.withValues(alpha: 0.12);
      fgColor = theme.colors.primary;
      iconData = Icons.sync;
    } else if (hasUnsavedChanges) {
      bgColor = theme.colors.destructive.withValues(alpha: 0.12);
      fgColor = theme.colors.destructive;
      iconData = Icons.edit_note;
    } else {
      bgColor = theme.colors.secondary.withValues(alpha: 0.12);
      fgColor = theme.colors.secondary;
      iconData = Icons.cloud_done_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSaving)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
            )
          else
            Icon(iconData, size: 14, color: fgColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: theme.typography.body.xs.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
