import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';

/// BLoC component managing site crew attendance state transitions.
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _repository;
  final Uuid _uuid;

  /// Source of the real site roster (actual `users.id` UUIDs).
  ///
  /// Optional so the list screen and tests can construct the bloc without
  /// auth wiring; the debug roster seeder degrades to a no-op without it
  /// instead of fabricating identifiers (STEP-48.26 R-6).
  final AuthRepository? _authRepository;

  AttendanceBloc({required this._repository, this._authRepository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const AttendanceInitial()) {
    on<LoadAttendanceEvent>(_onLoadAttendance);
    on<ChangeDateEvent>(_onChangeDate);
    on<UpdateCrewStatusEvent>(_onUpdateCrewStatus);
    on<UpdateSearchQueryEvent>(_onUpdateSearchQuery);
    on<FilterByStatusEvent>(_onFilterByStatus);
    on<SaveAttendanceBatchEvent>(_onSaveAttendanceBatch);
    on<SeedDefaultRosterEvent>(_onSeedDefaultRoster);
    on<ClearAttendanceSuccessEvent>(_onClearSuccess);
  }

  void _onClearSuccess(
    ClearAttendanceSuccessEvent event,
    Emitter<AttendanceState> emit,
  ) {
    final current = state;
    if (current is AttendanceLoaded && current.successMessage != null) {
      emit(current.copyWith(clearSuccessMessage: true));
    }
  }

  Future<void> _onLoadAttendance(
    LoadAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      final records = await _repository.getAttendanceForDate(
        event.date,
        siteId: event.siteId,
      );

      emit(
        AttendanceLoaded(
          records: records,
          selectedDate: event.date,
          siteId: event.siteId,
        ),
      );
    } catch (e) {
      emit(AttendanceError('Gagal memuat data absensi: ${e.toString()}'));
    }
  }

  Future<void> _onChangeDate(
    ChangeDateEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final currentState = state;
    String? siteId;
    if (currentState is AttendanceLoaded) {
      siteId = currentState.siteId;
    }

    add(LoadAttendanceEvent(date: event.date, siteId: siteId));
  }

  void _onUpdateCrewStatus(
    UpdateCrewStatusEvent event,
    Emitter<AttendanceState> emit,
  ) {
    final currentState = state;
    if (currentState is! AttendanceLoaded) return;

    final updatedRecords = List<AttendanceRecord>.from(currentState.records);
    final index = updatedRecords.indexWhere((r) => r.userId == event.userId);

    if (index != -1) {
      final existing = updatedRecords[index];
      updatedRecords[index] = existing.copyWith(
        status: event.status,
        remarks: event.remarks ?? existing.remarks,
        loggedBy: existing.loggedBy ?? currentUserId(),
        updatedAt: DateTime.now(),
      );
    } else {
      // Create new record entry for crew member
      updatedRecords.add(
        AttendanceRecord(
          id: _uuid.v4(),
          siteId: currentState.siteId ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          userId: event.userId,
          date: currentState.selectedDate,
          status: event.status,
          remarks: event.remarks,
          loggedBy: currentUserId(),
          createdAt: DateTime.now(),
        ),
      );
    }

    emit(
      currentState.copyWith(
        records: updatedRecords,
        hasUnsavedChanges: true,
        clearSuccessMessage: true,
      ),
    );
  }

  void _onUpdateSearchQuery(
    UpdateSearchQueryEvent event,
    Emitter<AttendanceState> emit,
  ) {
    final currentState = state;
    if (currentState is AttendanceLoaded) {
      emit(currentState.copyWith(searchQuery: event.query));
    }
  }

  void _onFilterByStatus(
    FilterByStatusEvent event,
    Emitter<AttendanceState> emit,
  ) {
    final currentState = state;
    if (currentState is AttendanceLoaded) {
      if (event.statusFilter == null) {
        emit(currentState.copyWith(clearStatusFilter: true));
      } else {
        emit(currentState.copyWith(statusFilter: event.statusFilter));
      }
    }
  }

  Future<void> _onSaveAttendanceBatch(
    SaveAttendanceBatchEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AttendanceLoaded) return;

    emit(currentState.copyWith(isSubmitting: true));

    try {
      final recordsToSave = currentState.records.map((r) {
        if (r.loggedBy == null || r.loggedBy!.isEmpty) {
          return r.copyWith(loggedBy: currentUserId());
        }
        return r;
      }).toList();

      await _repository.saveAttendanceBatch(recordsToSave);

      emit(
        currentState.copyWith(
          records: recordsToSave,
          isSubmitting: false,
          hasUnsavedChanges: false,
          successMessage: 'Absensi berhasil disimpan offline',
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isSubmitting: false));
      emit(AttendanceError('Gagal menyimpan absensi: ${e.toString()}'));
    }
  }

  Future<void> _onSeedDefaultRoster(
    SeedDefaultRosterEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AttendanceLoaded) return;

    final List<AttendanceRecord> rosterRecords;

    if (event.userIds.isNotEmpty) {
      // Test-only path: explicit identifiers supplied by the caller. Kept so
      // widget tests can drive this event directly; production code must not
      // use it (see [SeedDefaultRosterEvent] — non-UUID ids cannot be saved).
      rosterRecords = [
        for (final userId in event.userIds)
          AttendanceRecord(
            id: _uuid.v4(),
            siteId: event.siteId,
            userId: userId,
            userName: 'Pekerja ${_debugRoleIndex(userId)}',
            role: _debugRoleFor(userId),
            date: currentState.selectedDate,
            status: AttendanceStatus.present,
            loggedBy: currentUserId(),
            createdAt: DateTime.now(),
          ),
      ];
    } else {
      // Real roster path: load the site's users so every record references
      // an actual `users.id` UUID (STEP-48.26 R-6 — the old KRU-00N debug
      // codes were rejected by attendance_records.user_id with 22P02).
      final authRepository = _authRepository;
      if (authRepository == null) {
        // No auth wiring — degrade to a no-op rather than fabricating
        // identifiers that cannot be persisted.
        return;
      }
      try {
        final users = await authRepository.getSiteRoster(siteId: event.siteId);
        if (users.isEmpty) {
          emit(
            const AttendanceError('Belum ada kru terdaftar untuk site ini.'),
          );
          return;
        }
        rosterRecords = [
          for (final user in users)
            AttendanceRecord(
              id: _uuid.v4(),
              siteId: event.siteId,
              userId: user.id,
              userName: user.name,
              role: _roleLabel(user.role),
              date: currentState.selectedDate,
              status: AttendanceStatus.present,
              loggedBy: currentUserId(),
              createdAt: DateTime.now(),
            ),
        ];
      } catch (e) {
        emit(AttendanceError('Gagal memuat daftar kru: ${e.toString()}'));
        return;
      }
    }

    final existingUserIds = currentState.records.map((r) => r.userId).toSet();
    final newRecords = List<AttendanceRecord>.from(currentState.records)
      ..addAll(rosterRecords.where((r) => !existingUserIds.contains(r.userId)));

    emit(
      currentState.copyWith(
        records: newRecords,
        siteId: event.siteId,
        hasUnsavedChanges: true,
      ),
    );
  }

  /// Numeric suffix used by the legacy debug-id path for display names.
  static int _debugRoleIndex(String userId) {
    final numPart = userId.split('-').last;
    return int.tryParse(numPart) ?? 1;
  }

  /// Legacy debug-role derivation for explicit test ids (KRU-001 style).
  static String _debugRoleFor(String userId) {
    switch (_debugRoleIndex(userId)) {
      case 1:
        return 'Supervisor';
      case 2:
        return 'Foreman';
      case 3:
        return 'Operator Excavator';
      case 4:
        return 'Operator Dump Truck';
      default:
        return 'Crew';
    }
  }

  /// Maps a `users.role` value to the roster's display label.
  static String _roleLabel(String role) {
    switch (role) {
      case 'supervisor':
        return 'Supervisor';
      case 'foreman':
        return 'Foreman';
      default:
        return 'Crew';
    }
  }
}
