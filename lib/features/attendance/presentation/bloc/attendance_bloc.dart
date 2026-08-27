import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_state.dart';

/// BLoC component managing site crew attendance state transitions.
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _repository;
  final Uuid _uuid;

  AttendanceBloc({required this._repository, Uuid? uuid})
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
        updatedAt: DateTime.now(),
      );
    } else {
      // Create new record entry for crew member
      updatedRecords.add(
        AttendanceRecord(
          id: _uuid.v4(),
          siteId: currentState.siteId ?? '00000000-0000-0000-0000-000000000001',
          userId: event.userId,
          date: currentState.selectedDate,
          status: event.status,
          remarks: event.remarks,
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
      await _repository.saveAttendanceBatch(currentState.records);

      emit(
        currentState.copyWith(
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

  void _onSeedDefaultRoster(
    SeedDefaultRosterEvent event,
    Emitter<AttendanceState> emit,
  ) {
    final currentState = state;
    if (currentState is! AttendanceLoaded) return;

    final existingUserIds = currentState.records.map((r) => r.userId).toSet();
    final newRecords = List<AttendanceRecord>.from(currentState.records);

    for (final userId in event.userIds) {
      if (!existingUserIds.contains(userId)) {
        final numPart = userId.split('-').last;
        final index = int.tryParse(numPart) ?? 1;

        String role = 'Crew';
        if (index == 1) {
          role = 'Supervisor';
        } else if (index == 2) {
          role = 'Foreman';
        } else if (index == 3) {
          role = 'Operator Excavator';
        } else if (index == 4) {
          role = 'Operator Dump Truck';
        }

        newRecords.add(
          AttendanceRecord(
            id: _uuid.v4(),
            siteId: event.siteId,
            userId: userId,
            userName: 'Pekerja $index',
            role: role,
            date: currentState.selectedDate,
            status: AttendanceStatus.present,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    emit(
      currentState.copyWith(
        records: newRecords,
        siteId: event.siteId,
        hasUnsavedChanges: true,
      ),
    );
  }
}
