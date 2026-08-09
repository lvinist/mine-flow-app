import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';

/// Card widget displaying overall equipment operational status and SOP pass ratio summary.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced hardcoded Colors.*,
/// kColor* constants with FTheme semantic tokens.
class ConditionSummaryBadge extends StatelessWidget {
  final CheckStatus status;
  final bool isOperational;
  final int passedCount;
  final int totalCount;

  const ConditionSummaryBadge({
    super.key,
    required this.status,
    required this.isOperational,
    required this.passedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    final badgeColor = isOperational
        ? theme.colors.secondary
        : theme.colors.destructive;

    final backgroundColor = isOperational
        ? theme.colors.secondary.withValues(alpha: 0.12)
        : theme.colors.destructive.withValues(alpha: 0.12);

    final icon = isOperational
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;

    final titleText = isOperational
        ? 'OPERASIONAL (PASSED)'
        : 'PERLU MAINTENANCE / FLAGGED';

    final subtitleText = '$passedCount dari $totalCount Item SOP Lolos Check';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colors.primaryForeground, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
