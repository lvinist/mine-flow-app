import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_event.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_state.dart';

/// BLoC manager for SOP equipment condition check forms.
class EquipmentCheckBloc
    extends Bloc<EquipmentCheckEvent, EquipmentCheckState> {
  final EquipmentCheckRepository repository;
  final Uuid _uuid;

  EquipmentCheckBloc({required this.repository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const EquipmentCheckInitial()) {
    on<LoadEquipmentCheckEvent>(_onLoadEquipmentCheck);
    on<LoadEquipmentHistoryEvent>(_onLoadEquipmentHistory);
    on<SelectEquipmentTypeEvent>(_onSelectEquipmentType);
    on<SelectCheckTypeEvent>(_onSelectCheckType);
    on<UpdateSerialNumberEvent>(_onUpdateSerialNumber);
    on<ToggleCheckItemEvent>(_onToggleCheckItem);
    on<UpdateRemarksEvent>(_onUpdateRemarks);
    on<SubmitEquipmentCheckEvent>(_onSubmitEquipmentCheck);
    on<DeleteEquipmentCheckEvent>(_onDeleteEquipmentCheck);
  }

  /// Default SOP checklist items per equipment type.
  ///
  /// CF-017: every item starts un-answered (`isPassed: null`); the operator must
  /// give each an explicit pass/fail verdict before the check can be submitted.
  static List<CheckItem> getDefaultChecklist(EquipmentType equipmentType) {
    switch (equipmentType) {
      case EquipmentType.gnss:
        return const [
          CheckItem(
            id: 'gnss_battery',
            label: 'Level Baterai & Catu Daya',
            isPassed: null,
          ),
          CheckItem(
            id: 'gnss_antenna',
            label: 'Koneksi Antena & Kabel RTK',
            isPassed: null,
          ),
          CheckItem(
            id: 'gnss_bluetooth',
            label: 'Sinkronisasi Bluetooth Controller',
            isPassed: null,
          ),
          CheckItem(
            id: 'gnss_signal',
            label: 'Sinyal RTK Fix (Base/Rover)',
            isPassed: null,
          ),
          CheckItem(
            id: 'gnss_level_vial',
            label: 'Kondisi Fisik Pole & Gelembung Nivo',
            isPassed: null,
          ),
        ];
      case EquipmentType.totalStation:
        return const [
          CheckItem(
            id: 'ts_tribrach',
            label: 'Levelling Nivo & Optical Plummet',
            isPassed: null,
          ),
          CheckItem(
            id: 'ts_battery',
            label: 'Tegangan Baterai Utama & Cadangan',
            isPassed: null,
          ),
          CheckItem(
            id: 'ts_prism',
            label: 'Kondisi Prisma & Stik Prisma',
            isPassed: null,
          ),
          CheckItem(
            id: 'ts_compensator',
            label: 'Fungsi Kompensator Kemiringan',
            isPassed: null,
          ),
          CheckItem(
            id: 'ts_optics',
            label: 'Kebersihan Lensa & Teropong',
            isPassed: null,
          ),
        ];
      case EquipmentType.drone:
        return const [
          CheckItem(
            id: 'drone_propellers',
            label: 'Inspeksi Baling-baling (Propellers)',
            isPassed: null,
          ),
          CheckItem(
            id: 'drone_battery',
            label: 'Tegangan Baterai Terbang & Sel',
            isPassed: null,
          ),
          CheckItem(
            id: 'drone_remote',
            label: 'Koneksi Remote Controller & Sinyal',
            isPassed: null,
          ),
          CheckItem(
            id: 'drone_gimbal',
            label: 'Kalibrasi Gimbal & Kebersihan Kamera',
            isPassed: null,
          ),
          CheckItem(
            id: 'drone_sensors',
            label: 'Status Kalibrasi Kompas & IMU',
            isPassed: null,
          ),
        ];
    }
  }

  void _onLoadEquipmentCheck(
    LoadEquipmentCheckEvent event,
    Emitter<EquipmentCheckState> emit,
  ) {
    emit(const EquipmentCheckLoading());
    final defaultList = getDefaultChecklist(event.equipmentType);

    emit(
      EquipmentCheckLoaded(
        siteId: event.siteId,
        foremanId: event.foremanId,
        equipmentType: event.equipmentType,
        checkType: event.checkType,
        serialNumber: event.serialNumber ?? '',
        checkTime: DateTime.now(),
        checklist: defaultList,
      ),
    );
  }

  void _onSelectEquipmentType(
    SelectEquipmentTypeEvent event,
    Emitter<EquipmentCheckState> emit,
  ) {
    if (state is EquipmentCheckLoaded) {
      final current = state as EquipmentCheckLoaded;
      if (current.equipmentType == event.equipmentType) return;

      final newChecklist = getDefaultChecklist(event.equipmentType);
      emit(
        current.copyWith(
          equipmentType: event.equipmentType,
          checklist: newChecklist,
        ),
      );
    }
  }

  void _onSelectCheckType(
    SelectCheckTypeEvent event,
    Emitter<EquipmentCheckState> emit,
  ) {
    if (state is EquipmentCheckLoaded) {
      final current = state as EquipmentCheckLoaded;
      emit(current.copyWith(checkType: event.checkType));
    }
  }

  void _onUpdateSerialNumber(
    UpdateSerialNumberEvent event,
    Emitter<EquipmentCheckState> emit,
  ) {
    if (state is EquipmentCheckLoaded) {
      final current = state as EquipmentCheckLoaded;
      emit(current.copyWith(serialNumber: event.serialNumber));
    }
  }

  void _onToggleCheckItem(
    ToggleCheckItemEvent event,
    Emitter<EquipmentCheckState> emit,
  ) {
    if (state is EquipmentCheckLoaded) {
      final current = state as EquipmentCheckLoaded;
      final updatedChecklist = current.checklist.map((item) {
        if (item.id == event.itemId) {
          return item.copyWith(
            isPassed: event.isPassed,
            remarks: event.remarks,
          );
        }
        return item;
      }).toList();

      emit(current.copyWith(checklist: updatedChecklist));
    }
  }

  void _onUpdateRemarks(
    UpdateRemarksEvent event,
    Emitter<EquipmentCheckState> emit,
  ) {
    if (state is EquipmentCheckLoaded) {
      final current = state as EquipmentCheckLoaded;
      emit(current.copyWith(remarks: event.remarks));
    }
  }

  Future<void> _onSubmitEquipmentCheck(
    SubmitEquipmentCheckEvent event,
    Emitter<EquipmentCheckState> emit,
  ) async {
    if (state is EquipmentCheckLoaded) {
      final current = state as EquipmentCheckLoaded;
      emit(current.copyWith(isSubmitting: true));

      try {
        final checkId = _uuid.v4();
        final checkEntity = current.toEquipmentCheck(checkId);

        await repository.saveEquipmentCheck(checkEntity);

        emit(
          EquipmentCheckSubmitted(
            check: checkEntity,
            message: 'Pemeriksaan SOP berhasil disimpan offline',
          ),
        );
      } catch (e) {
        emit(
          EquipmentCheckError('Gagal menyimpan pemeriksaan: ${e.toString()}'),
        );
      }
    }
  }

  Future<void> _onDeleteEquipmentCheck(
    DeleteEquipmentCheckEvent event,
    Emitter<EquipmentCheckState> emit,
  ) async {
    try {
      await repository.deleteEquipmentCheck(event.checkId);

      // Reload history with the same filters (CF-020: no direct repo calls
      // from the UI — the bloc owns the delete + reload lifecycle).
      final currentState = state;
      if (currentState is EquipmentHistoryLoaded) {
        add(
          LoadEquipmentHistoryEvent(
            siteId: event.siteId,
            equipmentTypeFilter: currentState.equipmentTypeFilter,
            statusFilter: currentState.statusFilter,
            searchQuery: currentState.searchQuery.isEmpty
                ? null
                : currentState.searchQuery,
          ),
        );
      } else {
        add(LoadEquipmentHistoryEvent(siteId: event.siteId));
      }
    } catch (e) {
      emit(EquipmentCheckError('Gagal menghapus pemeriksaan: ${e.toString()}'));
    }
  }

  Future<void> _onLoadEquipmentHistory(
    LoadEquipmentHistoryEvent event,
    Emitter<EquipmentCheckState> emit,
  ) async {
    emit(const EquipmentCheckLoading());
    try {
      final list = await repository.getEquipmentChecks(
        siteId: event.siteId,
        equipmentType: event.equipmentTypeFilter,
      );

      var filtered = list;
      if (event.statusFilter != null) {
        filtered = filtered
            .where((check) => check.status == event.statusFilter)
            .toList();
      }

      if (event.searchQuery != null && event.searchQuery!.trim().isNotEmpty) {
        final query = event.searchQuery!.toLowerCase();
        filtered = filtered.where((check) {
          final matchesSerial =
              check.serialNumber?.toLowerCase().contains(query) ?? false;
          final matchesForeman = check.foremanId.toLowerCase().contains(query);
          final matchesRemarks =
              check.remarks?.toLowerCase().contains(query) ?? false;
          final matchesType = check.equipmentType.displayName
              .toLowerCase()
              .contains(query);
          return matchesSerial ||
              matchesForeman ||
              matchesRemarks ||
              matchesType;
        }).toList();
      }

      // Sort timeline descending by checkTime
      filtered.sort((a, b) => b.checkTime.compareTo(a.checkTime));

      emit(
        EquipmentHistoryLoaded(
          checks: filtered,
          equipmentTypeFilter: event.equipmentTypeFilter,
          statusFilter: event.statusFilter,
          searchQuery: event.searchQuery ?? '',
        ),
      );
    } catch (e) {
      emit(
        EquipmentCheckError(
          'Gagal memuat riwayat pemeriksaan: ${e.toString()}',
        ),
      );
    }
  }
}
