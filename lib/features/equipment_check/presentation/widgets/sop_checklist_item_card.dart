import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';

/// Card representing a single SOP inspection item with Pass/Fail status toggle and notes.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced hardcoded Colors.*
/// with FTheme semantic tokens.
///
/// CF-017: renders a tri-state verdict — un-answered (`null`), pass (`true`),
/// or fail (`false`) — so a fresh item is visibly unanswered, never pre-passed.
class SopChecklistItemCard extends StatefulWidget {
  final CheckItem item;
  final Function(bool, String?) onToggle;

  const SopChecklistItemCard({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  State<SopChecklistItemCard> createState() => _SopChecklistItemCardState();
}

class _SopChecklistItemCardState extends State<SopChecklistItemCard> {
  late final TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController(text: widget.item.remarks);
    _remarksController.addListener(() {
      widget.onToggle(false, _remarksController.text);
    });
  }

  @override
  void didUpdateWidget(SopChecklistItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.remarks != oldWidget.item.remarks &&
        _remarksController.text != widget.item.remarks) {
      _remarksController.text = widget.item.remarks ?? '';
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final item = widget.item;
    final isPassed = item.isPassed == true;
    final isFailed = item.isPassed == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFailed
              ? theme.colors.destructive.withValues(alpha: 0.5)
              : theme.colors.border,
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
                      onTap: () => widget.onToggle(true, null),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? theme.colors.secondary
                              : theme.colors.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PASS',
                          style: theme.typography.body.xs.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPassed
                                ? theme.colors.primaryForeground
                                : theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // FAIL Button
                    InkWell(
                      onTap: () => widget.onToggle(false, _remarksController.text),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isFailed
                              ? theme.colors.destructive
                              : theme.colors.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FAIL',
                          style: theme.typography.body.xs.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isFailed
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
            if (isFailed) ...[
              const SizedBox(height: 12),
              FTextField(
                control: FTextFieldControl.managed(
                  controller: _remarksController,
                ),
                label: const Text('Catatan Kerusakan / Kendala (Wajib)'),
                hint: 'Misal: Baterai 1 drop, kabel kendor',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
