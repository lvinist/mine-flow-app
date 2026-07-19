import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A re-usable numeric input field for area (m²) values with unit label,
/// increment/decrement buttons, and validation.
class AreaInputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const AreaInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: value.toStringAsFixed(1));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row with icon
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Input row with increment/decrement
            Row(
              children: [
                // Decrement button
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: enabled
                      ? () => onChanged(
                          (value - 10.0).clamp(0.0, double.infinity),
                        )
                      : null,
                ),

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
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      suffixText: 'm²',
                      suffixStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (text) {
                      final parsed = double.tryParse(text);
                      if (parsed != null && parsed >= 0) {
                        onChanged(parsed);
                      }
                    },
                  ),
                ),

                // Increment button
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: enabled ? () => onChanged(value + 10.0) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
