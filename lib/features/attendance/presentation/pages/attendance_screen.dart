import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/crew_roster_item.dart';

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
        ..add(LoadAttendanceEvent(
          date: startDate,
          siteId: initialSiteId ?? '00000000-0000-0000-0000-000000000001',
        )),
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
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.successMessage!)),
                ],
              ),
              backgroundColor: kColorSuccess,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
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
            title: const Text(
              'Absensi Kru Lapangan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            actions: [
              if (state is AttendanceLoaded && state.hasUnsavedChanges)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(
                      'Belum Disimpan',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: Color(0xFFEA580C),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          body: _buildBody(context, state, isDark, theme),
          bottomNavigationBar: _buildBottomBar(context, state, isDark, theme),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AttendanceState state,
    bool isDark,
    ThemeData theme,
  ) {
    if (state is AttendanceLoading || state is AttendanceInitial) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is AttendanceLoaded) {
      final filteredRecords = state.filteredRecords;

      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildDateNavigationHeader(context, state.selectedDate, isDark, theme),
                  const SizedBox(height: 12),
                  AttendanceSummaryCard(
                    totalCount: state.totalCount,
                    presentCount: state.presentCount,
                    absentCount: state.absentCount,
                    sickCount: state.sickCount,
                    leaveCount: state.leaveCount,
                    activeFilter: state.statusFilter,
                    onFilterTap: (status) {
                      context.read<AttendanceBloc>().add(FilterByStatusEvent(status));
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSearchAndFilterRow(context, state, isDark),
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
                      color: isDark ? kColorMuted : kColorTextSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.records.isEmpty
                          ? 'Belum ada data absensi untuk tanggal ini'
                          : 'Tidak ada kru yang cocok dengan filter',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? kColorTextPrimaryDark : kColorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.records.isEmpty)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('Muat Kru Default Site'),
                        onPressed: () {
                          context.read<AttendanceBloc>().add(
                                SeedDefaultRosterEvent(
                                  siteId: state.siteId ?? '00000000-0000-0000-0000-000000000001',
                                  userIds: List.generate(
                                    8,
                                    (i) => 'KRU-${(i + 1).toString().padLeft(3, '0')}',
                                  ),
                                ),
                              );
                        },
                      ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                  },
                  childCount: filteredRecords.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Space for bottom save bar
          ),
        ],
      );
    }

    return const Center(child: Text('Terjadi kesalahan'));
  }

  Widget _buildDateNavigationHeader(
    BuildContext context,
    DateTime selectedDate,
    bool isDark,
    ThemeData theme,
  ) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? kColorSurfaceDark : kColorSurface,
        borderRadius: kBorderRadius,
        border: Border.all(color: kColorBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () {
              final prevDate = selectedDate.subtract(const Duration(days: 1));
              context.read<AttendanceBloc>().add(ChangeDateEvent(prevDate));
            },
          ),
          InkWell(
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
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 20, color: kColorPrimary),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () {
              final nextDate = selectedDate.add(const Duration(days: 1));
              context.read<AttendanceBloc>().add(ChangeDateEvent(nextDate));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterRow(
    BuildContext context,
    AttendanceLoaded state,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
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
                        context
                            .read<AttendanceBloc>()
                            .add(const UpdateSearchQueryEvent(''));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              context
                  .read<AttendanceBloc>()
                  .add(UpdateSearchQueryEvent(value));
            },
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    AttendanceState state,
    bool isDark,
    ThemeData theme,
  ) {
    if (state is! AttendanceLoaded || state.records.isEmpty) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? kColorSurfaceDark : kColorSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kColorPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: const RoundedRectangleBorder(borderRadius: kBorderRadius),
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: state.isSubmitting
              ? null
              : () {
                  context
                      .read<AttendanceBloc>()
                      .add(const SaveAttendanceBatchEvent());
                },
        ),
      ),
    );
  }
}
