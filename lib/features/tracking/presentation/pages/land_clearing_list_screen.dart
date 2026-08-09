import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_entry_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/clearing_summary_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/land_clearing_card.dart';

const double _kPagePadding = 24;
const double _kBreakMobile = 600;
const double _kBreakTablet = 900;

/// Screen listing land clearing area records with aggregated summary
/// and filter controls for site/zone/date range.
class LandClearingSummaryScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;

  const LandClearingSummaryScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LandClearingBloc(repository: repository)
            ..add(LoadLandClearingRecordsEvent(siteId: siteId)),
      child: _LandClearingListView(
        repository: repository,
        siteId: siteId,
        foremanId: foremanId,
      ),
    );
  }
}

class _LandClearingListView extends StatefulWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;

  const _LandClearingListView({
    required this.repository,
    required this.siteId,
    required this.foremanId,
  });

  @override
  State<_LandClearingListView> createState() => _LandClearingListViewState();
}

class _LandClearingListViewState extends State<_LandClearingListView> {
  String? _selectedZoneId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop 
          ? null 
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: FHeader(
                title: Semantics(
                  header: true,
                  child: Text(
                    'Land Clearing',
                    style: theme.typography.display.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
            label: 'Buat Laporan Land Clearing',
            button: true,
            child: FloatingActionButton(
              heroTag: 'report_land_clearing_btn',
              backgroundColor: theme.colors.secondary,
              foregroundColor: theme.colors.secondaryForeground,
              elevation: 2,
              onPressed: () => context.pushNamed(
                'report-config',
                extra: ReportType.cutFill,
              ),
              child: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'add_land_clearing_btn',
            backgroundColor: theme.colors.primary,
            foregroundColor: theme.colors.primaryForeground,
            elevation: 2,
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => LandClearingEntryScreen(
                        repository: widget.repository,
                        siteId: widget.siteId,
                        foremanId: widget.foremanId,
                      ),
                    ),
                  )
                  .then((_) {
                    if (context.mounted) {
                      context.read<LandClearingBloc>().add(
                        LoadLandClearingRecordsEvent(
                          siteId: widget.siteId,
                          zoneId: _selectedZoneId,
                          startDate: _startDate,
                          endDate: _endDate,
                        ),
                      );
                    }
                  });
            },
            icon: const Icon(Icons.add),
            label: const Text('Clearing Baru'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, FThemeData theme) {
    return BlocBuilder<LandClearingBloc, LandClearingState>(
      builder: (context, state) {
        if (state is LandClearingLoading) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        if (state is LandClearingError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(_kPagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colors.destructive,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: theme.typography.body.md.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FButton(
                    onPress: () {
                      context.read<LandClearingBloc>().add(
                        LoadLandClearingRecordsEvent(
                          siteId: widget.siteId,
                          zoneId: _selectedZoneId,
                          startDate: _startDate,
                          endDate: _endDate,
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

        if (state is LandClearingRecordsLoaded) {
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
                                  _selectedZoneId == null && _startDate == null,
                              onSelected: () {
                                setState(() {
                                  _selectedZoneId = null;
                                  _startDate = null;
                                  _endDate = null;
                                });
                                context.read<LandClearingBloc>().add(
                                  LoadLandClearingRecordsEvent(
                                    siteId: widget.siteId,
                                  ),
                                );
                              },
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: _selectedZoneId ?? 'Zona',
                              selected: _selectedZoneId != null,
                              onSelected: () {
                                setState(() {
                                  _selectedZoneId = _selectedZoneId == null
                                      ? 'Zona A'
                                      : null;
                                });
                                context.read<LandClearingBloc>().add(
                                  LoadLandClearingRecordsEvent(
                                    siteId: widget.siteId,
                                    zoneId: _selectedZoneId,
                                    startDate: _startDate,
                                    endDate: _endDate,
                                  ),
                                );
                              },
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: _startDate != null && _endDate != null
                                  ? 'Filter Tanggal'
                                  : 'Pilih Tanggal',
                              selected: _startDate != null,
                              onSelected: () async {
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
                                  context.read<LandClearingBloc>().add(
                                    LoadLandClearingRecordsEvent(
                                      siteId: widget.siteId,
                                      zoneId: _selectedZoneId,
                                      startDate: _startDate,
                                      endDate: _endDate,
                                    ),
                                  );
                                }
                              },
                              theme: theme,
                            ),
                          ],
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
                      child: ClearingSummaryCard(
                        totalPlanArea: state.totalPlanArea,
                        totalActualArea: state.totalActualArea,
                      ),
                    ),
                  ),

                  // --- Record count ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        top: 16,
                      ),
                      child: Text(
                        '${state.records.length} pencatatan',
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // --- Record cards or Empty state ---
                  if (state.records.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forest,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Belum ada data land clearing.',
                            style: theme.typography.body.md.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tekan "Clearing Baru" untuk memulai.',
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
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
                          return LandClearingCard(
                            record: record,
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => LandClearingEntryScreen(
                                        repository: widget.repository,
                                        siteId: widget.siteId,
                                        foremanId: widget.foremanId,
                                        existingRecord: record,
                                      ),
                                    ),
                                  )
                                  .then((_) {
                                    if (context.mounted) {
                                      context.read<LandClearingBloc>().add(
                                        LoadLandClearingRecordsEvent(
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
                              context.read<LandClearingBloc>().add(
                                DeleteLandClearingRecordEvent(record.id),
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
    required VoidCallback onSelected,
    required FThemeData theme,
  }) {
    return FButton(onPress: onSelected, child: Text(label));
  }
}
