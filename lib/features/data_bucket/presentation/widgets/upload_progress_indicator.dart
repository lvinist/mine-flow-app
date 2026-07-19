import 'package:flutter/material.dart';

/// A linear progress indicator that shows the upload progress percentage
/// and the file name being uploaded.
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
    final theme = Theme.of(context);
    final percent = (progress * 100).toStringAsFixed(0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // File name
        Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Percentage text
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // Byte transfer info
        if (progress > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              progress < 1.0 ? 'Mengunggah...' : 'Memproses...',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
