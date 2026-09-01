import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/core/utils/crs_utils.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/// Events for the [BenchmarkBloc] that manages the benchmark list and form.
abstract class BenchmarkEvent extends Equatable {
  const BenchmarkEvent();

  @override
  List<Object?> get props => [];
}

/// Fires initial load of benchmarks — optionally filtered by [status].
class LoadBenchmarks extends BenchmarkEvent {
  final String? status;
  const LoadBenchmarks({this.status});

  @override
  List<Object?> get props => [status];
}

/// Navigates to the form in create mode.
class CreateBenchmark extends BenchmarkEvent {
  const CreateBenchmark();

  @override
  List<Object?> get props => [];
}

/// Opens an existing benchmark for editing.
class EditBenchmark extends BenchmarkEvent {
  final Benchmark benchmark;
  const EditBenchmark(this.benchmark);

  @override
  List<Object?> get props => [benchmark];
}

/// Updates the form field BM ID.
class FormBmIdChanged extends BenchmarkEvent {
  final String bmId;
  const FormBmIdChanged(this.bmId);

  @override
  List<Object?> get props => [bmId];
}

/// Updates the form field Northing (metres).
class FormNorthingChanged extends BenchmarkEvent {
  final double northing;
  const FormNorthingChanged(this.northing);

  @override
  List<Object?> get props => [northing];
}

/// Updates the form field Easting (metres).
class FormEastingChanged extends BenchmarkEvent {
  final double easting;
  const FormEastingChanged(this.easting);

  @override
  List<Object?> get props => [easting];
}

/// Updates the form field Orthometric Height (metres).
class FormOrthoHeightChanged extends BenchmarkEvent {
  final double orthoHeight;
  const FormOrthoHeightChanged(this.orthoHeight);

  @override
  List<Object?> get props => [orthoHeight];
}

/// Updates the form field Code.
class FormCodeChanged extends BenchmarkEvent {
  final String code;
  const FormCodeChanged(this.code);

  @override
  List<Object?> get props => [code];
}

/// Updates the form field Orde (order/grade).
class FormOrdeChanged extends BenchmarkEvent {
  final String orde;
  const FormOrdeChanged(this.orde);

  @override
  List<Object?> get props => [orde];
}

/// Updates the form field CRS identifier.
///
/// Triggers automatic recalculation of Lat/Lon from Northing/Easting.
class FormCrsChanged extends BenchmarkEvent {
  final String crsIdentifier;
  const FormCrsChanged(this.crsIdentifier);

  @override
  List<Object?> get props => [crsIdentifier];
}

/// Updates the form field Ellipsoidal Height (metres).
class FormEllipsHeightChanged extends BenchmarkEvent {
  final double ellipsHeight;
  const FormEllipsHeightChanged(this.ellipsHeight);

  @override
  List<Object?> get props => [ellipsHeight];
}

/// Updates the form field Status.
class FormStatusChanged extends BenchmarkEvent {
  final String status;
  const FormStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Submits the form — creates or updates the benchmark.
class SubmitBenchmark extends BenchmarkEvent {
  const SubmitBenchmark();

  @override
  List<Object?> get props => [];
}

/// Cancels the form and returns to list view.
class CancelForm extends BenchmarkEvent {
  const CancelForm();

  @override
  List<Object?> get props => [];
}

/// Deletes a benchmark by [id].
class DeleteBenchmark extends BenchmarkEvent {
  final String id;
  const DeleteBenchmark(this.id);

  @override
  List<Object?> get props => [id];
}

/// Triggers a full refresh.
class RefreshBenchmarks extends BenchmarkEvent {
  const RefreshBenchmarks();

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

/// Abstract base for all [BenchmarkBloc] states.
abstract class BenchmarkState extends Equatable {
  const BenchmarkState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class BenchmarkInitial extends BenchmarkState {
  const BenchmarkInitial();
}

/// Loading state while fetching benchmarks.
class BenchmarkLoading extends BenchmarkState {
  const BenchmarkLoading();
}

/// Loaded state with the benchmark list.
class BenchmarkListLoaded extends BenchmarkState {
  final List<Benchmark> benchmarks;

  const BenchmarkListLoaded({required this.benchmarks});

  @override
  List<Object?> get props => [benchmarks];
}

/// Form state for creating or editing a benchmark.
///
/// If [editingBenchmark] is non-null, the form is in edit mode.
/// Latitude and Longitude are auto-computed from Northing/Easting/CRS.
class BenchmarkFormState extends BenchmarkState {
  final Benchmark? editingBenchmark;
  final String bmId;
  final double northing;
  final double easting;
  final double orthoHeight;
  final String code;
  final String orde;
  final String crsIdentifier;
  final double ellipsHeight;
  final String status;

  /// Computed latitude based on current Northing, Easting, and CRS.
  /// Will be `null` if calculation fails (e.g., invalid values).
  final double? computedLatitude;

  /// Computed longitude based on current Northing, Easting, and CRS.
  /// Will be `null` if calculation fails (e.g., invalid values).
  final double? computedLongitude;

  const BenchmarkFormState({
    this.editingBenchmark,
    required this.bmId,
    required this.northing,
    required this.easting,
    required this.orthoHeight,
    required this.code,
    required this.orde,
    required this.crsIdentifier,
    required this.ellipsHeight,
    required this.status,
    this.computedLatitude,
    this.computedLongitude,
  });

  /// Whether this form is in edit mode.
  bool get isEditing => editingBenchmark != null;

  BenchmarkFormState copyWith({
    Benchmark? editingBenchmark,
    String? bmId,
    double? northing,
    double? easting,
    double? orthoHeight,
    String? code,
    String? orde,
    String? crsIdentifier,
    double? ellipsHeight,
    String? status,
    double? computedLatitude,
    double? computedLongitude,
    bool clearLatLon = false,
    bool clearEditing = false,
  }) {
    return BenchmarkFormState(
      editingBenchmark: clearEditing
          ? null
          : (editingBenchmark ?? this.editingBenchmark),
      bmId: bmId ?? this.bmId,
      northing: northing ?? this.northing,
      easting: easting ?? this.easting,
      orthoHeight: orthoHeight ?? this.orthoHeight,
      code: code ?? this.code,
      orde: orde ?? this.orde,
      crsIdentifier: crsIdentifier ?? this.crsIdentifier,
      ellipsHeight: ellipsHeight ?? this.ellipsHeight,
      status: status ?? this.status,
      computedLatitude: clearLatLon
          ? null
          : (computedLatitude ?? this.computedLatitude),
      computedLongitude: clearLatLon
          ? null
          : (computedLongitude ?? this.computedLongitude),
    );
  }

  @override
  List<Object?> get props => [
    editingBenchmark,
    bmId,
    northing,
    easting,
    orthoHeight,
    code,
    orde,
    crsIdentifier,
    ellipsHeight,
    status,
    computedLatitude,
    computedLongitude,
  ];
}

/// Operation was successful.
class BenchmarkSuccess extends BenchmarkState {
  final String message;
  const BenchmarkSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state with a descriptive [message].
class BenchmarkError extends BenchmarkState {
  final String message;
  const BenchmarkError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

/// BLoC managing the Benchmark Database feature.
///
/// Supports:
/// - Load & refresh from [BenchmarkRepository]
/// - Form state with auto-calculated Lat/Lon via [CrsUtils]
/// - Create, update, and delete operations
class BenchmarkBloc extends Bloc<BenchmarkEvent, BenchmarkState> {
  final BenchmarkRepository _repository;

  BenchmarkBloc({required this._repository}) : super(const BenchmarkInitial()) {
    on<LoadBenchmarks>(_onLoadBenchmarks);
    on<CreateBenchmark>(_onCreateBenchmark);
    on<EditBenchmark>(_onEditBenchmark);
    on<FormBmIdChanged>(_onFormBmIdChanged);
    on<FormNorthingChanged>(_onFormNorthingChanged);
    on<FormEastingChanged>(_onFormEastingChanged);
    on<FormOrthoHeightChanged>(_onFormOrthoHeightChanged);
    on<FormCodeChanged>(_onFormCodeChanged);
    on<FormOrdeChanged>(_onFormOrdeChanged);
    on<FormCrsChanged>(_onFormCrsChanged);
    on<FormEllipsHeightChanged>(_onFormEllipsHeightChanged);
    on<FormStatusChanged>(_onFormStatusChanged);
    on<SubmitBenchmark>(_onSubmitBenchmark);
    on<CancelForm>(_onCancelForm);
    on<DeleteBenchmark>(_onDeleteBenchmark);
    on<RefreshBenchmarks>(_onRefreshBenchmarks);
  }

  /// Computes Lat/Lon from the current form values.
  ///
  /// Returns `(latitude, longitude)` or `null` if computation fails.
  ({double latitude, double longitude})? _computeLatLon(
    double northing,
    double easting,
    String crsIdentifier,
  ) {
    try {
      final result = CrsUtils.utmToLatLon(
        northing: northing,
        easting: easting,
        crsIdentifier: crsIdentifier,
      );
      return (latitude: result.latitude, longitude: result.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onLoadBenchmarks(
    LoadBenchmarks event,
    Emitter<BenchmarkState> emit,
  ) async {
    emit(const BenchmarkLoading());
    try {
      final benchmarks = await _repository.getBenchmarks(status: event.status);
      emit(BenchmarkListLoaded(benchmarks: benchmarks));
    } catch (e) {
      emit(BenchmarkError('Gagal memuat benchmark: ${e.toString()}'));
    }
  }

  void _onCreateBenchmark(CreateBenchmark event, Emitter<BenchmarkState> emit) {
    final latLon = _computeLatLon(0.0, 0.0, 'UTM Zone 51S');
    emit(
      BenchmarkFormState(
        bmId: '',
        northing: 0.0,
        easting: 0.0,
        orthoHeight: 0.0,
        code: '',
        orde: '',
        crsIdentifier: 'UTM Zone 51S',
        ellipsHeight: 0.0,
        status: 'active',
        computedLatitude: latLon?.latitude,
        computedLongitude: latLon?.longitude,
      ),
    );
  }

  void _onEditBenchmark(EditBenchmark event, Emitter<BenchmarkState> emit) {
    final b = event.benchmark;
    // CF-033: use the stored CRS, not a hardcoded default.
    final latLon = _computeLatLon(b.northing, b.easting, b.crsIdentifier);
    emit(
      BenchmarkFormState(
        editingBenchmark: b,
        bmId: b.bmId,
        northing: b.northing,
        easting: b.easting,
        orthoHeight: b.orthoHeight,
        code: b.code,
        orde: b.orde,
        crsIdentifier: b.crsIdentifier,
        ellipsHeight: b.ellipsHeight,
        status: b.status,
        computedLatitude: latLon?.latitude ?? b.latitude,
        computedLongitude: latLon?.longitude ?? b.longitude,
      ),
    );
  }

  void _onFormBmIdChanged(FormBmIdChanged event, Emitter<BenchmarkState> emit) {
    final current = state;
    if (current is BenchmarkFormState) {
      emit(current.copyWith(bmId: event.bmId));
    }
  }

  void _onFormNorthingChanged(
    FormNorthingChanged event,
    Emitter<BenchmarkState> emit,
  ) {
    final current = state;
    if (current is BenchmarkFormState) {
      final latLon = _computeLatLon(
        event.northing,
        current.easting,
        current.crsIdentifier,
      );
      emit(
        current.copyWith(
          northing: event.northing,
          computedLatitude: latLon?.latitude,
          computedLongitude: latLon?.longitude,
          clearLatLon: latLon == null,
        ),
      );
    }
  }

  void _onFormEastingChanged(
    FormEastingChanged event,
    Emitter<BenchmarkState> emit,
  ) {
    final current = state;
    if (current is BenchmarkFormState) {
      final latLon = _computeLatLon(
        current.northing,
        event.easting,
        current.crsIdentifier,
      );
      emit(
        current.copyWith(
          easting: event.easting,
          computedLatitude: latLon?.latitude,
          computedLongitude: latLon?.longitude,
          clearLatLon: latLon == null,
        ),
      );
    }
  }

  void _onFormOrthoHeightChanged(
    FormOrthoHeightChanged event,
    Emitter<BenchmarkState> emit,
  ) {
    final current = state;
    if (current is BenchmarkFormState) {
      emit(current.copyWith(orthoHeight: event.orthoHeight));
    }
  }

  void _onFormCodeChanged(FormCodeChanged event, Emitter<BenchmarkState> emit) {
    final current = state;
    if (current is BenchmarkFormState) {
      emit(current.copyWith(code: event.code));
    }
  }

  void _onFormOrdeChanged(FormOrdeChanged event, Emitter<BenchmarkState> emit) {
    final current = state;
    if (current is BenchmarkFormState) {
      emit(current.copyWith(orde: event.orde));
    }
  }

  void _onFormCrsChanged(FormCrsChanged event, Emitter<BenchmarkState> emit) {
    final current = state;
    if (current is BenchmarkFormState) {
      final latLon = _computeLatLon(
        current.northing,
        current.easting,
        event.crsIdentifier,
      );
      emit(
        current.copyWith(
          crsIdentifier: event.crsIdentifier,
          computedLatitude: latLon?.latitude,
          computedLongitude: latLon?.longitude,
          clearLatLon: latLon == null,
        ),
      );
    }
  }

  void _onFormEllipsHeightChanged(
    FormEllipsHeightChanged event,
    Emitter<BenchmarkState> emit,
  ) {
    final current = state;
    if (current is BenchmarkFormState) {
      emit(current.copyWith(ellipsHeight: event.ellipsHeight));
    }
  }

  void _onFormStatusChanged(
    FormStatusChanged event,
    Emitter<BenchmarkState> emit,
  ) {
    final current = state;
    if (current is BenchmarkFormState) {
      emit(current.copyWith(status: event.status));
    }
  }

  Future<void> _onSubmitBenchmark(
    SubmitBenchmark event,
    Emitter<BenchmarkState> emit,
  ) async {
    final current = state;
    if (current is! BenchmarkFormState) return;

    // Validate BM ID is not empty
    if (current.bmId.trim().isEmpty) {
      emit(const BenchmarkError('BM ID tidak boleh kosong.'));
      return;
    }

    try {
      final lat = current.computedLatitude ?? 0.0;
      final lon = current.computedLongitude ?? 0.0;

      // A new benchmark must not fabricate its primary key: benchmarks.id is
      // a uuid column and '' is rejected with 22P02 (STEP-48.26 R-5). The
      // repository/sync layer assigns and persists the generated UUIDv4.
      final benchmark = Benchmark(
        id: current.editingBenchmark?.id ?? const Uuid().v4(),
        bmId: current.bmId,
        northing: current.northing,
        easting: current.easting,
        orthoHeight: current.orthoHeight,
        code: current.code,
        orde: current.orde,
        geom: current.editingBenchmark?.geom,
        latitude: lat,
        longitude: lon,
        crsIdentifier: current.crsIdentifier,
        ellipsHeight: current.ellipsHeight,
        status: current.status,
      );

      await _repository.saveBenchmark(benchmark);
      emit(const BenchmarkSuccess('Benchmark berhasil disimpan.'));
    } catch (e) {
      emit(BenchmarkError('Gagal menyimpan benchmark: ${e.toString()}'));
    }
  }

  Future<void> _onCancelForm(
    CancelForm event,
    Emitter<BenchmarkState> emit,
  ) async {
    // Reload the list
    add(const LoadBenchmarks());
  }

  Future<void> _onDeleteBenchmark(
    DeleteBenchmark event,
    Emitter<BenchmarkState> emit,
  ) async {
    try {
      await _repository.deleteBenchmark(event.id);
      // Reload after deletion
      add(const LoadBenchmarks());
    } catch (e) {
      emit(BenchmarkError('Gagal menghapus benchmark: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshBenchmarks(
    RefreshBenchmarks event,
    Emitter<BenchmarkState> emit,
  ) async {
    emit(const BenchmarkLoading());
    try {
      final benchmarks = await _repository.getBenchmarks();
      emit(BenchmarkListLoaded(benchmarks: benchmarks));
    } catch (e) {
      emit(BenchmarkError('Gagal memuat ulang benchmark: ${e.toString()}'));
    }
  }
}
