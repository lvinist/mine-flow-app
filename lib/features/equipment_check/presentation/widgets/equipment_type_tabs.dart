import 'package:flutter/material.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Tab selector for switching between Equipment Types (GNSS, Total Station, Drone/UAV).
class EquipmentTypeTabs extends StatelessWidget {
  final EquipmentType selectedType;
  final ValueChanged<EquipmentType> onTypeSelected;

  const EquipmentTypeTabs({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  IconData _getIconForType(EquipmentType type) {
    switch (type) {
      case EquipmentType.gnss:
        return Icons.satellite_alt;
      case EquipmentType.totalStation:
        return Icons.square_foot;
      case EquipmentType.drone:
        return Icons.flight_takeoff;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? kColorSurfaceDark : Colors.grey.shade200,
        borderRadius: kBorderRadius,
      ),
      child: Row(
        children: EquipmentType.values.map((type) {
          final isSelected = selectedType == type;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTypeSelected(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? kColorPrimaryDark : kColorPrimary)
                      : Colors.transparent,
                  borderRadius: kBorderRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getIconForType(type),
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? kColorTextPrimaryDark : kColorTextSecondary),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        type.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? kColorTextPrimaryDark : kColorTextSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
