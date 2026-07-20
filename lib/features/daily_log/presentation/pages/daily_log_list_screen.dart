import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_form_screen.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/daily_log_card.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kPagePadding = 24;

/// Accent — Cyan / Teal, used sparingly for interactive elements.
const Color _kAccent = Color(0xFF0891B2);

/// Micro-interaction duration for state transitions.
const Duration _kTransitionDuration = Duration(milliseconds: 200);

// --- Responsive breakpoints (DESIGN.md §28) ---
const double _kBreakMobile = 600;
const double _kBreakTablet = 900;

/// Screen listing daily log history with status filtering and option to create new log entries.
class DailyLogListScreen extends StatelessWidget {
  final DailyLogRepository repository;
  final String foremanId;
  final String siteId;

  const DailyLogListScreen({
    super.key,
    required this.repository,
    required this.foremanId,
    required this.siteId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DailyLogBloc(repository: repository)
            ..add(LoadDailyLogsListEvent(siteId: siteId, foremanId: foremanId)),
      child: DailyLogListView(
        repository: repository,
        foremanId: foremanId,
        siteId: siteId,
      ),
    );
  }
}

class DailyLogListView extends StatefulWidget {
  final DailyLogRepository repository;
  final String foremanId;
  final String siteId;

  const DailyLogListView({
    super.key,
    required this.repository,
    required this.foremanId,
    required this.siteId,
  });

  @override
  State<DailyLogListView> createState() => _DailyLogListViewState();
}

class _DailyLogListViewState extends State<DailyLogListView> {
  LogStatus? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            'Riwayat Log Harian',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        child: _buildBody(context, colorScheme, theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_new_daily_log_fab'),
        icon: const Icon(Icons.add),
        label: const Text('Log Baru'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => DailyLogFormScreen(
                    repository: widget.repository,
                    foremanId: widget.foremanId,
                    siteId: widget.siteId,
                  ),
                ),
              )
              .then((_) {
                if (context.mounted) {
                  context.read<DailyLogBloc>().add(
                    LoadDailyLogsListEvent(
                      siteId: widget.siteId,
                      foremanId: widget.foremanId,
                      statusFilter: _selectedStatusFilter,
                    ),
                  );
                }
              });
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return BlocBuilder<DailyLogBloc, DailyLogState>(
      builder: (context, state) {
        if (state is DailyLogLoading) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        if (state is DailyLogError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(_kPagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: _kTransitionDuration,
                    curve: Curves.easeOutQuart,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        context.read<DailyLogBloc>().add(
                          LoadDailyLogsListEvent(
                            siteId: widget.siteId,
                            foremanId: widget.foremanId,
                            statusFilter: _selectedStatusFilter,
                          ),
                        );
                      },
                      child: const Text('Muat Ulang'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is DailyLogsLoaded) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= _kBreakTablet;
              final bool isMobile = constraints.maxWidth < _kBreakMobile;
              // Narrow layout: single-column list. Wide layout: 2-column grid.
              final int crossAxisCount = isWide ? 2 : 1;

              final EdgeInsets contentPadding = EdgeInsets.only(
                left: isWide ? 32 : _kPagePadding,
                right: isWide ? 32 : _kPagePadding,
                bottom: 96,
              );
              final double horizontalPadding = isWide
                  ? 16.0
                  : _kPagePadding.toDouble();

              return CustomScrollView(
                slivers: [
                  // --- Filter Chips Row ---
                  SliverToBoxAdapter(
                    child: Semantics(
                      label: 'Filter status log',
                      sortKey: const OrdinalSortKey(0),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          _kPagePadding,
                          horizontalPadding,
                          0,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                label: 'Semua Status',
                                selected: _selectedStatusFilter == null,
                                onSelected: (selected) {
                                  setState(() => _selectedStatusFilter = null);
                                  context.read<DailyLogBloc>().add(
                                    LoadDailyLogsListEvent(
                                      siteId: widget.siteId,
                                      foremanId: widget.foremanId,
                                      statusFilter: null,
                                    ),
                                  );
                                },
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Draft',
                                selected:
                                    _selectedStatusFilter == LogStatus.draft,
                                onSelected: (selected) {
                                  final filter = selected
                                      ? LogStatus.draft
                                      : null;
                                  setState(
                                    () => _selectedStatusFilter = filter,
                                  );
                                  context.read<DailyLogBloc>().add(
                                    LoadDailyLogsListEvent(
                                      siteId: widget.siteId,
                                      foremanId: widget.foremanId,
                                      statusFilter: filter,
                                    ),
                                  );
                                },
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Terkirim',
                                selected:
                                    _selectedStatusFilter ==
                                    LogStatus.submitted,
                                onSelected: (selected) {
                                  final filter = selected
                                      ? LogStatus.submitted
                                      : null;
                                  setState(
                                    () => _selectedStatusFilter = filter,
                                  );
                                  context.read<DailyLogBloc>().add(
                                    LoadDailyLogsListEvent(
                                      siteId: widget.siteId,
                                      foremanId: widget.foremanId,
                                      statusFilter: filter,
                                    ),
                                  );
                                },
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Disetujui',
                                selected:
                                    _selectedStatusFilter == LogStatus.approved,
                                onSelected: (selected) {
                                  final filter = selected
                                      ? LogStatus.approved
                                      : null;
                                  setState(
                                    () => _selectedStatusFilter = filter,
                                  );
                                  context.read<DailyLogBloc>().add(
                                    LoadDailyLogsListEvent(
                                      siteId: widget.siteId,
                                      foremanId: widget.foremanId,
                                      statusFilter: filter,
                                    ),
                                  );
                                },
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Log count header ---
                  SliverToBoxAdapter(
                    child: Semantics(
                      label: '${state.logs.length} log harian',
                      sortKey: const OrdinalSortKey(1),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: 16,
                        ),
                        child: Text(
                          '${state.logs.length} log harian',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Logs List or Empty State ---
                  if (state.logs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Semantics(
                        label: 'Belum ada data log harian',
                        sortKey: const OrdinalSortKey(2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Belum ada data log harian.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tekan "Log Baru" untuk membuat entri pertama.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: contentPadding,
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 12,
                          childAspectRatio: isMobile ? 3.2 : 2.6,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final log = state.logs[index];
                          return DailyLogCard(
                            log: log,
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => DailyLogFormScreen(
                                        repository: widget.repository,
                                        foremanId: widget.foremanId,
                                        siteId: widget.siteId,
                                        existingLog: log,
                                      ),
                                    ),
                                  )
                                  .then((_) {
                                    if (context.mounted) {
                                      context.read<DailyLogBloc>().add(
                                        LoadDailyLogsListEvent(
                                          siteId: widget.siteId,
                                          foremanId: widget.foremanId,
                                          statusFilter: _selectedStatusFilter,
                                        ),
                                      );
                                    }
                                  });
                            },
                            onDelete: () {
                              context.read<DailyLogBloc>().add(
                                DeleteDailyLogEvent(log.id),
                              );
                            },
                          );
                        }, childCount: state.logs.length),
                      ),
                    ),
                ],
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required ColorScheme colorScheme,
  }) {
    return AnimatedContainer(
      duration: _kTransitionDuration,
      curve: Curves.easeOutQuart,
      child: FilterChip(
        label: Semantics(
          label: 'Filter: $label${selected ? ', aktif' : ''}',
          excludeSemantics: true,
          child: Text(label),
        ),
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        selectedColor: _kAccent.withValues(alpha: 0.12),
        checkmarkColor: _kAccent,
        side: BorderSide(
          color: selected
              ? _kAccent
              : colorScheme.outline.withValues(alpha: 0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          // Use onSurface for contrast — accent border/background conveys state.
          color: selected
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
