import 'package:flutter/material.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';

/// A card widget that represents a report type for selection on the dashboard.
///
/// Displays an icon, the report type's display name, and a "Pilih" button.
/// Tapping anywhere on the card triggers [onTap].
class ReportTypeCard extends StatelessWidget {
  final ReportType type;
  final IconData icon;
  final VoidCallback onTap;

  const ReportTypeCard({
    super.key,
    required this.type,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                type.displayName,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('Pilih'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
