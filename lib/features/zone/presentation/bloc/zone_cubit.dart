import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

/// Abstract base for zone states.
abstract class ZoneState extends Equatable {
  const ZoneState();

  @override
  List<Object?> get props => [];
}

/// Initial state before zones are loaded.
class ZoneInitial extends ZoneState {
  const ZoneInitial();
}

/// Zones are being loaded from the local repository.
class ZoneLoading extends ZoneState {
  const ZoneLoading();
}

/// Zones loaded successfully.
class ZoneLoaded extends ZoneState {
  final List<ZoneEntity> zones;

  const ZoneLoaded({required this.zones});

  @override
  List<Object?> get props => [zones];
}

/// An error occurred while loading or creating zones.
class ZoneError extends ZoneState {
  final String message;

  const ZoneError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// Cubit managing the list of zones, fetching them from [ZoneRepository]
/// and handling creation of new zones.
///
/// Emits [ZoneInitial] by default. Call [loadZones] to fetch from the
/// local data source, or [createZone] to persist a new zone.
class ZoneCubit extends Cubit<ZoneState> {
  final ZoneRepository repository;
  final Uuid _uuid;

  ZoneCubit({required this.repository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const ZoneInitial());

  /// Loads all non-deleted zones from the local repository.
  ///
  /// Emits [ZoneLoaded] on success or [ZoneError] on failure.
  Future<void> loadZones() async {
    emit(const ZoneLoading());
    try {
      final zones = repository.getZones();
      emit(ZoneLoaded(zones: zones));
    } catch (e) {
      emit(ZoneError('Gagal memuat zona: ${e.toString()}'));
    }
  }

  /// Creates a new zone with the given [name] and optional [siteId].
  ///
  /// Generates a UUIDv4 for the zone ID locally. [siteId] defaults to
  /// [defaultSiteId] — never an empty string, because `zones.site_id` is a
  /// `uuid` column and an empty string is rejected by Postgres with `22P02`
  /// (STEP-48.26 R-5). Persists the zone via [ZoneRepository.saveZone] and
  /// reloads the list.
  ///
  /// Returns the newly created [ZoneEntity] on success, or null on failure.
  Future<ZoneEntity?> createZone({
    required String name,
    String siteId = defaultSiteId,
  }) async {
    final currentState = state;
    if (currentState is! ZoneLoaded) return null;

    try {
      final now = DateTime.now();
      final zone = ZoneEntity(
        id: _uuid.v4(),
        siteId: siteId,
        name: name,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveZone(zone);

      // Reload zones to reflect the new addition
      final zones = repository.getZones();
      emit(ZoneLoaded(zones: zones));

      return zone;
    } catch (e) {
      emit(ZoneError('Gagal membuat zona: ${e.toString()}'));
      return null;
    }
  }
}
