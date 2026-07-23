import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Preset weather condition options for field operations.
class WeatherOption {
  final String label;
  final IconData icon;

  const WeatherOption(this.label, this.icon);
}

const List<WeatherOption> kWeatherOptions = [
  WeatherOption('Cerah', Icons.wb_sunny_outlined),
  WeatherOption('Berawan', Icons.cloud_outlined),
  WeatherOption('Hujan Ringan', Icons.grain_outlined),
  WeatherOption('Hujan Deras', Icons.thunderstorm_outlined),
  WeatherOption('Badai / Extreme', Icons.warning_amber_rounded),
];

/// Interactive horizontal choice selector widget for logging field weather conditions.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced Theme.of(context).colorScheme
/// with FTheme semantic tokens.
class WeatherSelector extends StatelessWidget {
  final String? selectedWeather;
  final ValueChanged<String> onWeatherSelected;

  const WeatherSelector({
    super.key,
    required this.selectedWeather,
    required this.onWeatherSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kondisi Cuaca Lapangan',
          style: theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kWeatherOptions.map((option) {
              final isSelected = selectedWeather == option.label;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  avatar: Icon(
                    option.icon,
                    size: 18,
                    color: isSelected
                        ? theme.colors.primaryForeground
                        : theme.colors.primary,
                  ),
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onWeatherSelected(option.label);
                    }
                  },
                  selectedColor: theme.colors.primary,
                  labelStyle: theme.typography.body.xs.copyWith(
                    color: isSelected
                        ? theme.colors.primaryForeground
                        : theme.colors.foreground,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
