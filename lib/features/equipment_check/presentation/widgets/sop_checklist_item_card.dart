import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';

/// Card representing a single SOP inspection item with Pass/Fail status toggle and notes.
///
/// Standardized with labelled >=48dp selection controls and dual icon+text indicators
/// per FC-54.7-002 and FC-54.7-004.
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
  bool _isUpdatingFromProps = false;

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController(text: widget.item.remarks);
    _remarksController.addListener(_onRemarksChanged);
  }

  void _onRemarksChanged() {
    if (_isUpdatingFromProps) return;
    if (widget.item.isPassed == false) {
      widget.onToggle(false, _remarksController.text);
    }
  }

  @override
  void didUpdateWidget(SopChecklistItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.remarks != oldWidget.item.remarks &&
        _remarksController.text != widget.item.remarks) {
      _isUpdatingFromProps = true;
      _remarksController.text = widget.item.remarks ?? '';
      _isUpdatingFromProps = false;
    }
  }

  @override
  void dispose() {
    _remarksController.removeListener(_onRemarksChanged);
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
                    // PASS Button (>=48dp target, icon + text)
                    Semantics(
                      button: true,
                      selected: isPassed,
                      label: 'PASS - ${item.label}',
                      child: SizedBox(
                        height: 48,
                        child: FButton(
                          variant: isPassed
                              ? FButtonVariant.primary
                              : FButtonVariant.outline,
                          onPress: () => widget.onToggle(true, null),
                          prefix: Icon(
                            LucideIcons.check,
                            size: 16,
                            color: isPassed
                                ? theme.colors.primaryForeground
                                : theme.colors.mutedForeground,
                          ),
                          child: const Text('PASS'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // FAIL Button (>=48dp target, icon + text)
                    Semantics(
                      button: true,
                      selected: isFailed,
                      label: 'FAIL - ${item.label}',
                      child: SizedBox(
                        height: 48,
                        child: FButton(
                          variant: isFailed
                              ? FButtonVariant.destructive
                              : FButtonVariant.outline,
                          onPress: () =>
                              widget.onToggle(false, _remarksController.text),
                          prefix: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: isFailed
                                ? theme.colors.destructiveForeground
                                : theme.colors.mutedForeground,
                          ),
                          child: const Text('FAIL'),
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
