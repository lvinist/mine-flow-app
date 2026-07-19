import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:mine_flow/features/timeline/presentation/bloc/timeline_cubit.dart';
import 'package:mine_flow/features/timeline/presentation/bloc/timeline_state.dart';
import 'package:mine_flow/features/timeline/presentation/widgets/milestone_card.dart';
import 'package:mine_flow/features/timeline/presentation/widgets/timeline_chart.dart';

/// Main page for the Work Timeline feature.
///
/// Displays a chart of cumulative progress (cut/fill/land clearing) over a
/// date range, plus a list of milestones with planned vs. actual tracking.
class TimelinePage extends StatefulWidget {
  final TimelineRepository repository;
  final String siteId;

  const TimelinePage({
    super.key,
    required this.repository,
    required this.siteId,
  });

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  late TimelineCubit _cubit;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cubit = TimelineCubit(
      repository: widget.repository,
      siteId: widget.siteId,
    );
    _load();
  }

  void _load() {
    _cubit.loadData(startDate: _startDate, endDate: _endDate);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _load();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline Pekerjaan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
            onPressed: _load,
          ),
        ],
      ),
      body: BlocProvider<TimelineCubit>.value(
        value: _cubit,
        child: BlocBuilder<TimelineCubit, TimelineState>(
          builder: (context, state) {
            switch (state) {
              case TimelineInitial():
                return const Center(child: Text('Memuat...'));
              case TimelineLoading():
                return const Center(child: CircularProgressIndicator());
              case TimelineError():
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: _load,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              case TimelineLoaded():
                return _TimelineContent(
                  state: state,
                  onDateRangeTap: _pickDateRange,
                  dateLabel:
                      '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}',
                );
            }
          },
        ),
      ),
    );
  }
}

/// The main content body when data is loaded.
class _TimelineContent extends StatelessWidget {
  final TimelineLoaded state;
  final VoidCallback onDateRangeTap;
  final String dateLabel;

  const _TimelineContent({
    required this.state,
    required this.onDateRangeTap,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Separate milestones by status
    final activeMilestones = state.milestones
        .where(
          (m) =>
              m.status == MilestoneStatus.planned ||
              m.status == MilestoneStatus.inProgress,
        )
        .toList();
    final completedMilestones = state.milestones
        .where((m) => m.status == MilestoneStatus.completed)
        .toList();
    final overdueMilestones = state.milestones
        .where((m) => m.status == MilestoneStatus.overdue)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range selector
        InkWell(
          onTap: onDateRangeTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Progress chart section
        Text(
          'Progress Kumulatif',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TimelineChart(dataPoints: state.progressData),

        const SizedBox(height: 24),

        // Summary stats
        Row(
          children: [
            _StatBadge(
              color: Colors.blue,
              label: 'Berjalan',
              count: activeMilestones.length,
            ),
            const SizedBox(width: 8),
            _StatBadge(
              color: Colors.green,
              label: 'Selesai',
              count: completedMilestones.length,
            ),
            const SizedBox(width: 8),
            _StatBadge(
              color: Colors.red,
              label: 'Terlambat',
              count: overdueMilestones.length,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Overdue milestones first
        if (overdueMilestones.isNotEmpty) ...[
          Text(
            'Terlambat',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          ...overdueMilestones.map((m) => MilestoneCard(milestone: m)),
          const SizedBox(height: 16),
        ],

        // Active milestones
        if (activeMilestones.isNotEmpty) ...[
          Text(
            'Aktif',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...activeMilestones.map((m) => MilestoneCard(milestone: m)),
          const SizedBox(height: 16),
        ],

        // Completed milestones
        if (completedMilestones.isNotEmpty) ...[
          Text(
            'Selesai',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          ...completedMilestones.map((m) => MilestoneCard(milestone: m)),
        ],

        // Empty state
        if (state.milestones.isEmpty && state.progressData.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 64,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data timeline',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data akan muncul setelah Anda menambahkan\nmilestone dan mencatat progres.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A small badge showing a count with a coloured dot.
class _StatBadge extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _StatBadge({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $count',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
