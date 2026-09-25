// Daily Log list — role-aware tabbed review workflow (STEP-55.6, spec §4.5
// items 1–4, 9 / FC-54.6-001..004, 008).
//
// Tabs express workflow status only: `Semua`, `Draft`, `Perlu Disetujui`,
// `Disetujui`, each with a count. A foreman defaults to `Draft` and sees
// their own logs; a supervisor defaults to `Perlu Disetujui` and sees the
// site-wide submitted queue. Date/zone/foreman filters live in the shared
// popover; the date opens the in-context calendar dialog. Status changes
// happen ONLY through the explicit supervisor `Setujui Log` action — no
// drag/drop, no inline mutation. The report is the contextual Daily Log
// dialog seeded by the active filters; no FAB, no route push.

// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:mine_flow/core/presentation/widgets/adaptive_card_sliver_grid.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:mine_flow/core/presentation/widgets/zone_filter_dropdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/daily_log_card.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/core/navigation/route_observer.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/main.dart';

const double _kPagePadding = 24;

/// --- Responsive breakpoints --- ///
const double _kBreakTablet = 900;

/// Screen presenting the Daily Log review workflow (STEP-55.6).
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
    // Role defaults (spec §4.5 item 1): foreman → Draft (own logs, already
    // scoped by `foremanId`); supervisor → Perlu Disetujui (site-wide).
    final user = authCubit?.state.user;
    final isSupervisor = user?.isSupervisor ?? false;
    final defaultTab = isSupervisor
        ? DailyLogReviewTab.needsApproval
        : DailyLogReviewTab.draft;

    return BlocProvider(
      create: (context) => DailyLogBloc(repository: repository)
        ..add(
          LoadDailyLogsListEvent(
            siteId: siteId,
            foremanId: foremanId,
            tab: defaultTab,
          ),
        ),
      child: DailyLogListView(
        repository: repository,
        zoneRepository: zoneRepository,
        foremanId: foremanId,
        siteId: siteId,
        isSupervisor: isSupervisor,
        supervisorId: isSupervisor ? user?.id : null,
      ),
    );
  }
}

class DailyLogListView extends StatefulWidget {
  final DailyLogRepository repository;
  final ZoneRepository zoneRepository;
  final String? foremanId;
  final String siteId;
  final bool isSupervisor;
  final String? supervisorId;

  const DailyLogListView({
    super.key,
    required this.repository,
    required this.zoneRepository,
    required this.foremanId,
    required this.siteId,
    required this.isSupervisor,
    required this.supervisorId,
  });

  @override
  State<DailyLogListView> createState() => _DailyLogListViewState();
}

class _DailyLogListViewState extends State<DailyLogListView> with RouteAware {
  final ScrollController _scrollController = ScrollController();

  /// Foreman display names resolved from the roster (spec §4.5 item 3:
  /// real foreman identity — a UUID is never shown when a name exists).
  Map<String, String> _foremanNames = const {};

  @override
  void initState() {
    super.initState();
    _resolveForemanNames();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // STEP-55.11 E2E residual: the route-hosted form sheet stays mounted
    // beneath this list. Without a resume hook the list never sees the
    // log the foreman just created and submitted (the BLoC loaded once at
    // creation, before the write landed). didPopNext fires when the sheet
    // pops back to this route — matching the STEP-55.5 attendance pattern.
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  void _refreshListAndWidenToAll() {
    final bloc = context.read<DailyLogBloc>();
    final blocState = bloc.state;
    final targetTab =
        (!widget.isSupervisor &&
            (blocState is! DailyLogsLoaded ||
                blocState.activeTab == DailyLogReviewTab.draft))
        ? DailyLogReviewTab.all
        : (blocState is DailyLogsLoaded
              ? blocState.activeTab
              : DailyLogReviewTab.all);

    bloc.add(
      LoadDailyLogsListEvent(
        siteId: blocState is DailyLogsLoaded ? blocState.siteId : widget.siteId,
        foremanId:
            widget.foremanId ??
            (blocState is DailyLogsLoaded ? blocState.foremanFilter : null),
        tab: targetTab,
      ),
    );
  }

  @override
  void didPopNext() {
    _refreshListAndWidenToAll();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _resolveForemanNames() async {
    try {
      final roster = await appServices!.authRepository.getSiteRoster(
        siteId: widget.siteId,
      );
      if (mounted) {
        setState(() {
          _foremanNames = {for (final user in roster) user.id: user.name};
        });
      }
    } catch (_) {
      // Name resolution is best-effort; cards fall back to the raw id.
    }
  }

  Future<void> _openCreateForm() async {
    await context.pushNamed(
      'daily-log-form',
      queryParameters: {
        if (widget.foremanId != null) 'foremanId': widget.foremanId!,
      },
    );
    if (mounted) {
      _refreshListAndWidenToAll();
    }
  }

  Future<void> _openContextualReport(DailyLogsLoaded state) async {
    // Spec §4.5 item 9: the report is the contextual Daily Log dialog
    // seeded by the active date/zone context; the list stays mounted.
    final day = state.selectedDate ?? DateTime.now();
    await showAppContextualReportDialog(
      context: context,
      reportType: ReportType.dailyLog,
      sourceTitle: 'Log Harian',
      initialDateRange: DateTimeRange(start: day, end: day),
      initialZoneId: state.zoneFilter,
      reportingRepository: appServices!.reportingRepository,
      zoneRepository: appServices!.zoneRepository,
    );
  }

  /// Supervisor approval (spec §4.5 item 4): confirmation names the
  /// record/date/foreman, then dispatches the existing approval use case
  /// with the authenticated supervisor ID.
  Future<void> _approveLog(DailyLog log) async {
    final foremanName = _foremanNames[log.foremanId] ?? log.foremanId;
    // Spec §4.5 item 9 / FC-54.6-009: no unbounded Material form control may
    // remain. Migrated from Material AlertDialog to ForUI FDialog, preserving
    // the named-record confirmation copy, barrierDismissible: false, and the
    // confirm -> ApproveDailyLogEvent wiring below.
    final confirmed = await showFDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext, style, animation) => FDialog(
        builder: (dialogBuilderContext, dialogStyle) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FAlert(
              title: const Text('Setujui Log Harian'),
              subtitle: Text(
                'Setujui log '
                '${DateFormat('dd MMMM yyyy', 'id_ID').format(log.logDate)} '
                'dari $foremanName? Status akan berubah menjadi Disetujui dan '
                'tidak dapat dibatalkan.',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Setujui'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final supervisorId = widget.supervisorId ?? currentUserId();
    if (supervisorId == null) return;
    context.read<DailyLogBloc>().add(
      ApproveDailyLogEvent(logId: log.id, approvedBy: supervisorId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return BlocConsumer<DailyLogBloc, DailyLogState>(
      listener: (context, state) {
        if (state is DailyLogError) {
          showFToast(
            context: context,
            variant: FToastVariant.destructive,
            title: Text(state.message),
            icon: const Icon(LucideIcons.alertCircle),
            duration: const Duration(seconds: 4),
          );
        } else if (state is DailyLogsLoaded && state.approvingLogId == null) {
          // Approval completed and counts refreshed — success feedback via
          // the toast keeps the list (tab/scroll) intact.
        }
      },
      builder: (context, state) {
        return FScaffold(
          header: MediaQuery.of(context).size.width > 800
              ? null
              : FHeader(
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
                ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: _buildBody(context, state, theme),
                ),
              ),
              // Create action (FButton, not a FAB — spec §4.5 item 9).
              // Foremen create logs; supervisors review, so the create
              // action is hidden for supervisors.
              if (!widget.isSupervisor)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FButton(
                    key: const Key('create_new_daily_log_fab'),
                    variant: FButtonVariant.primary,
                    onPress: _openCreateForm,
                    prefix: const Icon(LucideIcons.plus),
                    child: const Text('Log Baru'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    DailyLogState state,
    FThemeData theme,
  ) {
    if (state is DailyLogLoading || state is DailyLogInitial) {
      return const Center(child: FCircularProgress(size: .lg));
    }

    if (state is DailyLogsLoaded) {
      final isWide = MediaQuery.sizeOf(context).width >= _kBreakTablet;

      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : _kPagePadding,
                _kPagePadding,
                isWide ? 32 : _kPagePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabStrip(context, state, theme),
                  const SizedBox(height: 16),
                  _buildFilterRow(context, state, theme),
                  const SizedBox(height: 12),
                  Text(
                    '${state.logs.length} log harian',
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground.withValues(
                        alpha: 0.7,
                      ),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.logs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Semantics(
                label: 'Belum ada data log harian',
                child: Center(
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
                          LucideIcons.clipboardList,
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
                    ],
                  ),
                ),
              ),
            )
          else
            AdaptiveCardSliverGrid(
              padding: EdgeInsets.only(
                left: isWide ? 32 : _kPagePadding,
                right: isWide ? 32 : _kPagePadding,
                bottom: 96,
              ),
              crossAxisCount: isWide ? 2 : 1,
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final log = state.logs[index];
                return DailyLogCard(
                  log: log,
                  foremanName: _foremanNames[log.foremanId],
                  onTap: () => context.pushNamed(
                    'daily-log-record-form',
                    pathParameters: {'id': log.id},
                  ),
                  // Spec §4.5 item 4: supervisor-only, submitted-only.
                  onApprove:
                      widget.isSupervisor && log.status == LogStatus.submitted
                      ? () => _approveLog(log)
                      : null,
                  isApproving: state.approvingLogId == log.id,
                  onDelete: log.status == LogStatus.draft
                      ? () async {
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
                        }
                      : null,
                );
              },
            ),
        ],
      );
    }

    if (state is DailyLogError) {
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
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FButton(
                onPress: () {
                  context.read<DailyLogBloc>().add(
                    LoadDailyLogsListEvent(
                      siteId: widget.siteId,
                      foremanId: widget.foremanId,
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

    return const SizedBox.shrink();
  }

  /// Workflow tab strip (spec §4.5 item 1): `Semua`, `Draft`,
  /// `Perlu Disetujui`, `Disetujui` with counts. FTabs renders an
  /// accessible control that does not overflow horizontally on narrow
  /// screens (scrollable).
  Widget _buildTabStrip(
    BuildContext context,
    DailyLogsLoaded state,
    FThemeData theme,
  ) {
    return Semantics(
      label: 'Filter status alur kerja log',
      container: true,
      child: FTabs(
        control: FTabControl.lifted(
          index: DailyLogReviewTab.values.indexOf(state.activeTab),
          onChange: (index) => context.read<DailyLogBloc>().add(
            SelectDailyLogTabEvent(DailyLogReviewTab.values[index]),
          ),
        ),
        scrollable: true,
        children: [
          for (final tab in DailyLogReviewTab.values)
            FTabEntry.entry(
              label: Text(
                '${_tabLabel(tab)} (${state.countFor(tab)})',
                key: ValueKey('daily_log_tab_${tab.name}'),
              ),
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  String _tabLabel(DailyLogReviewTab tab) => switch (tab) {
    DailyLogReviewTab.all => 'Semua',
    DailyLogReviewTab.draft => 'Draft',
    DailyLogReviewTab.needsApproval => 'Perlu Disetujui',
    DailyLogReviewTab.approved => 'Disetujui',
  };

  /// Data filters (spec §4.5 item 2): date + zone + foreman in the shared
  /// popover; the tab is NOT a filter pill row and stays separate.
  Widget _buildFilterRow(
    BuildContext context,
    DailyLogsLoaded state,
    FThemeData theme,
  ) {
    final hasFilters =
        state.selectedDate != null ||
        state.zoneFilter != null ||
        state.foremanFilter != null;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Filter data log harian',
            button: true,
            child: GestureDetector(
              onTap: () => _showFilterPopover(context, state),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasFilters
                        ? theme.colors.primary
                        : theme.colors.border.withValues(alpha: 0.3),
                    width: hasFilters ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.filter, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _filterSummary(state),
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.body.sm.copyWith(
                          fontWeight: hasFilters
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: hasFilters
                              ? theme.colors.primary
                              : theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => _openContextualReport(state),
          prefix: const Icon(LucideIcons.fileText),
          child: const Text('Laporan'),
        ),
      ],
    );
  }

  String _filterSummary(DailyLogsLoaded state) {
    final parts = <String>[];
    if (state.selectedDate != null) {
      parts.add(DateFormat('d MMM yyyy', 'id_ID').format(state.selectedDate!));
    }
    if (state.zoneFilter != null) {
      parts.add('Zona: ${_zoneName(state.zoneFilter!)}');
    }
    if (state.foremanFilter != null) {
      final name = _foremanNames[state.foremanFilter!];
      parts.add('Foreman: ${name ?? state.foremanFilter}');
    }
    return parts.isEmpty ? 'Filter data' : 'Filter: ${parts.join(' · ')}';
  }

  String _zoneName(String zoneId) => zoneId;

  Future<void> _showFilterPopover(
    BuildContext context,
    DailyLogsLoaded state,
  ) async {
    final bloc = context.read<DailyLogBloc>();
    DateTime? draftDate = state.selectedDate;
    String? draftZone = state.zoneFilter;
    String? draftForeman = state.foremanFilter;

    await showAppFilterPopover<void>(
      context: context,
      builder: (popoverContext) => StatefulBuilder(
        builder: (popoverContext, setPopoverState) =>
            // The popover opens on a fresh dialog route with no bloc scope,
            // so the zone dropdown's ZoneCubit is provided here.
            BlocProvider<ZoneCubit>(
              create: (_) =>
                  ZoneCubit(repository: widget.zoneRepository)..loadZones(),
              child: AppFilterPopover(
                onApply: () {
                  bloc.add(
                    ApplyDailyLogFiltersEvent(
                      date: draftDate,
                      zoneId: draftZone,
                      foremanId: draftForeman,
                    ),
                  );
                  Navigator.of(popoverContext).pop();
                },
                onReset: () {
                  bloc.add(const ApplyDailyLogFiltersEvent());
                  Navigator.of(popoverContext).pop();
                },
                onCancel: () => Navigator.of(popoverContext).pop(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date via in-context calendar dialog (spec §4.5 item 2).
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: () async {
                        final picked = await AppCalendarDialog.showSingle(
                          popoverContext,
                          initialDate: draftDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setPopoverState(() => draftDate = picked);
                        }
                      },
                      prefix: const Icon(LucideIcons.calendarDays),
                      child: Text(
                        draftDate != null
                            ? DateFormat(
                                'EEEE, d MMMM yyyy',
                                'id_ID',
                              ).format(draftDate!)
                            : 'Semua tanggal',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ZoneFilterDropdown(
                      selectedZoneId: draftZone,
                      onZoneSelected: (zoneId) =>
                          setPopoverState(() => draftZone = zoneId),
                    ),
                    const SizedBox(height: 12),
                    if (widget.isSupervisor && _foremanNames.isNotEmpty)
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: draftForeman,
                          hint: const Text('Semua foreman'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua foreman'),
                            ),
                            for (final entry in _foremanNames.entries)
                              DropdownMenuItem<String?>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                          onChanged: (value) =>
                              setPopoverState(() => draftForeman = value),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
