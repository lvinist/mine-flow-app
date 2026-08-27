import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/crew_roster_item.dart';

class AttendanceFormPage extends StatefulWidget {
  final AttendanceRepository repository;
  final String? siteId;
  final DateTime? initialDate;

  const AttendanceFormPage({
    super.key,
    required this.repository,
    this.siteId,
    this.initialDate,
  });

  @override
  State<AttendanceFormPage> createState() => _AttendanceFormPageState();
}

class _AttendanceFormPageState extends State<AttendanceFormPage> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final targetDate =
        widget.initialDate ?? DateTime(now.year, now.month, now.day);
    final theme = FTheme.of(context);
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(targetDate);

    return BlocProvider(
      create: (context) => AttendanceBloc(repository: widget.repository)
        ..add(
          LoadAttendanceEvent(
            date: targetDate,
            siteId: widget.siteId ?? '00000000-0000-0000-0000-000000000001',
          ),
        ),
      child: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceLoaded && state.successMessage != null) {
            // CF-048: consume the one-shot success signal so the pop fires only
            // for the just-completed save, not on an unrelated emission.
            context.read<AttendanceBloc>().add(
              const ClearAttendanceSuccessEvent(),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: theme.colors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
            context.pop(true);
          } else if (state is AttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colors.destructive,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: FHeader.nested(
                title: Semantics(
                  header: true,
                  child: Text(
                    'Input Absensi Kru',
                    style: theme.typography.display.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                prefixes: [
                  FButton(
                    variant: FButtonVariant.ghost,
                    onPress: () => context.pop(),
                    child: const Icon(Icons.arrow_back),
                  ),
                ],
              ),
            ),
            body: _buildBody(context, state, theme, formattedDate),
            bottomNavigationBar: _buildBottomBar(context, state, theme),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AttendanceState state,
    FThemeData theme,
    String formattedDate,
  ) {
    if (state is AttendanceLoading || state is AttendanceInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AttendanceLoaded) {
      final records = state.records;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            width: double.infinity,
            color: theme.colors.background,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: theme.colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
          ),
          if (records.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: theme.colors.mutedForeground.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mulai Absensi Massal',
                      style: theme.typography.display.xs.copyWith(
                        color: theme.colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Muat daftar kru default untuk site ini.',
                      style: theme.typography.body.md.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // CF-015: synthetic KRU-xxx seeding is a dev convenience
                    // only — it must never fabricate crew records in a release
                    // build. In release, point at the real roster source.
                    if (kDebugMode)
                      FButton(
                        onPress: () {
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
                        child: const Text('Muat Daftar Kru Default (Debug)'),
                      )
                    else
                      Text(
                        'Daftar kru akan dimuat dari data pengguna terdaftar.',
                        textAlign: TextAlign.center,
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return CrewRosterItem(
                    record: record,
                    readOnly: false,
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

  Widget? _buildBottomBar(
    BuildContext context,
    AttendanceState state,
    FThemeData theme,
  ) {
    if (state is! AttendanceLoaded || state.records.isEmpty) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: SafeArea(
        child: FButton(
          onPress: state.isSubmitting
              ? null
              : () {
                  context.read<AttendanceBloc>().add(
                    const SaveAttendanceBatchEvent(),
                  );
                },
          prefix: state.isSubmitting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colors.primaryForeground,
                  ),
                )
              : Icon(
                  Icons.save_outlined,
                  color: theme.colors.primaryForeground,
                ),
          child: Text(
            state.isSubmitting
                ? 'Menyimpan Absensi...'
                : 'Simpan Absensi (${state.records.length} Kru)',
            style: theme.typography.body.md.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.primaryForeground,
            ),
          ),
        ),
      ),
    );
  }
}
