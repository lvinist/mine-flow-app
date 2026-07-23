import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A linear progress indicator that shows the upload progress percentage
/// and the file name being uploaded.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced Theme.of(context).colorScheme
/// and TextStyle references with FTheme semantic tokens.
class UploadProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String fileName;

  const UploadProgressIndicator({
    super.key,
    required this.progress,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final percent = (progress * 100).toStringAsFixed(0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // File name
        Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colors.muted,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colors.primary),
          ),
        ),
        const SizedBox(height: 8),
        // Percentage text
        Text(
          '$percent%',
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        // Byte transfer info
        if (progress > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              progress < 1.0 ? 'Mengunggah...' : 'Memproses...',
              style: theme.typography.body.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
      ],
    );
  }
}
