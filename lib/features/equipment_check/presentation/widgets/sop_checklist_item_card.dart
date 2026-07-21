import 'package:flutter/material.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';

/// Card representing a single SOP inspection item with Pass/Fail status toggle and notes.
class SopChecklistItemCard extends StatelessWidget {
  final CheckItem item;
  final Function(bool isPassed, String? remarks) onToggle;

  const SopChecklistItemCard({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark ? kColorSurfaceDark : kColorSurface,
      shape: RoundedRectangleBorder(
        borderRadius: kBorderRadius,
        side: BorderSide(
          color: item.isPassed
              ? (isDark ? kColorBorderDark : kColorBorder)
              : const Color(0xFFDC2626).withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? kColorTextPrimaryDark : kColorTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PASS Button
                    InkWell(
                      onTap: () => onToggle(true, null),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: item.isPassed
                              ? const Color(0xFF15803D)
                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PASS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.isPassed
                                ? Colors.white
                                : (isDark ? kColorTextPrimaryDark : kColorTextSecondary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // FAIL Button
                    InkWell(
                      onTap: () => onToggle(false, item.remarks),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: !item.isPassed
                              ? const Color(0xFFDC2626)
                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FAIL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !item.isPassed
                                ? Colors.white
                                : (isDark ? kColorTextPrimaryDark : kColorTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!item.isPassed) ...[
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: item.remarks),
                onChanged: (val) => onToggle(false, val),
                decoration: const InputDecoration(
                  labelText: 'Catatan Kerusakan / Kendala (Wajib)',
                  hintText: 'Misal: Baterai 1 drop, kabel kendor',
                  isDense: true,
                  prefixIcon: Icon(Icons.edit_note, size: 18),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
