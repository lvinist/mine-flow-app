import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/// Events for the [DataBucketBloc] that manages the file list state.
abstract class DataBucketEvent extends Equatable {
  const DataBucketEvent();

  @override
  List<Object?> get props => [];
}

/// Fires initial load of files — optionally filtered by [siteId].
class LoadFiles extends DataBucketEvent {
  final String? siteId;
  const LoadFiles({this.siteId});

  @override
  List<Object?> get props => [siteId];
}

/// Filters the loaded list by a text search query (against file name).
class SearchFiles extends DataBucketEvent {
  final String query;
  const SearchFiles(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filters the loaded list by [zoneId]. Pass `null` to clear the zone filter.
class FilterByZone extends DataBucketEvent {
  final String? zoneId;
  const FilterByZone(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

/// Filters the loaded list by [fileType]. Pass `null` to clear the type filter.
class FilterByType extends DataBucketEvent {
  final String? fileType;
  const FilterByType(this.fileType);

  @override
  List<Object?> get props => [fileType];
}

/// Deletes a file by its [fileId].
class DeleteFile extends DataBucketEvent {
  final String fileId;
  const DeleteFile(this.fileId);

  @override
  List<Object?> get props => [fileId];
}

/// Triggers a full refresh (re-fetches from repository).
class RefreshFiles extends DataBucketEvent {
  const RefreshFiles();

  @override
  List<Object?> get props => [];
}

/// Internal: the repository's cache stream emitted a new record set.
///
/// Private because only [DataBucketBloc]'s own subscription raises it (R-4);
/// callers use [LoadFiles] / [RefreshFiles].
class _FilesUpdated extends DataBucketEvent {
  final List<GeospatialFile> files;
  const _FilesUpdated(this.files);

  @override
  List<Object?> get props => [files];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

/// Abstract base for all [DataBucketBloc] states.
abstract class DataBucketState extends Equatable {
  const DataBucketState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class DataBucketInitial extends DataBucketState {
  const DataBucketInitial();
}

/// Loading state while fetching files.
class DataBucketLoading extends DataBucketState {
  const DataBucketLoading();
}

/// Loaded state with the file list and active filter values.
class DataBucketLoaded extends DataBucketState {
  final List<GeospatialFile> files;
  final String? searchQuery;
  final String? filterZoneId;
  final String? filterFileType;
  final bool isDeleting;

  const DataBucketLoaded({
    required this.files,
    this.searchQuery,
    this.filterZoneId,
    this.filterFileType,
    this.isDeleting = false,
  });

  /// Returns the filtered subset of [files] based on active search/filters.
  List<GeospatialFile> get filteredFiles {
    var result = files;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result
          .where((f) => f.fileName.toLowerCase().contains(query))
          .toList();
    }

    if (filterZoneId != null) {
      result = result.where((f) => f.zoneId == filterZoneId).toList();
    }

    if (filterFileType != null) {
      result = result.where((f) => f.fileType == filterFileType).toList();
    }

    return result;
  }

  DataBucketLoaded copyWith({
    List<GeospatialFile>? files,
    String? searchQuery,
    String? filterZoneId,
    String? filterFileType,
    bool clearSearch = false,
    bool clearZoneFilter = false,
    bool clearTypeFilter = false,
    bool? isDeleting,
  }) {
    return DataBucketLoaded(
      files: files ?? this.files,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      filterZoneId: clearZoneFilter
          ? null
          : (filterZoneId ?? this.filterZoneId),
      filterFileType: clearTypeFilter
          ? null
          : (filterFileType ?? this.filterFileType),
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  @override
  List<Object?> get props => [
    files,
    searchQuery,
    filterZoneId,
    filterFileType,
    isDeleting,
  ];
}

/// Error state with a descriptive [message].
class DataBucketError extends DataBucketState {
  final String message;

  const DataBucketError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

/// BLoC managing the file browser list for the Data Bucket feature.
///
/// Supports:
/// - Load & refresh from [DataBucketRepository]
/// - Client-side search & filter by zone / file type
/// - Row deletion
///
/// STEP-48.22 (re-run, finding R-4): the bloc loaded once from the local cache
/// and never observed the repository again. `getFiles` is local-first with an
/// `unawaited` background refresh, so any row that arrived from staging after
/// mount was invisible until a manual [RefreshFiles] — the data-bucket journey's
/// "site-scoped rows exist → file cards must render" assertion caught this the
/// moment 48.20 re-sited the seed row (before that, both sides were empty and it
/// passed for the wrong reason). The bloc now subscribes to
/// [DataBucketRepository.watchFiles] and folds cache updates into the loaded
/// state, preserving the active search/filter selections.
class DataBucketBloc extends Bloc<DataBucketEvent, DataBucketState> {
  final DataBucketRepository _repository;
  String? _siteId;

  /// Subscription to the repository's cache stream (see [_onLoadFiles]).
  StreamSubscription<List<GeospatialFile>>? _filesSubscription;

  DataBucketBloc({required this._repository, this._siteId})
    : super(const DataBucketInitial()) {
    on<LoadFiles>(_onLoadFiles);
    on<SearchFiles>(_onSearchFiles);
    on<FilterByZone>(_onFilterByZone);
    on<FilterByType>(_onFilterByType);
    on<DeleteFile>(_onDeleteFile);
    on<RefreshFiles>(_onRefreshFiles);
    on<_FilesUpdated>(_onFilesUpdated);
  }

  @override
  Future<void> close() async {
    await _filesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadFiles(
    LoadFiles event,
    Emitter<DataBucketState> emit,
  ) async {
    emit(const DataBucketLoading());
    _siteId = event.siteId ?? _siteId;

    try {
      final files = await _repository.getFiles(siteId: _siteId);
      emit(DataBucketLoaded(files: files));
      _subscribeToFiles();
    } catch (e) {
      emit(DataBucketError('Gagal memuat daftar file: ${e.toString()}'));
    }
  }

  /// Watches the repository so background refreshes reach the UI (R-4).
  ///
  /// Stream errors are swallowed deliberately: the list has already loaded, so
  /// degrading to "no live updates" is correct, whereas replacing a rendered list
  /// with an error state would be a regression. The manual [RefreshFiles] path
  /// still surfaces read errors.
  void _subscribeToFiles() {
    _filesSubscription?.cancel();
    _filesSubscription = _repository
        .watchFiles(siteId: _siteId)
        .listen((files) => add(_FilesUpdated(files)), onError: (_) {});
  }

  void _onFilesUpdated(_FilesUpdated event, Emitter<DataBucketState> emit) {
    final current = state;
    if (current is! DataBucketLoaded) return;
    if (current.files == event.files) return;
    emit(current.copyWith(files: event.files));
  }

  void _onSearchFiles(SearchFiles event, Emitter<DataBucketState> emit) {
    final current = state;
    if (current is DataBucketLoaded) {
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  void _onFilterByZone(FilterByZone event, Emitter<DataBucketState> emit) {
    final current = state;
    if (current is DataBucketLoaded) {
      emit(current.copyWith(filterZoneId: event.zoneId));
    }
  }

  void _onFilterByType(FilterByType event, Emitter<DataBucketState> emit) {
    final current = state;
    if (current is DataBucketLoaded) {
      emit(current.copyWith(filterFileType: event.fileType));
    }
  }

  Future<void> _onDeleteFile(
    DeleteFile event,
    Emitter<DataBucketState> emit,
  ) async {
    final current = state;
    if (current is! DataBucketLoaded) return;

    // CF-079: emit a loading (deleting) state so the UI can disable the
    // button and prevent double-trigger during the Drive round-trip.
    emit(current.copyWith(isDeleting: true));
    try {
      await _repository.deleteFile(event.fileId);
      final updated = current.files.where((f) => f.id != event.fileId).toList();
      emit(DataBucketLoaded(files: updated));
    } catch (e) {
      emit(DataBucketError('Gagal menghapus file: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshFiles(
    RefreshFiles event,
    Emitter<DataBucketState> emit,
  ) async {
    emit(const DataBucketLoading());
    try {
      final files = await _repository.getFiles(siteId: _siteId);
      emit(DataBucketLoaded(files: files));
      _subscribeToFiles();
    } catch (e) {
      emit(DataBucketError('Gagal memuat ulang daftar file: ${e.toString()}'));
    }
  }
}
