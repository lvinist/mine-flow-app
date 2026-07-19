import 'package:flutter/material.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: CheckType.values.map((type) {
        final isSelected = selectedCheckType == type;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                type == CheckType.preWork ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? kColorTextPrimaryDark : kColorTextSecondary),
              ),
              label: Container(
                alignment: Alignment.center,
                child: Text(
                  type.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? kColorTextPrimaryDark : kColorTextSecondary),
                  ),
                ),
              ),
              selected: isSelected,
              selectedColor: isDark ? kColorPrimaryDark : kColorPrimary,
              backgroundColor: isDark ? kColorSurfaceDark : kColorSurface,
              shape: RoundedRectangleBorder(
                borderRadius: kBorderRadius,
                side: BorderSide(
                  color: isSelected
                      ? (isDark ? kColorPrimaryDark : kColorPrimary)
                      : (isDark ? kColorBorderDark : kColorBorder),
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
