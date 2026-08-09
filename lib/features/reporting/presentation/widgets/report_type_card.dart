// Report Type Card — report type selection card in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hand-rolled Material Card with
// ForUI FCard and FButton, using FTheme colors/typography tokens.

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
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
    final theme = FTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: theme.colors.primary),
              const SizedBox(height: 16),
              Text(
                type.displayName,
                textAlign: TextAlign.center,
                style: theme.typography.body.md.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FButton(
                  variant: FButtonVariant.outline,
                  onPress: onTap,
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
