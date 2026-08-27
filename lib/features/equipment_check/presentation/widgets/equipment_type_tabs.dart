import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Tab selector for switching between Equipment Types (GNSS, Total Station, Drone/UAV).
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced hardcoded Colors.*,
/// kColor* with FTheme semantic tokens.
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
        return LucideIcons.satellite;
      case EquipmentType.totalStation:
        return LucideIcons.ruler;
      case EquipmentType.drone:
        return LucideIcons.plane;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: EquipmentType.values.map((type) {
            final isSelected = selectedType == type;

            return ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 110),
              child: GestureDetector(
                onTap: () => onTypeSelected(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
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
                        _getIconForType(type),
                        size: 18,
                        color: isSelected
                            ? theme.colors.primaryForeground
                            : theme.colors.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.displayName,
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
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
