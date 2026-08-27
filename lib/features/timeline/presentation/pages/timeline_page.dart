// Timeline Page — Work Timeline visualization in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hand-rolled Material layouts and
// hardcoded raw colors with ForUI components (FButton, FCard, FBadge) and FTheme
// colors/typography tokens. No logic, state, or data-fetching changes.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:mine_flow/features/timeline/presentation/bloc/timeline_cubit.dart';
import 'package:mine_flow/features/timeline/presentation/bloc/timeline_state.dart';
import 'package:mine_flow/features/timeline/presentation/widgets/milestone_card.dart';
import 'package:mine_flow/features/timeline/presentation/widgets/timeline_chart.dart';

const double _kPagePadding = 24;
const double _kSpacing8 = 8;
const double _kSpacing12 = 12;
const double _kSpacing16 = 16;
const double _kSpacing20 = 20;
const double _kSpacing24 = 24;

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
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: MediaQuery.of(context).size.width > 800
          ? null
          : AppBar(
              title: Semantics(
                header: true,
                child: Text(
                  'Timeline Pekerjaan',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              elevation: 0,
            ),
      body: Column(
        children: [
          // CF-032: refresh action lives in the body so it persists on the
          // desktop layout where the AppBar is absent.
          if (MediaQuery.of(context).size.width > 800)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _kPagePadding,
                _kSpacing12,
                _kPagePadding,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: _load,
                    prefix: const Icon(Icons.refresh, size: 18),
                    child: const Text('Muat Ulang'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocProvider<TimelineCubit>.value(
              value: _cubit,
              child: BlocBuilder<TimelineCubit, TimelineState>(
                builder: (context, state) {
                  switch (state) {
                    case TimelineInitial():
                      return Center(
                        child: Text(
                          'Memuat...',
                          style: theme.typography.body.md.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      );
                    case TimelineLoading():
                      return const Center(child: CircularProgressIndicator());
                    case TimelineError():
                      return _buildErrorState(context, state, theme);
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
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    TimelineError state,
    FThemeData theme,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(_kPagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(_kSpacing16),
              decoration: BoxDecoration(
                color: theme.colors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(_kSpacing12),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colors.destructive,
              ),
            ),
            const SizedBox(height: _kSpacing16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: theme.typography.body.md.copyWith(
                color: theme.colors.mutedForeground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: _kSpacing16),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _load,
              child: const Text('Coba Lagi'),
            ),
          ],
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
    final theme = FTheme.of(context);

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
      padding: const EdgeInsets.all(_kPagePadding),
      children: [
        // Date range selector
        InkWell(
          onTap: onDateRangeTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _kSpacing12,
              vertical: _kSpacing12,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, size: 18, color: theme.colors.primary),
                const SizedBox(width: _kSpacing8),
                Text(
                  dateLabel,
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: _kSpacing20),

        // Progress chart section
        Text(
          'Progress Kumulatif',
          style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: _kSpacing12),
        TimelineChart(dataPoints: state.progressData),

        const SizedBox(height: _kSpacing24),

        // Summary stats
        Row(
          children: [
            _StatBadge(
              color: theme.colors.primary,
              label: 'Berjalan',
              count: activeMilestones.length,
            ),
            const SizedBox(width: _kSpacing8),
            // CF-067: "Selesai" uses a distinct token from "Berjalan".
            _StatBadge(
              color: theme.colors.secondary,
              label: 'Selesai',
              count: completedMilestones.length,
            ),
            const SizedBox(width: _kSpacing8),
            _StatBadge(
              color: theme.colors.destructive,
              label: 'Terlambat',
              count: overdueMilestones.length,
            ),
          ],
        ),
        const SizedBox(height: _kSpacing16),

        // Overdue milestones first
        if (overdueMilestones.isNotEmpty) ...[
          Text(
            'Terlambat',
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.destructive,
            ),
          ),
          const SizedBox(height: _kSpacing8),
          ...overdueMilestones.map((m) => MilestoneCard(milestone: m)),
          const SizedBox(height: _kSpacing16),
        ],

        // Active milestones
        if (activeMilestones.isNotEmpty) ...[
          Text(
            'Aktif',
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: _kSpacing8),
          ...activeMilestones.map((m) => MilestoneCard(milestone: m)),
          const SizedBox(height: _kSpacing16),
        ],

        // Completed milestones
        if (completedMilestones.isNotEmpty) ...[
          Text(
            'Selesai',
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.primary,
            ),
          ),
          const SizedBox(height: _kSpacing8),
          ...completedMilestones.map((m) => MilestoneCard(milestone: m)),
        ],

        // Empty state (CF-066: show when milestones are empty, regardless of
        // progress — a progress-only site still gets an explanation)
        if (state.milestones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 64,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(height: _kSpacing16),
                  Text(
                    'Belum ada data timeline',
                    style: theme.typography.body.md,
                  ),
                  const SizedBox(height: _kSpacing8),
                  Text(
                    'Belum ada milestone yang tersedia untuk ditampilkan.',
                    textAlign: TextAlign.center,
                    style: theme.typography.body.sm.copyWith(
                      color: theme.colors.mutedForeground,
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
    final theme = FTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label $count',
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
