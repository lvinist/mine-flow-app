import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/crew_roster_item.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kPagePadding = 24;

/// Screen for site supervisors and foremen to track and record site crew attendance.
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
            siteId: initialSiteId ?? '00000000-0000-0000-0000-000000000001',
          ),
        ),
      child: const AttendanceView(),
    );
  }
}

/// Main view widget for attendance page.
class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Semantics(
                    label: 'Berhasil',
                    child: const Icon(Icons.check_circle, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.successMessage!)),
                ],
              ),
              backgroundColor: theme.colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Semantics(
                    label: 'Error',
                    child: const Icon(Icons.error_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: theme.colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Semantics(
              header: true,
              child: Text(
                'Absensi Kru Lapangan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            elevation: 0,
            actions: [
              if (state is AttendanceLoaded && state.hasUnsavedChanges)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: const Text(
                      'Belum Disimpan',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.85,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          body: _buildBody(context, state, colorScheme, theme),
          bottomNavigationBar: _buildBottomBar(
            context,
            state,
            colorScheme,
            theme,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AttendanceState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (state is AttendanceLoading || state is AttendanceInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AttendanceLoaded) {
      final filteredRecords = state.filteredRecords;

      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(_kPagePadding),
              child: Column(
                children: [
                  _buildDateNavigationHeader(
                    context,
                    state.selectedDate,
                    colorScheme,
                    theme,
                  ),
                  const SizedBox(height: 16),
                  AttendanceSummaryCard(
                    totalCount: state.totalCount,
                    presentCount: state.presentCount,
                    absentCount: state.absentCount,
                    sickCount: state.sickCount,
                    leaveCount: state.leaveCount,
                    activeFilter: state.statusFilter,
                    onFilterTap: (status) {
                      context.read<AttendanceBloc>().add(
                        FilterByStatusEvent(status),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSearchAndFilterRow(context, state, colorScheme, theme),
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
                      Icons.person_search_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.records.isEmpty
                          ? 'Belum ada data absensi untuk tanggal ini'
                          : 'Tidak ada kru yang cocok dengan filter',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.records.isEmpty)
                      Semantics(
                        label: 'Muat kru default site',
                        button: true,
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.group_add_outlined),
                          label: const Text('Muat Kru Default Site'),
                          onPressed: () {
                            context.read<AttendanceBloc>().add(
                              SeedDefaultRosterEvent(
                                siteId:
                                    state.siteId ??
                                    '00000000-0000-0000-0000-000000000001',
                                userIds: List.generate(
                                  8,
                                  (i) =>
                                      'KRU-${(i + 1).toString().padLeft(3, '0')}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
                  return CrewRosterItem(
                    record: record,
                    onStatusChanged: (newStatus) {
                      context.read<AttendanceBloc>().add(
                        UpdateCrewStatusEvent(
                          userId: record.userId,
                          status: newStatus,
                        ),
                      );
                    },
                    onRemarksChanged: (newRemarks) {
                      context.read<AttendanceBloc>().add(
                        UpdateCrewStatusEvent(
                          userId: record.userId,
                          status: record.status,
                          remarks: newRemarks,
                        ),
                      );
                    },
                  );
                }, childCount: filteredRecords.length),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Space for bottom save bar
          ),
        ],
      );
    }

    return Center(
      child: Text(
        'Terjadi kesalahan',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDateNavigationHeader(
    BuildContext context,
    DateTime selectedDate,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(selectedDate);

    return Semantics(
      label: 'Navigasi tanggal',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: 'Hari sebelumnya',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                color: colorScheme.primary,
                onPressed: () {
                  final prevDate = selectedDate.subtract(
                    const Duration(days: 1),
                  );
                  context.read<AttendanceBloc>().add(ChangeDateEvent(prevDate));
                },
              ),
            ),
            Semantics(
              label: 'Pilih tanggal',
              button: true,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null && context.mounted) {
                    context.read<AttendanceBloc>().add(ChangeDateEvent(picked));
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Semantics(
              label: 'Hari berikutnya',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                color: colorScheme.primary,
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
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Semantics(
      label: 'Pencarian kru',
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari Kru ID atau Catatan...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
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
              color: colorScheme.outline.withValues(alpha: 0.6),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          context.read<AttendanceBloc>().add(UpdateSearchQueryEvent(value));
        },
      ),
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    AttendanceState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (state is! AttendanceLoaded || state.records.isEmpty) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: state.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            state.isSubmitting
                ? 'Menyimpan Absensi...'
                : 'Simpan Absensi (${state.records.length} Kru)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          onPressed: state.isSubmitting
              ? null
              : () {
                  context.read<AttendanceBloc>().add(
                    const SaveAttendanceBatchEvent(),
                  );
                },
        ),
      ),
    );
  }
}
