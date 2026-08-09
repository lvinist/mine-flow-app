import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// A re-usable numeric input field for volume values with customizable unit label
/// and validation (stepper buttons removed per UX requirements).
class VolumeInputField extends StatefulWidget {
  final String label;
  final IconData icon;
  final String unit;
  final Color? color;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const VolumeInputField({
    super.key,
    required this.label,
    required this.icon,
    this.unit = 'm³',
    this.color,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<VolumeInputField> createState() => _VolumeInputFieldState();
}

class _VolumeInputFieldState extends State<VolumeInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value > 0 ? widget.value.toStringAsFixed(1) : '',
    );
  }

  @override
  void didUpdateWidget(VolumeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final parsed = double.tryParse(_controller.text) ?? 0.0;
      if (parsed != widget.value) {
        // Only update text if it actually differs from what user is typing
        _controller.text = widget.value > 0
            ? widget.value.toStringAsFixed(1)
            : '';
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row with icon
            Row(
              children: [
                Icon(widget.icon, size: 18, color: theme.colors.foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Numeric text field without stepper buttons
            TextField(
              controller: _controller,
              enabled: widget.enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.start,
              style: theme.typography.body.md.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: '0.0',
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                suffixText: widget.unit,
                suffixStyle: theme.typography.body.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
              onChanged: (text) {
                if (text.isEmpty) {
                  widget.onChanged(0.0);
                  return;
                }
                final parsed = double.tryParse(text);
                if (parsed != null && parsed >= 0) {
                  widget.onChanged(parsed);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
