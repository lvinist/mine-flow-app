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

  const DateRangeSelector({
    super.key,
    required this.initialRange,
    required this.onChanged,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late String _selectedOption;
  late DateRangeFilter _currentRange;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.initialRange;
    _selectedOption = 'Minggu Ini';
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
        // Fallback to previous if canceled
        setState(() {
          _selectedOption = 'Minggu Ini';
          _currentRange = DateRangeFilter.currentWeek();
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
        DropdownButtonFormField<String>(
          initialValue: _selectedOption,
          decoration: const InputDecoration(
            labelText: 'Periode Laporan',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'Minggu Ini', child: Text('Minggu Ini')),
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
          onChanged: _onOptionChanged,
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
