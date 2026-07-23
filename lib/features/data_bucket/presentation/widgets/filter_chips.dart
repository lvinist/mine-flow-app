import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A row of filter dropdowns for file type and zone selection.
///
/// Fires [onTypeChanged] and [onZoneChanged] callbacks when the user
/// changes the selected filter value. Pass `null` to clear a filter.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced
/// Theme.of(context).colorScheme.outline with FTheme border token.
class FilterChips extends StatelessWidget {
  final String? selectedType;
  final String? selectedZone;
  final List<String> availableTypes;
  final List<String> availableZones;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onZoneChanged;

  const FilterChips({
    super.key,
    this.selectedType,
    this.selectedZone,
    required this.availableTypes,
    required this.availableZones,
    required this.onTypeChanged,
    required this.onZoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // File type dropdown
          Expanded(
            child: _FilterDropdown(
              value: selectedType,
              hint: 'Semua Tipe',
              items: availableTypes,
              itemLabel: _typeLabel,
              onChanged: onTypeChanged,
            ),
          ),
          const SizedBox(width: 12),
          // Zone dropdown
          Expanded(
            child: _FilterDropdown(
              value: selectedZone,
              hint: 'Semua Zona',
              items: availableZones,
              itemLabel: (z) => z,
              onChanged: onZoneChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a human-readable label for the file type extension.
  static String _typeLabel(String type) {
    switch (type) {
      case '.shp':
        return 'Shapefile (.shp)';
      case '.tiff':
      case '.tif':
        return 'GeoTIFF (.tiff)';
      case '.dxf':
        return 'DXF (.dxf)';
      case '.dwg':
        return 'DWG (.dwg)';
      case '.csv':
        return 'CSV (.csv)';
      case '.kml':
        return 'KML (.kml)';
      case '.kmz':
        return 'KMZ (.kmz)';
      case '.gpx':
        return 'GPX (.gpx)';
      case '.pdf':
        return 'PDF (.pdf)';
      default:
        return type;
    }
  }
}

/// A compact dropdown widget used inside [FilterChips].
class _FilterDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final String Function(String) itemLabel;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    this.value,
    required this.hint,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: theme.typography.body.xs),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(hint, style: theme.typography.body.xs),
            ),
            ...items.map(
              (item) => DropdownMenuItem<String?>(
                value: item,
                child: Text(itemLabel(item), style: theme.typography.body.xs),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
