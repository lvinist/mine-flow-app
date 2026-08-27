import 'package:flutter/material.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_form_screen.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/daily_log_card.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';

const double _kPagePadding = 24;

// --- Responsive breakpoints ---
const double _kBreakMobile = 600;
const double _kBreakTablet = 900;

/// Screen listing daily log history with status filtering and option to create new log entries.
///
/// Migrated to ForUI in Substep 30.3: Material colors/tokens replaced with
/// FTheme semantic tokens, FilterChips updated with ForUI color scheme.
class DailyLogListScreen extends StatelessWidget {
  final DailyLogRepository repository;
  final ZoneRepository zoneRepository;
  final String? foremanId;
  final String siteId;

  const DailyLogListScreen({
    super.key,
    required this.repository,
    required this.zoneRepository,
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
        zoneRepository: zoneRepository,
        foremanId: foremanId,
        siteId: siteId,
      ),
    );
  }
}

class DailyLogListView extends StatefulWidget {
  final DailyLogRepository repository;
  final ZoneRepository zoneRepository;
  final String? foremanId;
  final String siteId;

  const DailyLogListView({
    super.key,
    required this.repository,
    required this.zoneRepository,
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
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: MediaQuery.of(context).size.width > 800
          ? null
          : AppBar(
              title: Semantics(
                header: true,
                child: Text(
                  'Riwayat Log Harian',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w700,
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
        switchOutCurve: Curves.easeOutQuart,
        child: _buildBody(context, theme),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Buat Laporan Log Harian',
            button: true,
            child: FloatingActionButton(
              heroTag: 'report_daily_log_btn',
              backgroundColor: theme.colors.secondary,
              foregroundColor: theme.colors.secondaryForeground,
              elevation: 2,
              onPressed: () => context.pushNamed(
                'report-config',
                extra: ReportType
                    .attendance, // original logic used attendance, keeping it
              ),
              child: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            label: 'Buat log baru',
            button: true,
            child: FloatingActionButton.extended(
              key: const Key('create_new_daily_log_fab'),
              heroTag: 'add_daily_log_btn',
              icon: const Icon(Icons.add),
              label: const Text('Log Baru'),
              backgroundColor: theme.colors.primary,
              foregroundColor: theme.colors.primaryForeground,
              elevation: 2,
              highlightElevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => DailyLogFormScreen(
                          repository: widget.repository,
                          zoneRepository: widget.zoneRepository,
                          // CF-007: attribute the log to the signed-in user.
                          foremanId: currentUserId() ?? '',
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
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, FThemeData theme) {
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
                      color: theme.colors.destructive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colors.destructive,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: theme.typography.body.md.copyWith(
                      color: theme.colors.mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
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
                                theme: theme,
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
                                theme: theme,
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
                                theme: theme,
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
                                theme: theme,
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
                          style: theme.typography.body.xs.copyWith(
                            color: theme.colors.mutedForeground.withValues(
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
                                color: theme.colors.muted,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                size: 48,
                                color: theme.colors.mutedForeground.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Belum ada data log harian.',
                              style: theme.typography.body.md.copyWith(
                                color: theme.colors.mutedForeground,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tekan "Log Baru" untuk membuat entri pertama.',
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground.withValues(
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
                                        zoneRepository: widget.zoneRepository,
                                        // CF-007: attribute to signed-in user.
                                        foremanId: currentUserId() ?? '',
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
                            onDelete: () async {
                              final proceed = await confirmDestructiveAction(
                                context,
                                message:
                                    'Hapus log harian ini? Tindakan tidak dapat dibatalkan.',
                              );
                              if (proceed && context.mounted) {
                                context.read<DailyLogBloc>().add(
                                  DeleteDailyLogEvent(log.id),
                                );
                              }
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
    required FThemeData theme,
  }) {
    return FilterChip(
      label: Semantics(
        label: 'Filter: $label${selected ? ', aktif' : ''}',
        excludeSemantics: true,
        child: Text(label),
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: theme.colors.primary.withValues(alpha: 0.12),
      checkmarkColor: theme.colors.primary,
      side: BorderSide(
        color: selected ? theme.colors.primary : theme.colors.border,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: theme.typography.body.sm.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: selected
            ? theme.colors.foreground
            : theme.colors.mutedForeground,
        letterSpacing: 0.2,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
