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
/// Phase 2 polish: AnimatedSwitcher for smooth state transitions,
/// micro-interactions on the date range selector and section headers,
/// standardised shadcn-admin colour tokens and spacing.
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
    return Scaffold(
      body: BlocProvider<TimelineCubit>.value(
        value: _cubit,
        child: BlocBuilder<TimelineCubit, TimelineState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: switch (state) {
                TimelineInitial() => const Center(child: Text('Memuat...')),
                TimelineLoading() => const _LoadingView(
                  key: ValueKey('loading'),
                ),
                TimelineError() => _ErrorView(
                  key: const ValueKey('error'),
                  message: state.message,
                  onRetry: _load,
                ),
                TimelineLoaded() => CustomScrollView(
                  key: const ValueKey('loaded'),
                  slivers: [
                    // App bar
                    SliverAppBar(
                      title: const Text('Timeline Pekerjaan'),
                      floating: true,
                      snap: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Muat Ulang',
                          onPressed: _load,
                        ),
                      ],
                    ),

                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _TimelineContent(
                            state: state,
                            onDateRangeTap: _pickDateRange,
                            dateLabel:
                                '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}',
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

/// Animated loading placeholder with a shimmer-like appearance.
class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data timeline...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state with retry action.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.error_outline,
                size: 28,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date range selector — shadcn-style filter button
        InkWell(
          onTap: onDateRangeTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TimelineChart(dataPoints: state.progressData),
        ),

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
              color: const Color(0xFF15803D),
              label: 'Selesai',
              count: completedMilestones.length,
            ),
            const SizedBox(width: 8),
            _StatBadge(
              color: const Color(0xFFDC2626),
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
              color: const Color(0xFFDC2626),
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
              color: const Color(0xFF15803D),
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Icon(
                      Icons.timeline,
                      size: 36,
                      color: theme.colorScheme.outlineVariant,
                    ),
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

/// A small badge showing a count with a coloured dot — shadcn-admin style.
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
