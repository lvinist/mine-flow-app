import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Preset weather condition options for field operations.
class WeatherOption {
  final String label;
  final IconData icon;

  const WeatherOption(this.label, this.icon);
}

const List<WeatherOption> kWeatherOptions = [
  WeatherOption('Cerah', LucideIcons.sun),
  WeatherOption('Berawan', LucideIcons.cloud),
  WeatherOption('Hujan Ringan', LucideIcons.cloudDrizzle),
  WeatherOption('Hujan Deras', LucideIcons.cloudRainWind),
  WeatherOption('Badai / Extreme', LucideIcons.cloudLightning),
];

/// Weather selector (STEP-55.6, spec §4.5 item 8): single-select with
/// icon + label pairing so selection never relies on color alone
/// (FC-54.6-003). The Material `ChoiceChip` is replaced by ForUI buttons
/// whose variant reflects selection; horizontal scroll keeps all five
/// options reachable on narrow screens.
class WeatherSelector extends StatelessWidget {
  final String? selectedWeather;
  final ValueChanged<String> onWeatherSelected;
  final bool enabled;

  const WeatherSelector({
    super.key,
    required this.selectedWeather,
    required this.onWeatherSelected,
    this.enabled = true,
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
            children: [
              for (final (index, option) in kWeatherOptions.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                FButton(
                  key: ValueKey('weather_option_${option.label}'),
                  variant: selectedWeather == option.label
                      ? FButtonVariant.primary
                      : FButtonVariant.outline,
                  onPress: enabled && selectedWeather != option.label
                      ? () => onWeatherSelected(option.label)
                      : null,
                  prefix: Icon(
                    option.icon,
                    size: 18,
                    color: selectedWeather == option.label
                        ? theme.colors.primaryForeground
                        : theme.colors.primary,
                  ),
                  child: Semantics(
                    label:
                        'Cuaca ${option.label}'
                        '${selectedWeather == option.label ? ', terpilih' : ''}',
                    excludeSemantics: true,
                    child: Text(option.label),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
