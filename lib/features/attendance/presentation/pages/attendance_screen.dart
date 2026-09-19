// Attendance list screen — crew attendance history in ForUI aesthetic.
//
// STEP-55.5: rebuilt per master spec §4.4 items 7, 9–10. The list keeps its
// search/status/date filters and scroll position across a form round-trip
// (push-based sheet navigation keeps this screen mounted beneath), exposes
// filters through the shared popover-first pattern, and seeds the contextual
// attendance report with the selected date/site. Cards are read-only entries
// — there is deliberately NO per-member inspector (D7 verdict), so tapping a
// card does nothing more than the report affordance at the header.

// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/navigation/route_observer.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/crew_roster_item.dart';
import 'package:mine_flow/main.dart';

const double _kPagePadding = 24;

/// Screen for site supervisors and foremen to track and record site crew
/// attendance.
class AttendanceScreen extends StatelessWidget {
  final AttendanceRepository repository;
  final String? initialSiteId;
  final DateTime? initialDate;

  const AttendanceScreen({
    super.key,
    required this.repository,
    this.initialSiteId,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = initialDate ?? DateTime(now.year, now.month, now.day);

    return BlocProvider(
      create: (context) => AttendanceBloc(repository: repository)
        ..add(
          LoadAttendanceEvent(
            date: startDate,
            siteId: initialSiteId ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          ),
        ),
      child: AttendanceView(repository: repository),
    );
  }
}

/// Main view widget for attendance page.
class AttendanceView extends StatefulWidget {
  final AttendanceRepository repository;
  const AttendanceView({super.key, required this.repository});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // CF-053: rebuild so the clear button tracks the text as it changes.
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // STEP-55.11: the batch form is a route-hosted sheet, so this list stays
    // mounted beneath it. The bloc loads once at creation; without a resume
    // hook the list keeps showing the pre-edit snapshot after a save and the
    // newly persisted rows never appear (CF-006/007/009 read-back contract).
    // didPopNext fires when the sheet pops back to this route.
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // The form sheet closed: reload the selected date so the list reflects
    // what was just persisted (leftover snapshot would otherwise win).
    final state = context.read<AttendanceBloc>().state;
    if (state is AttendanceLoaded) {
      context.read<AttendanceBloc>().add(
        LoadAttendanceEvent(date: state.selectedDate, siteId: state.siteId),
      );
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openAttendanceForm(AttendanceLoaded state) {
    // Durable URL (spec §4.4 item 1): date and site ride the query string so
    // refresh/deep link reconstructs the same sheet.
    final uri = Uri(
      path: AppRoutes.attendanceForm,
      queryParameters: {
        'date': _dateKey(state.selectedDate),
        if (state.siteId != null) 'siteId': state.siteId,
      },
    );
    context.push(uri.toString());
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _openContextualReport(AttendanceLoaded state) async {
    // Spec §4.4 item 10: the report is seeded with the selected date/site;
    // list filters and position remain behind the dialog (the dialog does
    // not navigate).
    final day = state.selectedDate;
    await showAppContextualReportDialog(
      context: context,
      reportType: ReportType.attendance,
      sourceTitle: 'Absensi Kru',
      initialDateRange: DateTimeRange(start: day, end: day),
      reportingRepository: appServices!.reportingRepository,
      zoneRepository: appServices!.zoneRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceLoaded && state.successMessage != null) {
          showFToast(
            context: context,
            title: Text(state.successMessage!),
            icon: const Icon(LucideIcons.checkCircle),
            duration: const Duration(seconds: 3),
          );
        } else if (state is AttendanceError) {
          showFToast(
            context: context,
            variant: FToastVariant.destructive,
            title: Text(state.message),
            icon: const Icon(LucideIcons.alertCircle),
            duration: const Duration(seconds: 4),
          );
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
                      'Absensi Kru Lapangan',
                      style: theme.typography.display.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  suffixes: [
                    if (state is AttendanceLoaded && state.hasUnsavedChanges)
                      FBadge(
                        child: Text(
                          'Belum Disimpan',
                          style: theme.typography.body.xs.copyWith(
                            color: theme.colors.primaryForeground,
                          ),
                        ),
                      ),
                  ],
                ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: _buildBody(context, state, theme),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Buat Laporan Kehadiran',
                      button: true,
                      child: FloatingActionButton(
                        heroTag: 'report_attendance_btn',
                        backgroundColor: theme.colors.secondary,
                        foregroundColor: theme.colors.secondaryForeground,
                        elevation: 2,
                        // Spec §4.4 item 10: contextual report seeded by
                        // date/site, replacing the old route push.
                        onPressed: state is AttendanceLoaded
                            ? () => _openContextualReport(state)
                            : null,
                        child: const Icon(LucideIcons.fileText),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton.extended(
                      heroTag: 'add_attendance_btn',
                      backgroundColor: theme.colors.primary,
                      foregroundColor: theme.colors.primaryForeground,
                      elevation: 2,
                      // Spec §4.4 item 7: pushing the sheet keeps this list
                      // (filters + position) mounted beneath it.
                      onPressed: state is AttendanceLoaded
                          ? () => _openAttendanceForm(state)
                          : null,
                      icon: const Icon(LucideIcons.userPlus),
                      label: const Text('Input Absensi'),
                    ),
                  ],
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
    AttendanceState state,
    FThemeData theme,
  ) {
    if (state is AttendanceLoading || state is AttendanceInitial) {
      return const Center(child: FCircularProgress());
    }

    if (state is AttendanceLoaded) {
      final filteredRecords = state.filteredRecords;

      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(_kPagePadding),
              child: Column(
                children: [
                  _buildDateNavigationHeader(context, state.selectedDate),
                  const SizedBox(height: 16),
                  AttendanceSummaryCard(
                    totalCount: state.totalCount,
                    presentCount: state.presentCount,
                    absentCount: state.absentCount,
                    sickCount: state.sickCount,
                    leaveCount: state.leaveCount,
                    activeFilter: state.statusFilter,
                    onFilterTap: null,
                  ),
                  const SizedBox(height: 16),
                  _buildSearchAndFilterRow(context, state),
                ],
              ),
            ),
          ),
          if (filteredRecords.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 64,
                      color: theme.colors.mutedForeground.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.records.isEmpty
                          ? 'Belum ada data absensi untuk tanggal ini'
                          : 'Tidak ada kru yang cocok dengan filter',
                      style: theme.typography.body.md.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: _kPagePadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final record = filteredRecords[index];
                  // Read-only entries (D7: no per-member inspector — tapping
                  // a card never navigates to a detail page).
                  return CrewRosterItem(record: record, readOnly: true);
                }, childCount: filteredRecords.length),
              ),
            ),
        ],
      );
    }

    return Center(
      child: Text(
        'Terjadi kesalahan',
        style: theme.typography.body.md.copyWith(
          color: theme.colors.mutedForeground,
        ),
      ),
    );
  }

  Widget _buildDateNavigationHeader(
    BuildContext context,
    DateTime selectedDate,
  ) {
    final theme = FTheme.of(context);
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(selectedDate);

    return Semantics(
      label: 'Navigasi tanggal',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: 'Hari sebelumnya',
              button: true,
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                color: theme.colors.primary,
                onPressed: () {
                  final prevDate = selectedDate.subtract(
                    const Duration(days: 1),
                  );
                  context.read<AttendanceBloc>().add(ChangeDateEvent(prevDate));
                },
              ),
            ),
            Expanded(
              child: Semantics(
                label: 'Pilih tanggal',
                button: true,
                child: InkWell(
                  onTap: () async {
                    final picked = await AppCalendarDialog.showSingle(
                      context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null && context.mounted) {
                      context.read<AttendanceBloc>().add(
                        ChangeDateEvent(picked),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.calendarDays,
                          size: 20,
                          color: theme.colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            formattedDate,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              label: 'Hari berikutnya',
              button: true,
              child: IconButton(
                icon: const Icon(LucideIcons.arrowRight, size: 18),
                color: theme.colors.primary,
                onPressed: () {
                  final nextDate = selectedDate.add(const Duration(days: 1));
                  context.read<AttendanceBloc>().add(ChangeDateEvent(nextDate));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterRow(
    BuildContext context,
    AttendanceLoaded state,
  ) {
    final theme = FTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            label: 'Pencarian kru',
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama kru atau catatan...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<AttendanceBloc>().add(
                            const UpdateSearchQueryEvent(''),
                          );
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colors.border.withValues(alpha: 0.6),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colors.border.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                context.read<AttendanceBloc>().add(
                  UpdateSearchQueryEvent(value),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Popover-first status filter (master spec D3): one labelled control
        // summarizes the active filter; pills are not spawned.
        _buildStatusFilterControl(context, state),
      ],
    );
  }

  Widget _buildStatusFilterControl(
    BuildContext context,
    AttendanceLoaded state,
  ) {
    final theme = FTheme.of(context);
    final activeLabel = _statusLabel(state.statusFilter);

    return Semantics(
      label: 'Filter status kehadiran',
      button: true,
      child: GestureDetector(
        onTap: () => _showStatusFilterPopover(context, state),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.statusFilter != null
                  ? theme.colors.primary
                  : theme.colors.border.withValues(alpha: 0.3),
              width: state.statusFilter != null ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.filter, size: 18),
              const SizedBox(width: 8),
              Text(
                activeLabel,
                style: theme.typography.body.sm.copyWith(
                  fontWeight: state.statusFilter != null
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: state.statusFilter != null
                      ? theme.colors.primary
                      : theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Filter: Masuk';
      case AttendanceStatus.absent:
        return 'Filter: Alpa';
      case AttendanceStatus.sick:
        return 'Filter: Sakit';
      case AttendanceStatus.leave:
        return 'Filter: Izin';
      case null:
        return 'Semua Status';
    }
  }

  Future<void> _showStatusFilterPopover(
    BuildContext context,
    AttendanceLoaded state,
  ) async {
    final bloc = context.read<AttendanceBloc>();

    await showAppFilterPopover<void>(
      context: context,
      builder: (popoverContext) => _StatusFilterPopover(
        initialFilter: state.statusFilter,
        onApply: (filter) {
          bloc.add(FilterByStatusEvent(filter));
          Navigator.of(popoverContext).pop();
        },
        onReset: () {
          bloc.add(const FilterByStatusEvent(null));
          Navigator.of(popoverContext).pop();
        },
        onCancel: () => Navigator.of(popoverContext).pop(),
      ),
    );
  }
}

/// Popover body for the status filter preview/apply/reset/cancel cycle.
class _StatusFilterPopover extends StatefulWidget {
  final AttendanceStatus? initialFilter;
  final ValueChanged<AttendanceStatus?> onApply;
  final VoidCallback onReset;
  final VoidCallback onCancel;

  const _StatusFilterPopover({
    required this.initialFilter,
    required this.onApply,
    required this.onReset,
    required this.onCancel,
  });

  @override
  State<_StatusFilterPopover> createState() => _StatusFilterPopoverState();
}

class _StatusFilterPopoverState extends State<_StatusFilterPopover> {
  late AttendanceStatus? _selected = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    return AppFilterPopover(
      onApply: () => widget.onApply(_selected),
      onReset: widget.onReset,
      onCancel: widget.onCancel,
      child: RadioGroup<AttendanceStatus?>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final status in AttendanceStatus.values)
              RadioListTile<AttendanceStatus?>(
                value: status,
                title: Text(_statusLabel(status).replaceFirst('Filter: ', '')),
              ),
            const RadioListTile<AttendanceStatus?>(
              value: null,
              title: Text('Semua Status'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Masuk';
      case AttendanceStatus.absent:
        return 'Alpa';
      case AttendanceStatus.sick:
        return 'Sakit';
      case AttendanceStatus.leave:
        return 'Izin';
      case null:
        return 'Semua Status';
    }
  }
}
