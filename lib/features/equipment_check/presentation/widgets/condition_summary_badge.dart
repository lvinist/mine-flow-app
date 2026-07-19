import 'package:flutter/material.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';

/// Card widget displaying overall equipment operational status and SOP pass ratio summary.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final badgeColor = isOperational
        ? const Color(0xFF15803D)
        : const Color(0xFFDC2626);

    final backgroundColor = isOperational
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2));

    final icon = isOperational ? Icons.check_circle_rounded : Icons.warning_amber_rounded;

    final titleText = isOperational
        ? 'OPERASIONAL (PASSED)'
        : 'PERLU MAINTENANCE / FLAGGED';

    final subtitleText = '$passedCount dari $totalCount Item SOP Lolos Check';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: kBorderRadius,
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? kColorTextPrimaryDark : kColorTextPrimary,
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
