import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/reporting/domain/entities/date_range_filter.dart';

/// A dropdown-based date range selector for report configuration.
///
/// Offers preset options (Minggu Ini, Bulan Ini, Year-to-Date, Project-to-Date)
/// and a custom date range picker via [showDateRangePicker].
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced
/// Theme.of(context).textTheme / colorScheme with FTheme tokens.
class DateRangeSelector extends StatefulWidget {
  final DateRangeFilter initialRange;
  final ValueChanged<DateRangeFilter> onChanged;
  final bool enabled;

  const DateRangeSelector({
    super.key,
    required this.initialRange,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late String _selectedOption;
  late DateRangeFilter _currentRange;

  /// CF-073: derive the dropdown label from the actual range (not a hardcoded
  /// 'Minggu Ini') so the label and the held range can't desync.
  String _optionForRange(DateRangeFilter range) {
    if (range == DateRangeFilter.currentWeek()) return 'Minggu Ini';
    if (range == DateRangeFilter.currentMonth()) return 'Bulan Ini';
    if (range == DateRangeFilter.yearToDate()) return 'Year-to-Date';
    if (range == DateRangeFilter.projectToDate()) return 'Project-to-Date';
    return 'Kustom';
  }

  @override
  void initState() {
    super.initState();
    _currentRange = widget.initialRange;
    _selectedOption = _optionForRange(widget.initialRange);
  }

  void _onOptionChanged(String? newValue) async {
    if (newValue == null) return;

    setState(() {
      _selectedOption = newValue;
    });

    if (newValue == 'Minggu Ini') {
      _updateRange(DateRangeFilter.currentWeek());
    } else if (newValue == 'Bulan Ini') {
      _updateRange(DateRangeFilter.currentMonth());
    } else if (newValue == 'Year-to-Date') {
      _updateRange(DateRangeFilter.yearToDate());
    } else if (newValue == 'Project-to-Date') {
      _updateRange(DateRangeFilter.projectToDate());
    } else if (newValue == 'Kustom') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(
          start: _currentRange.startDate,
          end: _currentRange.endDate,
        ),
      );
      if (picked != null) {
        _updateRange(
          DateRangeFilter(
            startDate: picked.start,
            endDate: DateTime(
              picked.end.year,
              picked.end.month,
              picked.end.day,
              23,
              59,
              59,
            ),
          ),
        );
      } else {
        // CF-073: on cancel, restore the label to match the still-current
        // range (previously hardcoded back to 'Minggu Ini', desyncing it).
        setState(() {
          _selectedOption = _optionForRange(_currentRange);
        });
      }
    }
  }

  void _updateRange(DateRangeFilter newRange) {
    setState(() {
      _currentRange = newRange;
    });
    widget.onChanged(newRange);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final rangeText =
        '${dateFormat.format(_currentRange.startDate)} - ${dateFormat.format(_currentRange.endDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Periode Laporan',
          style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FCard(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedOption,
              decoration: const InputDecoration(border: InputBorder.none),
              items: const [
                DropdownMenuItem(
                  value: 'Minggu Ini',
                  child: Text('Minggu Ini'),
                ),
                DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                DropdownMenuItem(
                  value: 'Year-to-Date',
                  child: Text('Year-to-Date'),
                ),
                DropdownMenuItem(
                  value: 'Project-to-Date',
                  child: Text('Project-to-Date'),
                ),
                DropdownMenuItem(value: 'Kustom', child: Text('Kustom...')),
              ],
              onChanged: widget.enabled ? _onOptionChanged : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rentang: $rangeText',
          style: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
