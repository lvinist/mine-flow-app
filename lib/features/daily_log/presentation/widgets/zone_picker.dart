import 'package:flutter/material.dart';

/// Default mining site active operational zones.
const List<Map<String, String>> kDefaultOperationalZones = [
  {'id': 'ZONE-PIT-A', 'name': 'Pit A - Utama (North Cut)'},
  {'id': 'ZONE-PIT-B', 'name': 'Pit B - Timur (South Cut)'},
  {'id': 'ZONE-SP-01', 'name': 'Stockpile 1 (ROM)'},
  {'id': 'ZONE-SP-02', 'name': 'Stockpile 2 (High Grade)'},
  {'id': 'ZONE-HAUL-03', 'name': 'Jalur Angkut Utama (Haul Road 3)'},
  {'id': 'ZONE-DISPOSAL-01', 'name': 'Disposal Site Alpha'},
];

/// Dropdown picker for selecting operational mine zone.
class ZonePicker extends StatelessWidget {
  final String? selectedZoneId;
  final ValueChanged<String?> onZoneSelected;
  final List<Map<String, String>> zones;

  const ZonePicker({
    super.key,
    required this.selectedZoneId,
    required this.onZoneSelected,
    this.zones = kDefaultOperationalZones,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zona Operasional',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: zones.any((z) => z['id'] == selectedZoneId) ? selectedZoneId : null,
          decoration: const InputDecoration(
            hintText: 'Pilih Zona Operasional...',
            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
          ),
          items: zones.map((zone) {
            return DropdownMenuItem<String>(
              value: zone['id'],
              child: Text(
                zone['name'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }).toList(),
          onChanged: onZoneSelected,
        ),
      ],
    );
  }
}
