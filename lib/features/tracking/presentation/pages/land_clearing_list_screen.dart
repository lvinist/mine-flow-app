// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/core/presentation/widgets/adaptive_card_sliver_grid.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:mine_flow/core/presentation/widgets/zone_filter_dropdown.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/clearing_summary_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/land_clearing_card.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';
import 'package:mine_flow/main.dart';

const double _kPagePadding = 24;
const double _kBreakTablet = 900;

/// Screen listing land clearing area records with aggregated summary
/// and filter controls for site/zone/date range.
class LandClearingSummaryScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;
  final ZoneRepository? zoneRepository;
  final ReportingRepository? reportingRepository;

  const LandClearingSummaryScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
    this.zoneRepository,
    this.reportingRepository,
  });

  @override
  Widget build(BuildContext context) {
    final zRepo = zoneRepository ?? appServices?.zoneRepository;
    final rRepo = reportingRepository ?? appServices?.reportingRepository;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              LandClearingBloc(repository: repository)
                ..add(LoadLandClearingRecordsEvent(siteId: siteId)),
        ),
        if (zRepo != null)
          BlocProvider<ZoneCubit>(
            create: (_) => ZoneCubit(repository: zRepo)..loadZones(),
          ),
      ],
      child: _LandClearingListView(
        repository: repository,
        siteId: siteId,
        foremanId: foremanId,
        zoneRepository: zRepo,
        reportingRepository: rRepo,
      ),
    );
  }
}

class _LandClearingListView extends StatefulWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;
  final ZoneRepository? zoneRepository;
  final ReportingRepository? reportingRepository;

  const _LandClearingListView({
    required this.repository,
    required this.siteId,
    required this.foremanId,
    this.zoneRepository,
    this.reportingRepository,
  });

  @override
  State<_LandClearingListView> createState() => _LandClearingListViewState();
}

class _LandClearingListViewState extends State<_LandClearingListView> {
  String? _selectedZoneId;
  DateTime? _startDate;
  DateTime? _endDate;

  void _reloadList() {
    context.read<LandClearingBloc>().add(
      LoadLandClearingRecordsEvent(
        siteId: widget.siteId,
        zoneId: _selectedZoneId,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  Map<String, String> _activeQueryParams() {
    final params = <String, String>{};
    if (_startDate != null) {
      params['from'] = _startDate!.toIso8601String().substring(0, 10);
    }
    if (_endDate != null) {
      params['to'] = _endDate!.toIso8601String().substring(0, 10);
    }
    if (_selectedZoneId != null && _selectedZoneId!.isNotEmpty) {
      params['zoneId'] = _selectedZoneId!;
    }
    return params;
  }

  void _openCreateForm(BuildContext context) {
    final queryParams = _activeQueryParams();
    context
        .pushNamed('land-clearing-create', queryParameters: queryParams)
        .then((_) {
          if (mounted) {
            _reloadList();
          }
        });
  }

  void _openInspector(BuildContext context, LandClearingRecord record) {
    final queryParams = _activeQueryParams();
    context
        .pushNamed(
          'land-clearing-detail',
          pathParameters: {'id': record.id},
          queryParameters: queryParams,
          extra: record,
        )
        .then((_) {
          if (mounted) {
            _reloadList();
          }
        });
  }

  void _openReportDialog(BuildContext context) {
    final zRepo = widget.zoneRepository ?? appServices?.zoneRepository;
    final rRepo =
        widget.reportingRepository ?? appServices?.reportingRepository;
    if (zRepo == null || rRepo == null) return;

    DateTimeRange? initialRange;
    if (_startDate != null && _endDate != null) {
      initialRange = DateTimeRange(start: _startDate!, end: _endDate!);
    }

    showAppContextualReportDialog(
      context: context,
      reportType: ReportType.landClearing,
      sourceTitle: 'Land Clearing',
      initialDateRange: initialRange,
      initialZoneId: _selectedZoneId,
      reportingRepository: rRepo,
      zoneRepository: zRepo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return FScaffold(
      header: isDesktop
          ? null
          : FHeader(
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
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeOutQuart,
                child: _buildBody(context, theme),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Buat Laporan Land Clearing',
                    button: true,
                    child: SizedBox(
                      height: 48,
                      child: FButton(
                        variant: FButtonVariant.outline,
                        onPress: () => _openReportDialog(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.fileText, size: 18),
                            SizedBox(width: 8),
                            Text('Laporan'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: 'Clearing Baru',
                    button: true,
                    child: SizedBox(
                      height: 48,
                      child: FButton(
                        variant: FButtonVariant.primary,
                        onPress: () => _openCreateForm(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus, size: 18),
                            SizedBox(width: 8),
                            Text('Clearing Baru'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, FThemeData theme) {
    return BlocBuilder<LandClearingBloc, LandClearingState>(
      builder: (context, state) {
        if (state is LandClearingLoading) {
          return const Center(child: FCircularProgress(size: .lg));
        }

        if (state is LandClearingError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(_kPagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertCircle,
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
                    onPress: _reloadList,
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
                                _reloadList();
                              },
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            ZoneFilterDropdown(
                              selectedZoneId: _selectedZoneId,
                              onZoneSelected: (zoneId) {
                                setState(() => _selectedZoneId = zoneId);
                                _reloadList();
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: _startDate != null && _endDate != null
                                  ? 'Filter Tanggal'
                                  : 'Pilih Tanggal',
                              selected: _startDate != null,
                              onSelected: () async {
                                final picked =
                                    await AppCalendarDialog.showRange(
                                      context,
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
                                  _reloadList();
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
                            LucideIcons.trees,
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
                    AdaptiveCardSliverGrid(
                      padding: contentPadding,
                      crossAxisCount: crossAxisCount,
                      itemCount: state.records.length,
                      itemBuilder: (context, index) {
                        final record = state.records[index];
                        return LandClearingCard(
                          record: record,
                          onTap: () => _openInspector(context, record),
                          onDelete: () async {
                            final proceed = await confirmDestructiveAction(
                              context,
                              message:
                                  'Hapus data land clearing ini? Tindakan tidak dapat dibatalkan.',
                            );
                            if (proceed && context.mounted) {
                              context.read<LandClearingBloc>().add(
                                DeleteLandClearingRecordEvent(record.id),
                              );
                            }
                          },
                        );
                      },
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
    return FButton(
      variant: selected ? FButtonVariant.primary : FButtonVariant.outline,
      onPress: onSelected,
      child: Text(label),
    );
  }
}
