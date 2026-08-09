import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_result.dart';

/// A card widget summarizing a successfully generated report.
///
/// Displays the report title, record count, generation timestamp, and file size.
class ReportSummaryCard extends StatelessWidget {
  final ReportResult result;

  const ReportSummaryCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colors.primary.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: theme.colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Laporan Berhasil Dibuat',
                    style: theme.typography.body.md.copyWith(
                      color: theme.colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const FDivider(),
            const SizedBox(height: 8),
            _buildRow('Judul:', result.title, theme),
            const SizedBox(height: 4),
            _buildRow('Jumlah Data:', '${result.recordCount} baris', theme),
            const SizedBox(height: 4),
            _buildRow(
              'Waktu Dibuat:',
              dateFormat.format(result.generatedAt),
              theme,
            ),
            const SizedBox(height: 4),
            _buildRow(
              'Ukuran File:',
              '${(result.pdfBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, FThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
