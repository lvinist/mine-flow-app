import 'package:flutter/material.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kCardRadius = 12;
const double _kSpacing16 = 16;
const double _kSpacing20 = 20;

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

    return Semantics(
      label: type.displayName,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_kCardRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kCardRadius),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_kSpacing20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: _kSpacing16),
                  Text(
                    type.displayName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Pilih'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
