import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';

/// Toggle control for switching between Pre-Work and Post-Work check types.
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

    return Row(
      children: CheckType.values.map((type) {
        final isSelected = selectedCheckType == type;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                type == CheckType.preWork
                    ? Icons.wb_sunny_outlined
                    : Icons.nights_stay_outlined,
                size: 16,
                color: isSelected
                    ? theme.colors.primaryForeground
                    : theme.colors.mutedForeground,
              ),
              label: Container(
                alignment: Alignment.center,
                child: Text(
                  type.displayName,
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colors.primaryForeground
                        : theme.colors.mutedForeground,
                  ),
                ),
              ),
              selected: isSelected,
              selectedColor: theme.colors.primary,
              backgroundColor: theme.colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? theme.colors.primary
                      : theme.colors.border,
                ),
              ),
              onSelected: (_) => onCheckTypeChanged(type),
            ),
          ),
        );
      }).toList(),
    );
  }
}
