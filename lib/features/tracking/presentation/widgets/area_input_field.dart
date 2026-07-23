import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// A re-usable numeric input field for area (m²) values with unit label,
/// increment/decrement buttons, and validation.
class AreaInputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const AreaInputField({
    super.key,
    required this.label,
    required this.icon,
    this.color,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final controller = TextEditingController(text: value.toStringAsFixed(1));

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row with icon
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: theme.colors.foreground,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Input row with increment/decrement
            Row(
              children: [
                // Decrement button
                FButton(
                  onPress: enabled
                      ? () => onChanged(
                          (value - 10.0).clamp(0.0, double.infinity),
                        )
                      : null,
                  child: const Icon(Icons.remove, size: 16),
                ),
                const SizedBox(width: 8),

                // Numeric text field
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,1}'),
                      ),
                    ],
                    textAlign: TextAlign.center,
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      suffixText: 'm²',
                      suffixStyle: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    onChanged: (text) {
                      final parsed = double.tryParse(text);
                      if (parsed != null && parsed >= 0) {
                        onChanged(parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Increment button
                FButton(
                  onPress: enabled ? () => onChanged(value + 10.0) : null,
                  child: const Icon(Icons.add, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


