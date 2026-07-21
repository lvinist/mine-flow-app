import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_state.dart';
import 'package:mine_flow/features/tracking/presentation/pages/cut_fill_form_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/cut_fill_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/volume_summary_card.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kPagePadding = 24;

/// Micro-interaction duration for state transitions.
const Duration _kTransitionDuration = Duration(milliseconds: 200);

// --- Responsive breakpoints (DESIGN.md §28) ---
const double _kBreakMobile = 600;
const double _kBreakTablet = 900;

/// Screen listing cut/fill volume measurement records with aggregated summary
/// and filter controls for site/zone/date range.
class CutFillListScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;

  const CutFillListScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CutFillBloc(repository: repository)
            ..add(LoadCutFillRecordsEvent(siteId: siteId)),
      child: CutFillListView(
        repository: repository,
        siteId: siteId,
        foremanId: foremanId,
      ),
    );
  }
}

class CutFillListView extends StatefulWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;

  const CutFillListView({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
  });

  @override
  State<CutFillListView> createState() => _CutFillListViewState();
}

class _CutFillListViewState extends State<CutFillListView> {
  String? _selectedZoneId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              'Volume Cut / Fill',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
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
        child: _buildBody(context, colorScheme, theme),
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final bool isExtended = constraints.maxWidth >= _kBreakMobile;
          return Semantics(
            label: 'Buat pengukuran baru',
            hint: 'Membuka formulir entri volume cut/fill',
            button: true,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: _kTransitionDuration,
              curve: Curves.easeOutQuart,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: isExtended
                  ? FloatingActionButton.extended(
                      key: const Key('create_new_cut_fill_fab'),
                      icon: const Icon(Icons.add),
                      label: const Text('Pengukuran Baru'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 2,
                      highlightElevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => CutFillFormScreen(
                                  repository: widget.repository,
                                  siteId: widget.siteId,
                                  foremanId: widget.foremanId,
                                ),
                              ),
                            )
                            .then((_) {
                              if (context.mounted) {
                                context.read<CutFillBloc>().add(
                                  LoadCutFillRecordsEvent(
                                    siteId: widget.siteId,
                                    zoneId: _selectedZoneId,
                                    startDate: _startDate,
                                    endDate: _endDate,
                                  ),
                                );
                              }
                            });
                      },
                    )
                  : FloatingActionButton(
                      key: const Key('create_new_cut_fill_fab'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 2,
                      highlightElevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => CutFillFormScreen(
                                  repository: widget.repository,
                                  siteId: widget.siteId,
                                  foremanId: widget.foremanId,
                                ),
                              ),
                            )
                            .then((_) {
                              if (context.mounted) {
                                context.read<CutFillBloc>().add(
                                  LoadCutFillRecordsEvent(
                                    siteId: widget.siteId,
                                    zoneId: _selectedZoneId,
                                    startDate: _startDate,
                                    endDate: _endDate,
                                  ),
                                );
                              }
                            });
                      },
                      child: const Icon(Icons.add),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return BlocBuilder<CutFillBloc, CutFillState>(
      builder: (context, state) {
        if (state is CutFillLoading) {
          return Semantics(
            label: 'Memuat data volume cut/fill',
            liveRegion: true,
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        if (state is CutFillError) {
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
                        context.read<CutFillBloc>().add(
                          LoadCutFillRecordsEvent(
                            siteId: widget.siteId,
                            zoneId: _selectedZoneId,
                            startDate: _startDate,
                            endDate: _endDate,
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

        if (state is CutFillRecordsLoaded) {
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
                      label: 'Filter zona dan tanggal',
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
                                label: 'Semua Zona',
                                selected:
                                    _selectedZoneId == null &&
                                    _startDate == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedZoneId = null;
                                    _startDate = null;
                                    _endDate = null;
                                  });
                                  context.read<CutFillBloc>().add(
                                    LoadCutFillRecordsEvent(
                                      siteId: widget.siteId,
                                    ),
                                  );
                                },
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: _selectedZoneId ?? 'Zona',
                                selected: _selectedZoneId != null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedZoneId = selected
                                        ? 'Zona A'
                                        : null;
                                  });
                                  context.read<CutFillBloc>().add(
                                    LoadCutFillRecordsEvent(
                                      siteId: widget.siteId,
                                      zoneId: _selectedZoneId,
                                      startDate: _startDate,
                                      endDate: _endDate,
                                    ),
                                  );
                                },
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: _startDate != null && _endDate != null
                                    ? 'Filter Tanggal'
                                    : 'Pilih Tanggal',
                                selected: _startDate != null,
                                onSelected: (selected) async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                    initialDateRange:
                                        _startDate != null && _endDate != null
                                        ? DateTimeRange(
                                            start: _startDate!,
                                            end: _endDate!,
                                          )
                                        : null,
                                  );
                                  if (picked != null && context.mounted) {
                                    setState(() {
                                      _startDate = picked.start;
                                      _endDate = picked.end;
                                    });
                                    context.read<CutFillBloc>().add(
                                      LoadCutFillRecordsEvent(
                                        siteId: widget.siteId,
                                        zoneId: _selectedZoneId,
                                        startDate: _startDate,
                                        endDate: _endDate,
                                      ),
                                    );
                                  }
                                },
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 8),
                              // Clear filter button
                              if (_selectedZoneId != null || _startDate != null)
                                _buildFilterChip(
                                  label: 'Hapus Filter',
                                  selected: false,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedZoneId = null;
                                      _startDate = null;
                                      _endDate = null;
                                    });
                                    context.read<CutFillBloc>().add(
                                      LoadCutFillRecordsEvent(
                                        siteId: widget.siteId,
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

                  // --- Summary card ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        0,
                      ),
                      child: VolumeSummaryCard(
                        totalCutM3: state.totalCutM3,
                        totalFillM3: state.totalFillM3,
                        totalNetM3: state.totalNetM3,
                      ),
                    ),
                  ),

                  // --- Record count ---
                  SliverToBoxAdapter(
                    child: Semantics(
                      label: '${state.records.length} pengukuran',
                      sortKey: const OrdinalSortKey(1),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: 16,
                        ),
                        child: Text(
                          '${state.records.length} pengukuran',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Record cards or Empty state ---
                  if (state.records.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Semantics(
                        label: 'Belum ada data volume cut/fill',
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
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.auto_graph_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Belum ada data volume cut/fill.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tekan "Pengukuran Baru" untuk memulai.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.85,
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
                          final record = state.records[index];
                          return CutFillCard(
                            record: record,
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => CutFillFormScreen(
                                        repository: widget.repository,
                                        siteId: widget.siteId,
                                        foremanId: widget.foremanId,
                                        existingRecord: record,
                                      ),
                                    ),
                                  )
                                  .then((_) {
                                    if (context.mounted) {
                                      context.read<CutFillBloc>().add(
                                        LoadCutFillRecordsEvent(
                                          siteId: widget.siteId,
                                          zoneId: _selectedZoneId,
                                          startDate: _startDate,
                                          endDate: _endDate,
                                        ),
                                      );
                                    }
                                  });
                            },
                            onDelete: () {
                              context.read<CutFillBloc>().add(
                                DeleteCutFillRecordEvent(record.id),
                              );
                            },
                          );
                        }, childCount: state.records.length),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: FilterChip(
        label: Semantics(
          label: 'Filter: $label${selected ? ', aktif' : ''}',
          excludeSemantics: true,
          child: Text(label),
        ),
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        selectedColor: colorScheme.primary.withValues(alpha: 0.12),
        checkmarkColor: colorScheme.primary,
        side: BorderSide(
          color: selected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        pressElevation: 1,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
