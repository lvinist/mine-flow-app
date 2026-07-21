import 'package:flutter/material.dart';

/// Visual auto-save status indicator chip for field data safety.
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
    final theme = Theme.of(context);

    Color bgColor;
    Color fgColor;
    IconData iconData;

    if (isSaving) {
      bgColor = Colors.amber.shade100;
      fgColor = Colors.amber.shade900;
      iconData = Icons.sync;
    } else if (hasUnsavedChanges) {
      bgColor = Colors.orange.shade100;
      fgColor = Colors.orange.shade900;
      iconData = Icons.edit_note;
    } else {
      bgColor = theme.colorScheme.primaryContainer;
      fgColor = theme.colorScheme.primary;
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fgColor,
              ),
            )
          else
            Icon(iconData, size: 14, color: fgColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
