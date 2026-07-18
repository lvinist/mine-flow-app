# mine-flow-app — Internal Architecture

> **System-level architecture** lives in the docs hub:
> - [Doc 03 — Architecture Overview & Component Boundaries](../mine-flow-docs/architecture/03-architecture-overview.md)
> - [Doc 15 — Native App Architecture](../mine-flow-docs/architecture/15-native-app-architecture.md)
> - [Doc 07 — UI / Design System](../mine-flow-docs/architecture/07-ui-design-system.md)
>
> This file covers the **codebase-level internal design** — how the folders are
> organised, the conventions every feature must follow, and the key cross-cutting
> patterns.

## 1. Layer model (Clean Architecture)

Every feature in `lib/features/<domain>/` is split into three layers. The
dependency rule runs **inward only**: Presentation depends on Domain; Data
depends on Domain. Nothing in Domain knows about Flutter or Supabase.

```
Presentation  ←  Domain  ←  Data
(BLoC, pages)    (entities,    (Supabase datasource,
                 use cases,    Hive cache,
                 repo interface) repository impl)
```

### Data layer
- **DataSource** — talks to a single external system (Supabase or Hive). One
  class per system per feature (e.g., `AttendanceRemoteDataSource`,
  `AttendanceLocalDataSource`).
- **Model** — Dart class that knows how to serialize/deserialize itself
  (`fromJson`, `toJson`, Hive `TypeAdapter`). Extends the domain Entity.
- **Repository implementation** — wires the datasources together. Decides
  whether to return local data or fetch from remote. Returns `Failure | T`
  (never throws across the boundary).

### Domain layer
- **Entity** — plain Dart class with no Flutter or JSON dependencies.
- **Repository interface** — abstract contract the Data layer implements and
  the use cases depend on.
- **Use case** — a single callable class (`call()`) encapsulating one business
  operation. Called by BLoC.

### Presentation layer
- **BLoC** — receives Events, emits States via `flutter_bloc`. Business logic
  lives in use cases, not here. Holds UI-relevant state only.
- **Page** — the route-level widget. Provides the BLoC via `BlocProvider`.
- **Widget** — reusable sub-widgets under `widgets/`. Kept small and `const`
  where possible.

## 2. Feature folder convention

```
lib/features/<domain>/
├── data/
│   ├── datasources/       # *RemoteDataSource, *LocalDataSource
│   ├── models/            # *Model extends *Entity; Hive adapters
│   └── repositories/      # *RepositoryImpl
├── domain/
│   ├── entities/          # Pure Dart entity classes
│   ├── repositories/      # Abstract repository interface
│   └── usecases/          # One file per use case
└── presentation/
    ├── bloc/              # *Bloc, *Event, *State
    ├── pages/             # Route-level screens
    └── widgets/           # Reusable sub-widgets for this feature
```

The `auth/` feature is the reference implementation. Every subsequent feature
follows the same structure.

## 3. BLoC conventions

- One BLoC per feature. Complex features may split into sub-BLoCs (e.g.,
  `LoginBloc` and `UserBloc` under `auth/`).
- States extend `Equatable` — enables `BlocBuilder` to skip redundant rebuilds.
- Loading / success / error are distinct state subclasses (not a single state
  with a `status` enum field) so `BlocListener` can match precisely.
- BLoCs never import Flutter widgets. They receive plain Dart inputs and emit
  plain Dart states.

## 4. Offline sync pattern

(Detailed implementation: STEP-3)

The offline-first strategy (Doc 15 §2) uses two Hive boxes per feature that
requires offline support:

| Box | Purpose |
|-----|---------|
| `<feature>_records` | Cached records (written locally first) |
| `sync_queue` | Pending writes not yet pushed to Supabase |

On write: record goes to `<feature>_records` + an entry added to `sync_queue`.  
On connectivity restored (`ConnectivityService.onConnectivityChanged → true`):
the sync queue is drained by pushing each entry to Supabase. On success the
entry is removed from the queue. Conflict resolution: last-write-wins (Doc 15 §2).

## 5. Secrets & configuration

No secret values live in this codebase. Config is injected as `--dart-define`
flags at build time (see `README.md` §Running and Doc 09 — Environments §2).
In `lib/core/constants/app_constants.dart`, `String.fromEnvironment()` reads
them at compile time — an empty string results if the flag is missing.

## 6. Theme usage

All colour, typography, and shape values are defined in
`lib/app/theme/app_theme.dart`. Features consume them via
`Theme.of(context).colorScheme.*` and the token constants exported from that
file (e.g., `kColorPrimary`, `kBorderRadius`). **No feature file hardcodes
raw hex colour values.**

## 7. Routing

Routes are declared in `lib/app/router.dart`. Each feature adds its routes
there when implemented. Use the `AppRoutes` constants class for path strings —
never inline raw strings in `context.go(...)` calls.

## 8. Internationalization

All user-facing strings are routed through the localization layer (configured
in `lib/app/app.dart`). The primary locale is `id_ID` (Indonesian). Hardcoded
Indonesian strings in stub code are acceptable during scaffolding but must be
moved to ARB files before the feature ships.

## 9. Logging

Use `buildLogger('ClassName')` from `lib/core/utils/logger.dart` to get a
scoped `Logger`. Never use `print()` in shipped code (enforced by
`avoid_print` lint). Never log secrets or PII.

## 10. ADRs

Decisions that shaped this repo's design:

| ADR | Decision |
|-----|---------|
| [ADR-0001](../mine-flow-docs/adr/ADR-0001-local-storage-hive.md) | Hive selected over SQLite/sqflite for local offline storage |
