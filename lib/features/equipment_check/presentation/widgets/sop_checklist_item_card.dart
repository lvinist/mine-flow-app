import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';

/// Card representing a single SOP inspection item with Pass/Fail status toggle and notes.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced hardcoded Colors.*
/// with FTheme semantic tokens.
class SopChecklistItemCard extends StatelessWidget {
  final CheckItem item;
  final Function(bool isPassed, String? remarks) onToggle;

  const SopChecklistItemCard({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: item.isPassed
              ? theme.colors.border
              : theme.colors.destructive.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PASS Button
                    InkWell(
                      onTap: () => onToggle(true, null),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: item.isPassed
                              ? theme.colors.secondary
                              : theme.colors.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PASS',
                          style: theme.typography.body.xs.copyWith(
                            fontWeight: FontWeight.bold,
                            color: item.isPassed
                                ? theme.colors.primaryForeground
                                : theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // FAIL Button
                    InkWell(
                      onTap: () => onToggle(false, item.remarks),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: !item.isPassed
                              ? theme.colors.destructive
                              : theme.colors.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FAIL',
                          style: theme.typography.body.xs.copyWith(
                            fontWeight: FontWeight.bold,
                            color: !item.isPassed
                                ? theme.colors.primaryForeground
                                : theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!item.isPassed) ...[
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: item.remarks),
                onChanged: (val) => onToggle(false, val),
                decoration: const InputDecoration(
                  labelText: 'Catatan Kerusakan / Kendala (Wajib)',
                  hintText: 'Misal: Baterai 1 drop, kabel kendor',
                  isDense: true,
                  prefixIcon: Icon(Icons.edit_note, size: 18),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
