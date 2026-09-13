import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';

/// Toggle control for switching between Pre-Work and Post-Work check types.
///
/// Replaced Material ChoiceChip with ForUI token-aligned >=48dp segmented control
/// matching [EquipmentTypeTabs] visual styling and accessibility per FC-54.7-006.
class CheckTypeToggle extends StatelessWidget {
  final CheckType selectedCheckType;
  final ValueChanged<CheckType> onCheckTypeChanged;

  const CheckTypeToggle({
    super.key,
    required this.selectedCheckType,
    required this.onCheckTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: CheckType.values.map((type) {
          final isSelected = selectedCheckType == type;

          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: 'Pilih tipe inspeksi: ${type.displayName}',
              child: GestureDetector(
                onTap: () => onCheckTypeChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colors.primary
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type == CheckType.preWork
                            ? LucideIcons.sun
                            : LucideIcons.moonStar,
                        size: 18,
                        color: isSelected
                            ? theme.colors.primaryForeground
                            : theme.colors.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            type == CheckType.preWork
                                ? 'Pra-Kerja'
                                : 'Pasca-Kerja',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.body.sm.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colors.primaryForeground
                                  : theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
